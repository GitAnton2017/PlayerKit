//
//  Player States.swift
//  AreaSightDemo
//
//  Created by Anton V. Kalinin on 03.12.2022.
//  Copyright © 2022 Netris. All rights reserved.
//

import Foundation
import Combine
import UIKit

internal protocol NTXPlayerState  {
 
 associatedtype Player: NTXMobileNativePlayerProtocol
 
 var player: Player { get }
 
 func handle(priorState: (any NTXPlayerState)?) throws
}

internal extension NTXPlayerState  {
 
 typealias ConnectionManager      = Player.Manager
 typealias KeepAliveState         = ConnectionManager.KeepAliveState
 
 typealias KeepAlivePlayerMode    = KeepAliveState.Mode
 typealias KeepAlivePlayerState   = KeepAliveState.State
 typealias KeepAlivePlayerArchive = KeepAliveState.Archive
 
 var inputSearchVSS: Player.Manager.SearchResult { player.inputVSSSearchResult }
 
 var connectionsManager: ConnectionManager  { player.connectionsManager }
 
 func updateKeepAliveState(to state: KeepAliveState) throws {
  
  debugPrint (#function, state)
  
  try connectionsManager.changeVSSStateForBeating(activePlayerState: state,
                                                  for: inputSearchVSS)
 }
 
 func allControlsExcept(_ action: NTXPlayerActions, state: Bool) -> [NTXPlayerActions : Bool] {
  Dictionary(uniqueKeysWithValues: NTXPlayerActions.allCases.map{ ($0, $0 == action ? !state : state) })
 }
 
 func allControlsExcept(_ actions: [NTXPlayerActions], state: Bool) -> [NTXPlayerActions : Bool] {
  Dictionary(uniqueKeysWithValues: NTXPlayerActions.allCases.map{ ($0, actions.contains($0) ? !state : state) })
 }
 
 func updateControlsEnabledState ( _ statesMap: [NTXPlayerActions : Bool] ) {
  statesMap.forEach{ (action, state) in
   player[action]?.alpha = state ? 1.0 : NTXPlayerStates.controlDisabledOpacity
   player[action]?.isUserInteractionEnabled = state
  }
 }
 
 func disableAllControls() {
  player.playerControls.forEach{
   $0.isUserInteractionEnabled = false
   $0.alpha = NTXPlayerStates.controlDisabledOpacity
  }
 }
 
 func animateDisableAllControls(duration: TimeInterval = NTXPlayerStates.controlStateAnimationDuration,
                                completion: (() -> ())? = nil){
  UIView.animate(withDuration: duration) {
   player.playerControls.forEach{ $0.alpha = NTXPlayerStates.controlDisabledOpacity }
  } completion: { _ in
    player.playerControls.forEach { $0.isUserInteractionEnabled = false }
    completion?()
  }

 }
 
 func animateEnableAllControls(duration: TimeInterval = NTXPlayerStates.controlStateAnimationDuration,
                                completion: (() -> ())? = nil){
  UIView.animate(withDuration: duration) {
   player.playerControls.forEach { $0.alpha = 1.0 }
  } completion: { _ in
   player.playerControls.forEach { $0.isUserInteractionEnabled = false }
   completion?()
  }
  
 }
 
 func enableAllControls() {
  player.playerControls.forEach{
   $0.isUserInteractionEnabled = true
   $0.alpha = 1.0
  }
 }
 
 func animateControlsEnabledState( mask statesMap: [NTXPlayerActions : Bool],
                                   duration: TimeInterval = NTXPlayerStates.controlStateAnimationDuration,
                                   completion: (() -> ())? = nil) {
  UIView.animate(withDuration: duration) {
   statesMap.forEach { (action, state) in
    player[action]?.alpha = state ? 1.0 : NTXPlayerStates.controlDisabledOpacity
   }
   
  } completion: { _ in
   statesMap.forEach { (action, state) in
    player[action]?.isUserInteractionEnabled = state
   }
   completion?()
  }
  
 }
 
}

internal enum NTXPlayerError: Error {
 
 case snapshotPreloadFailed (error: Error)
 case VSSConnectionFailed   (error: Error)
 case playerContextFailed   (error: Error)
 case archiveRequestFailed  (error: Error)
 case noStreamingURL
 case keepAliveStateUpdateFailed(error: Error)
 case stateError(error: NTXPlayerStates.StateError)
 case noLastEnteredBackground
 
 case noArchiveShotsURL
 case archiveShotsPrefetchFailed(error: Error)
 
 
 
}

internal enum NTXPlayerStates {
 
 internal static let controlStateAnimationDuration: TimeInterval = 0.5
 internal static let controlDisabledOpacity: CGFloat = 0.5
 internal static let maxVSSContextRequests: Int = 10
 internal static let maxVSSStreamingRequests: Int = 5

 
 internal enum StateError: Error {
  case unexpectedState(prior: (any NTXPlayerState)?, current: any NTXPlayerState)
 }
 
 //MARK: <<< ***** PLAYER INITIAL STATE ***** >>>
 // - The player can be in this state only once when initialised and configured.
 
 internal struct Initial<P: NTXMobileNativePlayerProtocol>: NTXPlayerState {
  
  internal unowned let player: P
  

  internal func handle(priorState: (any NTXPlayerState)? ) throws  {
   debugPrint ("<<< ***** PLAYER INITIAL STATE ***** >>>")
   
   //Can be handled only initially when there is no prior state at all!
   
   if let priorState = priorState {
    throw StateError.unexpectedState(prior: priorState, current: self)
    //this error is processed in player...
   }
  
   initNotificationsObservations()
   disableAllControls()
   
   
   //ZP = 1 in Owner view
   player.playerContainerView.bringSubviewToFront(player.playerContext)
   player.playerContext.isHidden = true
  
   //ZP = 2 in Owner view
   player.playerContainerView.bringSubviewToFront(player.playerPreloadView)
   player.playerPreloadView.isHidden = false  // show this first & activity indicator
   
   //ZP = 3 in Owner view
   player.playerContainerView.bringSubviewToFront(player.playerActivityIndicator)
   player.playerActivityIndicator.startAnimating()
   
   //ZP = 4 in Owner view
   player.playerContext.isMuted = true
   player.playerMutedStateView.isHidden = false
   player.playerContainerView.bringSubviewToFront(player.playerMutedStateView)
   
   //ZP = 5
   player.controlGroups.forEach{player.playerContainerView.bringSubviewToFront($0)}
   
   //ZP = 6
   player.playerContainerView.bringSubviewToFront(player.playerAlertView)
   
 
  ///GO TO CONNECTING STATE...
   player.playerState = Connecting(player: player, tryCount: NTXPlayerStates.maxVSSContextRequests)
   
  }
  
  
  private func willResignActiveHandler(_ n: Notification) {
   
   debugPrint ("APP STATE CHANGE TO ", #function)
   
   player.lastTimeAppEnteredBackground = Date()
  
   switch player.playerState {
    case let state as Streaming<P>:
     player.playerState = Paused(player: player, streamURL: state.streamURL, archiveDepth: state.archiveDepth)
     
    case let state as PlayingArchive<P>:
     player.playerState = Paused(player: player, streamURL: state.liveStreamURL, archiveDepth: state.depthSeconds)
    
   
    default: break
   }
   
   
  }
  
  private func willEnterForegroundHandler(_ n: Notification) {
   
   debugPrint ("APP STATE CHANGE TO ", #function)
   
   guard let lastBack = player.lastTimeAppEnteredBackground?.timeIntervalSince1970 else {
    player.playerState = Failed(player: player, error: .noLastEnteredBackground)
    return
   }
   
   guard Date().timeIntervalSince1970 - lastBack < player.appBackgroundTimeLimitForPlayer else {
    player.playerState = Stopped(player: player)
    return
    
   }
   
   
   switch player.playerState {
    case let state as Paused<P>:
     player.playerState = Streaming(player: player,
                                    streamURL: state.streamURL,
                                    tryRestartCount: 0,
                                    archiveDepth: state.archiveDepth)
    default: break
   }
  
   
  }
  
  private func initNotificationsObservations() {
   
   print(#function, self)
   
   if #available(iOS 13.0, *) {
    
    let willResignActive = NotificationCenter.default
     .publisher(for: UIApplication.willResignActiveNotification)
     .receive(on: DispatchQueue.main)
     .sink(receiveValue: willResignActiveHandler)
    
    let willBecomeActive = NotificationCenter.default
     .publisher(for: UIApplication.willEnterForegroundNotification)
     .receive(on: DispatchQueue.main)
     .sink(receiveValue: willEnterForegroundHandler)
    
     player.notificationsTokens.append(contentsOf: [willBecomeActive, willResignActive])
   
   } else {
    let willResignActive = NotificationCenter.default
     .addObserver(forName: UIApplication.willResignActiveNotification,
                  object: nil, queue: .main, using: willResignActiveHandler)
    
    let willBecomeActive = NotificationCenter.default
     .addObserver(forName: UIApplication.willEnterForegroundNotification,
                  object: nil, queue: .main, using: willEnterForegroundHandler)
    
    player.notificationsTokens.append(contentsOf: [willBecomeActive, willResignActive])
   }
   
  }
  
 }
 
 //MARK: <<< ***** PLAYER CONNECTING STATE ***** >>>
 // - Request VSS connection and obtain parsed from JSON VSS context object

 internal struct Connecting<P: NTXMobileNativePlayerProtocol>: NTXPlayerState {
  
  
 
  private  func requestingVSSContextForLiveStreaming() {
   
   debugPrint (#function)
   
   animateControlsEnabledState(mask: allControlsExcept(.stop, state: false))
   
   guard tryCount > 0 else {
    player.showAlert(alert: .error(message: "Превышен лимит попыток подключения к СВН!"))
    return
   }
   
   
   let reqNo = NTXPlayerStates.maxVSSContextRequests - tryCount + 1
   
   player.showAlert(alert: .warning(message: "Запрос (\(reqNo)) подключения к выбранной СВН "))
   
   let request = player.connectionsManager.requestVSSConnection(from: player.inputVSSSearchResult) { result in
    switch result {
     case let .success(deviceContext):
      debugPrint ("SUCCESS: \(deviceContext)", #function, self)
      player.currentVSS = deviceContext
      player.playerState = Connected<P>(player: player, deviceContext: deviceContext)
      ///GO TO CONNECTED STATE WITH OBTAINED  VSS CONTEXT OBJECT...
      
     case let .failure(error):
      player.playerState = Failed<P>(player: player, error: .VSSConnectionFailed(error: error))
    }
    
   }
   
   if let request = request{ player.requests.append(request) }
  }
  
  private func refreshed() {
   UIView.transition(from:     player.playerContext,
                     to:       player.playerPreloadView,
                     duration: player.transitionDurationOfContexts,
                     options:  [.showHideTransitionViews, .transitionCrossDissolve]) { _ in
    
    player.playerActivityIndicator.startAnimating()
    player[.stop]?.tintColor = .white
    player[.stop]?.transform = .init(scaleX: 1.05, y: 1.05)
   }
  }
  
  
  internal unowned let player: P
  
  internal let tryCount: Int
  
  internal func handle(priorState: (any NTXPlayerState)?) throws {
   
   debugPrint ("<<< ***** PLAYER CONNECTING STATE ***** >>>")
   
   switch priorState {
     
    case is Stopped<P>            : fallthrough
    case is Paused<P>             : fallthrough
    case is Failed<P>             : fallthrough
    case is PlayingArchive<P>     : fallthrough
    case is Streaming<P>          : refreshed() ; fallthrough
    case is Initial<P>            : requestingVSSContextForLiveStreaming()
     
     try updateKeepAliveState(to: .init(mode:   .liveVideo,
                                        state:  .loading,
                                        archive: nil))
 
    default: break
   }
   
  }
 
  
 }
 
 //MARK: <<< ***** PLAYER CONNECTED STATE ***** >>>
 // - Move to streaming state
 // - As a side effect request VSS archive controls if avalable & photo shot static image data.
 
 internal struct Connected<P: NTXMobileNativePlayerProtocol>: NTXPlayerState {
  
  private var streamingURL: URL {
   get throws {
    guard let urlString = deviceContext.getLiveIosUrls()?.first, let url = URL(string: urlString) else {
     throw NTXPlayerError.noStreamingURL
    }
    
    return url
   }
  }
  
  internal unowned let player: P
  
  internal unowned let deviceContext: P.Manager.Device
  
  internal func handle(priorState: (any NTXPlayerState)?) throws  {
   
   debugPrint ("<<< ***** PLAYER CONNECTED STATE ***** >>>")
   
   switch priorState {
    case is Connecting<P>  : try startLiveStreamingFromConnectedVSS()
    default: break
   }
   
  }
  
  
  
  private func startLiveStreamingFromConnectedVSS() throws {
   
   debugPrint(#function)
   
   animateControlsEnabledState(mask: allControlsExcept([.stop, .refresh], state: false))
   requestArchiveControls()
   fetchingLivePhotoShot()
   
   
    ///GO TO STREAMING STATE WITH OBTAINED VSS URL...
   
   player.playerState = Streaming(player: player,
                                  streamURL: try streamingURL,
                                  tryRestartCount: NTXPlayerStates.maxVSSStreamingRequests,
                                  archiveDepth: 0)

  }
  
  
  private func prefetchingArchivePhotoShots(_ depth: Int) {
   
   debugPrint(#function)
   
   
   
  }
  
  private func fetchingLivePhotoShot()   {
   
   debugPrint(#function)
   
   guard player.playerPreloadView.image == nil else {
    debugPrint("Using Exisiting Preload", #function)
    return
   }
  
   
   let request = player.connectionsManager.requestVSSPhotoShot(for: deviceContext){ result in
    switch result {
     case let .success(photoShot):
      debugPrint("LIVE PHOTO SHOT DATA RECEIVED SUCCESSFULLY: \(photoShot)")
      DispatchQueue.main.async {
       player.playerPreloadView.image = photoShot.uiImage
       player.currentPhotoShot = photoShot
       
      }
      
     case let .failure(error):
      player.playerState = Failed<P>(player: player, error: .snapshotPreloadFailed(error: error))
 
    }

   }
   
   if let request = request { player.requests.append(request) }
  }
 
 
  private func requestArchiveControls ()  {
   
   debugPrint(#function)
 
   let request = player.connectionsManager.requestVSSArchive(for: deviceContext){ result in
    
    switch result {
     case let .success(archiveContext):
      
      debugPrint("ARCHIVED CONTROLS RECEIVED SUCCESSFULLY: \(archiveContext)")
      
      player.currentVSSArchiveControls = archiveContext
      
      let depth = ((archiveContext.end ?? 0) - (archiveContext.start ?? 0)) / 1000
      
      guard depth > 0 else { break }
      
      debugPrint("ARCHIVE DEPTH AVAILABLE (SEC): \(depth)")
      
      
      
     case let .failure(error):
      player.playerState = Failed<P>(player: player, error: .archiveRequestFailed(error: error))
      
    }
    
   }
   
   if let request = request { player.requests.append(request) }
   
  }

 }
 
 
 //MARK: <<< ***** PLAYER STREAMING STATE ***** >>>
 // If VSS streaming endpoint URL available after connected state start playback in player playback context
 // Do not move to any other state here!
 
 internal struct Streaming<P: NTXMobileNativePlayerProtocol>: NTXPlayerState {
  
  internal unowned let player: P
  
  internal let streamURL: URL
  
  internal let tryRestartCount: Int
  
  let archiveDepth: Int
  
  private func pauseStreaming() {
   
   debugPrint (#function)
   
   player.playerState = Paused<P>(player: player, streamURL: streamURL, archiveDepth: archiveDepth)
   
  }
  
  ///PREPARE LIVE STREAMING ASSET FOR PLAYING AND WAIT WHILE IT IS NO READY...
  
  
  private var isArchiveAvailable: Bool {
   guard let archiveControls = player.currentVSSArchiveControls else { return false }
   return archiveControls.end ?? 0 > archiveControls.start ?? 0
  }
  
  private func startLiveStreaming() {
   
   debugPrint (#function)
   
   guard tryRestartCount > 0 else {
    player.showAlert(alert: .error(message: "Превышен лимит попыток живого вещания ресурса СВН!"))
    return
   }
   
   let reqNo = NTXPlayerStates.maxVSSStreamingRequests - tryRestartCount + 1
   
   player.showAlert(alert: .info(message: "Попытка (\(reqNo)) инициализация живого вещания ресурса СВН."))
  
   player.playerContext.startPlayback(from: streamURL,
                                      useLiveStreamingWhilePaused: true,
                                      retryCount: 100) { result in
    switch result {
     case .success(_ ):
      
      debugPrint ("SUCCESS!!! PLAYER CONTEXT IS READY TO STREAM")
      
      player.showAlert(alert: .info(message: "Успешное подключение к выбранной СВН в режиме живого вещания! "))
      
      UIView.transition(from:     player.playerPreloadView,
                        to:       player.playerContext,
                        duration: player.transitionDurationOfContexts,
                        options:  [.showHideTransitionViews, .transitionCrossDissolve]) { _ in
       
       
      
       player.playerActivityIndicator.stopAnimating()
       animateControlsEnabledState(mask: [ .play               : false,
                                           .pause              : true ,
                                           .toggleMuting       : true ,
                                           .playArchiveBack    : isArchiveAvailable ,
                                           .playArchiveForward : false ])
       
       player.showAlert(alert: .warning(message: "Трансляция производится с выключенным звуком! "))
      
       do {
         ///TRY TO SET KEEP ALIVE STATE NOW **PLAYING** FROM LIVE STREAMING ASSET...
         ///
        try updateKeepAliveState(to: .init(mode: .unchanged, state: .playing, archive: nil))
       } catch {
        player.playerState = Failed<P>(player: player,
                                       error: .keepAliveStateUpdateFailed(error: error))
       }
       
      }
      
     case .failure(let error):
      
      debugPrint ("FAILURE!!! PLAYER CONTEXT IS NOT READY!")
  
      player.playerState = Failed<P>(player: player, error: .playerContextFailed(error: error))
      
  
    }
   }
  }
  
  private func resumeAfterPause() {
   
   debugPrint (#function)
   
   player.showAlert(alert: .warning(message: "Возобновление трансляции с текущей СВН!"))
 
   guard player.playerContext.isReadyToPlay else  {
    
    UIView.transition(from:     player.playerContext,
                      to:       player.playerPreloadView,
                      duration: player.transitionDurationOfContexts,
                      options:  [.showHideTransitionViews, .transitionCrossDissolve]) { _ in
     
     player.playerActivityIndicator.startAnimating()
     startLiveStreaming()
    }
    return
   }
   
   player.playerContext.play()
   player.playerContext.isMuted = true
   player.playerMutedStateView.isHidden = false
   animateControlsEnabledState(mask: [.play: false, .pause: true, .toggleMuting: true])

  }
  
  
  internal func handle(priorState: (any NTXPlayerState)?) throws {
   debugPrint ("<<< ***** PLAYER STREAMING STATE ***** >>>")
   
   switch priorState {
    case is Self                  : pauseStreaming() // toggle streming/pause
    case is Paused<P>             : resumeAfterPause()
    case let failure as Failed<P> :
     if case .playerContextFailed(error: _ ) = failure.error { startLiveStreaming() }
    
    case is PlayingArchive<P>     : fallthrough
    case is Connected<P>          : startLiveStreaming()
     
     ///KEEP ALIVE **SUSPENDED** UNTIL PLAYER IS READY TO PLAY FROM LIVE STREAMING ASSET...
     try updateKeepAliveState(to: .init(mode: .unchanged,
                                        state: .suspended,
                                        archive: nil))
 
     
    default: break
   }
   
  }
 
 }
 
  //MARK: <<< ***** PLAYER PAUSED STATE ***** >>>
 internal struct Paused<P: NTXMobileNativePlayerProtocol>:  NTXPlayerState {
 
  internal unowned let player: P
  
  internal let streamURL: URL
  
  let archiveDepth: Int
  
  private func pausePlayer() {
  
   player.showAlert(alert: .warning(message: "Приостановка трансляции с текущей СВН!"))
   
   player.playerContext.pause()
   player.playerContext.isMuted = true
   player.playerMutedStateView.isHidden = false
   animateControlsEnabledState(mask: [.play: true, .pause: false])

  }
  
  private func resumeStreaming() {
   
   player.playerState = Streaming(player: player,
                                  streamURL: streamURL,
                                  tryRestartCount: 0,
                                  archiveDepth: archiveDepth)
  }
  
  
  internal func handle(priorState: ( any NTXPlayerState)? ) throws {
   
   debugPrint ("<<< ***** PLAYER PAUSED STATE ***** >>>")
   
   switch priorState {
    
    case is Self                 : resumeStreaming() //toggle pause/streaming...
    case is PlayingArchive<P>    : fallthrough
    case is Streaming<P>         : pausePlayer()
     
      ///KEEP ALIVE **PAUSED** UNTIL PLAYER IS READY TO PLAY FROM LIVE STREAMING ASSET...
      ///
     try updateKeepAliveState(to: .init(mode: .unchanged,
                                        state: .paused,
                                        archive: nil))
     
     
     
    default: break
   }
   
  }
  


 }
 
 
  //MARK: <<< ***** PLAYER STOPPED STATE ***** >>>
 internal struct Stopped<P: NTXMobileNativePlayerProtocol>: NTXPlayerState {
  
  internal unowned let player: P
  
  private func stopAfterPause() throws {
   
   player.showAlert(alert: .warning(message: "Трансляция с текущей СВН остановлена без возобновления!"))
   
   UIView.transition(from:      player.playerContext,
                     to:        player.playerPreloadView,
                     duration:  player.transitionDurationOfContexts,
                     options:  [.showHideTransitionViews, .transitionCrossDissolve]) {_ in
    
    animateControlsEnabledState(mask: allControlsExcept([.stop, .refresh], state: false))
    player[.stop]?.tintColor = .systemRed.withAlphaComponent(0.85)
    player[.stop]?.transform = .init(scaleX: 1.1, y: 1.1)
    
    do {
      ///TRY TO SET KEEP ALIVE STATE NOW **STOPPED**
     try updateKeepAliveState(to: .init(mode: .unchanged,
                                        state: .suspended,
                                        archive: nil))
    } catch {
     player.playerState = Failed<P>(player: player,
                                    error: .keepAliveStateUpdateFailed(error: error))
    }
   }
  }
  
  private func stopAfterStreaming() throws {
   
   player.showAlert(alert: .warning(message: "Трансляция с текущей СВН остановлена!"))
  
   UIView.transition(from:      player.playerContext,
                     to:        player.playerPreloadView,
                     duration:  player.transitionDurationOfContexts,
                     options:  [.showHideTransitionViews, .transitionCrossDissolve]) { _ in
    
    animateControlsEnabledState(mask: allControlsExcept([.stop, .refresh], state: false))
    player[.stop]?.tintColor = .systemRed.withAlphaComponent(0.85)
    player[.stop]?.transform = .init(scaleX: 1.1, y: 1.1)
    player.playerContext.pause()
    
    do {
      ///TRY TO SET KEEP ALIVE STATE NOW **STOPPED**
     try updateKeepAliveState(to: .init(mode: .unchanged,
                                        state: .suspended,
                                        archive: nil))
    } catch {
     player.playerState = Failed<P>(player: player,
                                    error: .keepAliveStateUpdateFailed(error: error))
    }
    
   }
   
  
  }
  
  private func stopWhenConnecting(){
   //TODO: Stop HTTPS request here...
   player.showAlert(alert: .warning(message: "Подключение к СВН отменено пользователем!"))
   player.playerActivityIndicator.stopAnimating()
   
   animateControlsEnabledState(mask: allControlsExcept([.stop, .refresh], state: false))
   player[.stop]?.tintColor = .systemRed.withAlphaComponent(0.85)
   player[.stop]?.transform = .init(scaleX: 1.1, y: 1.1)
   
   player.requests.forEach{ $0.cancel() }
   
  }
  
  private func playerShutdown() {
   player.playerState = Invalidated(player: player)
  }
  
  internal func handle(priorState: ( any NTXPlayerState )? ) throws {
   
   debugPrint ("<<< ***** PLAYER STOPPED STATE ***** >>>")
   
   switch priorState {
    
    case is Self                  : playerShutdown()
    case is PlayingArchive<P>     : fallthrough
    case is Streaming<P>          : try stopAfterStreaming()
    case is Paused<P>             : try stopAfterPause()
    case is Connected<P>          : fallthrough
    case is Connecting<P>         : stopWhenConnecting()
    
     
    default: break
   }
   
  }
  

  
  
 }
 
  //MARK: <<< ***** PLAYER ARCHIVE STATE ***** >>>
 
 internal struct  PlayingArchive<P: NTXMobileNativePlayerProtocol>:  NTXPlayerState {
  
  internal unowned let player: P
  
  internal let depthSeconds: Int
  
  let liveStreamURL: URL
 
  
  
  
  private func startArchiveStreaming(from streamURL: URL) {
   
   player.playerContext.pause()
  
   player.playerContext.startPlayback(from: streamURL,
                                      useLiveStreamingWhilePaused: true,
                                      retryCount: .max) { result in
    switch result {
     case .success(_ ):
      
      debugPrint ("SUCCESS!! PLAYING ARCHIVE RECORD!")
      
      player.showAlert(alert: .info(message: "Архивная запись успешно загружена!"))
      
      UIView.transition(from:     player.playerPreloadView,
                        to:       player.playerContext,
                        duration: player.transitionDurationOfContexts,
                        options:  [.showHideTransitionViews, .transitionCrossDissolve]) { _ in
       
       
       player.playerActivityIndicator.stopAnimating()
       
       animateControlsEnabledState(mask: [.playArchiveBack    : true,
                                          .playArchiveForward : true,
                                          .play               : false,
                                          .pause              : true])
       
       player.showAlert(alert: .warning(message: "Архив воспроизводится с выключенным звуком!"))
       
       do {
         ///TRY TO SET KEEP ALIVE STATE NOW **PLAYING ARCHIVE ** FROM ARCHIVE ASSET...
    
        try updateKeepAliveState(to: .init(mode: .archiveVideo, state: .playing, archive: nil))
       } catch {
        player.playerState = Failed<P>(player: player,
                                       error: .keepAliveStateUpdateFailed(error: error))
       }
       
      }
      
     case .failure(let error):
      
      debugPrint ("FAILURE!!! PLAYER CONTEXT IS NOT READY TO PLAY ARCHIVE RECORD!")
      
      player.playerState = Failed<P>(player: player, error: .playerContextFailed(error: error))
      
      
    }
   }
  }
  
  func resumeLiveStreaming() {
   
   debugPrint(#function)
   
   guard let liveURL = player.currentVSSStreamingURL else { return }
   
   player.playerState = Streaming<P>.init(player: player,
                                          streamURL: liveURL,
                                          tryRestartCount: NTXPlayerStates.maxVSSStreamingRequests,
                                          archiveDepth: 0)
   
  }
  
  internal func handle(priorState: (any NTXPlayerState)?) throws {
   
   debugPrint ("<<< ***** PLAYER PLAYING ARCHIVE STATE ***** >>>")
   
   guard let archiveContext = player.currentVSSArchiveControls else { return }
   guard let archiveURLString = player.currentVSS?.getArchiveIosUrls()?.first else { return }
  
   let startSec = (archiveContext.start ?? 0) / 1000
   let endSec   = (archiveContext.end   ?? 0) / 1000
   
   print("ARCHIVE DEPTH SEC: Start - \(startSec) |===>| End - \(endSec) ")
   
   switch priorState {
     
    case is Paused<P>         : fallthrough
    case is Streaming<P>      : fallthrough
    case is PlayingArchive<P> :
     
     guard depthSeconds < 0 else { resumeLiveStreaming(); break }
     
     let timePoint = endSec + depthSeconds
     
     guard timePoint >= startSec else { break }
     
     
     guard let depthURL = URL(string: "\(archiveURLString)&ts=\(timePoint)") else { break }
     player.showAlert(alert: .warning(message:
        """
         Запрос на воспроизведение записи архива
         видеонаблюдения с глубиной \(depthSeconds) секунд назад!
        """))
     
     startArchiveStreaming(from: depthURL)
     
    default: break
   }
   
   
  }
  
  
  
  
 }
 
 // TODO: ----
 internal struct ShowingVR<P: NTXMobileNativePlayerProtocol>:  NTXPlayerState {
  
  internal unowned let player: P
  
  internal func handle(priorState: (any NTXPlayerState)?) throws {
   debugPrint ("<<< ***** PLAYER SHOWING VR STATE ***** >>>")
   player.showAlert(alert: .warning(message: "Загрузка воспроизведения в режиме виртульной реальности!"))
 
    // TODO: ----
  }
 
 }
 
 
 
 //MARK: <<< ***** PLAYER FAILED STATE ***** >>>
 // Process all errors and alert using player alert view.
 internal class Failed<P: NTXMobileNativePlayerProtocol>: NSObject, NTXPlayerState {
  
  internal unowned let player: P
  
  internal var error: NTXPlayerError
  
  private func alert(_ message: String) {
    player.showAlert(alert: .error(message: message))
  }
  
  internal func handle(priorState: (any NTXPlayerState)?) throws {
   
   debugPrint ("<<< ***** PLAYER FAILED STATE ***** >>>")
   
   switch (priorState, error) {
     
    case let (state as Connecting<P>, .VSSConnectionFailed(error: error)):
     debugPrint("VSS Connection Failed: <\(error.localizedDescription)>")
     alert("Не возможно подключиться к данной СВН. Ошибка сервера!")
     
     ///RETRY CONNECT VSS AFTER CONNECTON ERROR!
     player.playerState = Connecting<P>(player: player, tryCount: state.tryCount - 1)
     
    case (_ , .noStreamingURL):
     alert("Ресурс для данной СВН отсутсвует на сервере!")
     
    case let (priorState?, .snapshotPreloadFailed(error: error)) : player.playerState = priorState
     debugPrint("VSS Snapshot Preload Failed: <\(error.localizedDescription)>")
     
     alert("Не удалось загрузить предварительный снимок с данной СВН")
     
    case let (state as Streaming<P>,  .playerContextFailed) :
     debugPrint("Player Playing Context Error: <\(error.localizedDescription)>")
     
     alert("Вещание с данного ресурса СВН временно не доступно!")
     
     ///TRY RESTART STREAMING FROM VSS AFTER INTERNAL CONTEXT AV PLAYER ERROR!
     player.playerState = Streaming<P>(player: player,
                                       streamURL: state.streamURL,
                                       tryRestartCount: state.tryRestartCount - 1,
                                       archiveDepth: state.archiveDepth)
     
    case let (state as PlayingArchive<P>,  .playerContextFailed) :
     debugPrint("Player Playing Archive Context Error: <\(error.localizedDescription)>")
     
     let depthSeconds = state.depthSeconds - player.archiveTimeStepSeconds
     
     alert("""
           Не возможно воспроизвести запись из архива c глубиной \(state.depthSeconds) сек.
           Будет воспроизведена следующая -\(depthSeconds) cек.
           """)
     
     player.playerState = PlayingArchive<P>.init(player: player,
                                                 depthSeconds: depthSeconds,
                                                 liveStreamURL: state.liveStreamURL)
     
    case let (priorState? , .archiveRequestFailed(error: error)) : player.playerState = priorState
     debugPrint("Archive Preload Failed: <\(error.localizedDescription)>")
     alert("Не возможно загрузить архивные данные СВН с сервера")
     
    case (_, .stateError(error: let error)):
     debugPrint("Player State Transition Error: <\(error.localizedDescription)>")
     
    case (_, .noLastEnteredBackground):
     debugPrint("Last entered background time stamp missing: <\(error.localizedDescription)>")
     
    default:
     debugPrint("Undefined Failure State: <\(String(describing: priorState)) - \(error.localizedDescription)>")
   }
   
   try updateKeepAliveState(to: .init(mode: .unchanged, state: .error, archive: nil))
  }
  

  
  
  internal init(player: P, error: NTXPlayerError){
   self.error = error
   self.player = player
   super.init()
  }
  
  
  

  
 }
 
 internal struct Invalidated<P: NTXMobileNativePlayerProtocol>: NTXPlayerState {
  
  
  internal unowned let player: P
  
  internal func handle(priorState: (any NTXPlayerState)?) throws {
   
   debugPrint ("<<< ***** PLAYER INVALIDATED STATE ***** >>>")
   
   guard priorState is Stopped<P> else {
    throw StateError.unexpectedState(prior: priorState, current: self)
   }
   
   invalidateNotificationsObservations()
   player.shutdownHandler()
  }
  
  
 
  
  
  private func invalidateNotificationsObservations() {
   
   debugPrint(#function)
   
   if #available(iOS 13.0, *) {
    player.notificationsTokens.compactMap{ $0 as? AnyCancellable }.forEach{ $0.cancel() }
    player.notificationsTokens.removeAll()
    
   } else {
    player.notificationsTokens.forEach { NotificationCenter.default.removeObserver($0) }
   }
  }
  
  
  
 }
 
}
