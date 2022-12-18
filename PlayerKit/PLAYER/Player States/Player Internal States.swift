 ///PLAYER INTERNAL CORE OBJECTS OF STATES.

import Combine
import UIKit


internal protocol NTXPlayerState  {
 
 associatedtype Player: NTXMobileNativePlayerProtocol
 
 var player: Player { get }
 
 func handle(priorState: (any NTXPlayerState)?) throws
}

internal extension NTXPlayerState
where Player.Delegate.Device == Player.Manager.InputDevice {
 
 typealias ConnectionManager      = Player.Manager
 typealias KeepAliveState         = ConnectionManager.KeepAliveState
 
 typealias KeepAlivePlayerMode    = KeepAliveState.Mode
 typealias KeepAlivePlayerState   = KeepAliveState.State
 typealias KeepAlivePlayerArchive = KeepAliveState.Archive
 
 var inputSearchVSS: Player.Manager.InputDevice { player.inputVSSSearchResult }
 
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
 case VSSConnectionRetryCountEcxeeded
 case playerContextFailed   (error: Error)
 case playerContextRetryCountEcxeeded
 case archiveRequestFailed  (error: Error)
 case noStreamingURL
 case keepAliveStateUpdateFailed(error: Error)
 case stateError(error: NTXPlayerStates.StateError)
 case noLastEnteredBackground
 case unauthorized(code: Int)
 
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
 
 internal struct Initial<P: NTXMobileNativePlayerProtocol>: NTXPlayerState
 where P.Delegate.Device == P.Manager.InputDevice {
  
  internal unowned let player: P
  
  
  internal func handle(priorState: (any NTXPlayerState)? ) throws  {
   debugPrint ("<<< ***** PLAYER INITIAL STATE ***** >>>")
   
   player.playerStateDelegate?
    .playerDidChangeState(deviceID: player.inputVSSSearchResult.id, to: .started)
   
    //Can be handled only initially when there is no prior state at all!
   
   if let priorState = priorState {
    throw StateError.unexpectedState(prior: priorState, current: self)
     //this error is processed in player...
   }
   
   initNotificationsObservations()
   disableAllControls()
   
   if player.playerContainerView.superview == player.playerOwnerView {
    player.playerStateDelegate?
     .playerMovedToOwner(deviceID: player.inputVSSSearchResult.id,
                         ownerView: player.playerOwnerView)
   }
   
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
   player.playerMutedStateView.isHidden = true
   player.playerContainerView.bringSubviewToFront(player.playerMutedStateView)
   
    //ZP = 5
   player.controlGroups.forEach{player.playerContainerView.bringSubviewToFront($0)}
   
    //ZP = 6
   player.playerContainerView.bringSubviewToFront(player.playerAlertView)
   
    //ZP = 7
   player.timeLine.isHidden = true
   player.playerContainerView.bringSubviewToFront(player.timeLine)
   
    ///GO TO CONNECTING STATE...
   
   
   
   player.playerStateDelegate?
    .playerWillChangeState(deviceID: player.inputVSSSearchResult.id, to: .connecting)
   
   player.playerState = Connecting(player: player, tryCount: NTXPlayerStates.maxVSSContextRequests)
   
   
  }
  
  
  private func willResignActiveHandler(_ n: Notification) {
   
   debugPrint ("APP STATE CHANGE TO ", #function)
   
   player.lastTimeAppEnteredBackground = Date()
   
   switch player.playerState {
    case let state as Streaming<P>:
     
     player.playerStateDelegate?
      .playerWillChangeState(deviceID: player.inputVSSSearchResult.id,  to: .paused)
     
     player.playerState = Paused(player: player, streamURL: state.streamURL, archiveDepth: state.archiveDepth)
     
    case let state as PlayingArchive<P>:
     
     player.playerStateDelegate?
      .playerWillChangeState(deviceID: player.inputVSSSearchResult.id,  to: .paused)
     
     player.playerState = Paused(player: player, streamURL: state.liveStreamURL, archiveDepth: state.depthSeconds)
     
     
    default: break
   }
   
   
  }
  
  private func willEnterForegroundHandler(_ n: Notification) {
   
   debugPrint ("APP STATE CHANGE TO ", #function)
   
   guard let lastBack = player.lastTimeAppEnteredBackground?.timeIntervalSince1970 else {
    
    player.playerStateDelegate?.playerWillChangeState(deviceID: player.inputVSSSearchResult.id,
                                                      to: .error)
    
    player.playerState = Failed(player: player, error: .noLastEnteredBackground)
    return
   }
   
   guard Date().timeIntervalSince1970 - lastBack < player.appBackgroundTimeLimitForPlayer else {
    
    player.playerStateDelegate?.playerWillChangeState(deviceID: player.inputVSSSearchResult.id,
                                                      to: .stopped)
    player.playerState = Stopped(player: player)
    
    return
    
   }
   
   
   switch player.playerState {
    case let state as Paused<P>:
     
     player.playerStateDelegate?.playerWillChangeState(deviceID: player.inputVSSSearchResult.id,
                                                       to: .playing)
     player.playerState = Streaming(player: player,
                                    streamURL: state.streamURL,
                                    tryRestartCount: 0,
                                    archiveDepth: state.archiveDepth)
    default: break
   }
   
   
  }
  
  private func initNotificationsObservations() {
   
   debugPrint(#function)
   
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
 
 internal struct Connecting<P: NTXMobileNativePlayerProtocol>: NTXPlayerState
 where P.Delegate.Device == P.Manager.InputDevice {
  
  
  
  private  func requestingVSSContextForLiveStreaming() {
   
   debugPrint (#function)
   
   player.playerMutedStateView.isHidden = true
   animateControlsEnabledState(mask: allControlsExcept(.stop, state: false))
   
   guard tryCount > 0 else {
    
    player.playerStateDelegate?
     .playerWillChangeState(deviceID: player.inputVSSSearchResult.id, to: .error)
    
    player.showAlert(alert: .error(message: "Превышен лимит попыток подключения к СВН!"))
    player.playerState = Failed(player: player, error: .VSSConnectionRetryCountEcxeeded)
    return
   }
   
   
   let reqNo = NTXPlayerStates.maxVSSContextRequests - tryCount + 1
   
   player.showAlert(alert: .warning(message: "Запрос (\(reqNo)) подключения к выбранной СВН "))
   
   let request = player.connectionsManager.requestVSSConnection(from: player.inputVSSSearchResult) { result in
    switch result {
     case let .success(deviceContext):
      debugPrint ("SUCCESS: \(deviceContext)", #function)
      player.currentVSS = deviceContext
      
      player.playerStateDelegate?
       .playerWillChangeState(deviceID: player.inputVSSSearchResult.id, to: .connected)
      
      player.playerState = Connected<P>(player: player, deviceContext: deviceContext)
       ///GO TO CONNECTED STATE WITH OBTAINED  VSS CONTEXT OBJECT...
      
     case let .failure(error):
      
      player.playerStateDelegate?
       .playerWillChangeState(deviceID: player.inputVSSSearchResult.id, to: .error)
      
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
    
    player.playerMutedStateView.isHidden = true
    player.playerActivityIndicator.startAnimating()
    player[.stop]?.tintColor = .white
    player[.stop]?.transform = .init(scaleX: 1.05, y: 1.05)
   }
  }
  
  
  internal unowned let player: P
  
  internal let tryCount: Int
  
  internal func handle(priorState: (any NTXPlayerState)?) throws {
   
   debugPrint ("<<< ***** PLAYER CONNECTING STATE ***** >>>")
   
   player.playerStateDelegate?
    .playerDidChangeState(deviceID: player.inputVSSSearchResult.id, to: .connecting)
   
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
 
 internal struct Connected<P: NTXMobileNativePlayerProtocol>: NTXPlayerState
 where P.Delegate.Device == P.Manager.InputDevice {
  
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
   
   player.playerStateDelegate?
    .playerDidChangeState(deviceID: player.inputVSSSearchResult.id,to: .connected)
   
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
   
   player.playerStateDelegate?
    .playerWillChangeState(deviceID: player.inputVSSSearchResult.id, to: .loading)
   
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
      player.playerStateDelegate?
       .playerWillChangeState(deviceID: player.inputVSSSearchResult.id, to: .error)
      
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
      player.playerStateDelegate?
       .playerWillChangeState(deviceID: player.inputVSSSearchResult.id,  to: .error)
      
      player.playerState = Failed<P>(player: player, error: .archiveRequestFailed(error: error))
      
    }
    
   }
   
   if let request = request { player.requests.append(request) }
   
  }
  
 }
 
 
  //MARK: <<< ***** PLAYER STREAMING STATE ***** >>>
  // If VSS streaming endpoint URL available after connected state start playback in player playback context
  // Do not move to any other state here!
 
 internal struct Streaming<P: NTXMobileNativePlayerProtocol>: NTXPlayerState
 where P.Delegate.Device == P.Manager.InputDevice {
  
  internal unowned let player: P
  
  internal let streamURL: URL
  
  internal let tryRestartCount: Int
  
  let archiveDepth: Int
  
  private func pauseStreaming() {
   
   debugPrint (#function)
   
   player.playerStateDelegate?
    .playerWillChangeState(deviceID: player.inputVSSSearchResult.id, to: .paused)
   
   player.playerState = Paused<P>(player: player, streamURL: streamURL, archiveDepth: archiveDepth)
   
  }
  
   ///PREPARE LIVE STREAMING ASSET FOR PLAYING AND WAIT WHILE IT IS NO READY...
  
  
  private var isArchiveAvailable: Bool {
   guard let archiveControls = player.currentVSSArchiveControls else { return false }
   return archiveControls.end ?? 0 > archiveControls.start ?? 0
  }
  
  private func startLiveStreaming() {
   
   debugPrint (#function)
   
   player.playerStateDelegate?
    .playerDidChangeState(deviceID: player.inputVSSSearchResult.id, to: .loading)
   
   
   guard tryRestartCount > 0 else {
    player.showAlert(alert: .error(message: "Превышен лимит попыток живого вещания ресурса СВН!"))
    
    player.playerStateDelegate?
     .playerWillChangeState(deviceID: player.inputVSSSearchResult.id, to: .error)
    
    player.playerState = Failed(player: player, error: .playerContextRetryCountEcxeeded)
    
    return
   }
   
   let reqNo = NTXPlayerStates.maxVSSStreamingRequests - tryRestartCount + 1
   
   player.showAlert(alert: .info(message: "Попытка (\(reqNo)) инициализация живого вещания ресурса СВН."))
   
   player.playerContext.startPlayback(from: streamURL,
                                      useLiveStreamingWhilePaused: true,
                                      retryCount: 100) { result in
    switch result {
     case .success(_ ):
      
      player.playerStateDelegate?.playerWillStreamLiveVideo(deviceID: player.inputVSSSearchResult.id)
      
      player.playerStateDelegate?
       .playerWillChangeState(deviceID: player.inputVSSSearchResult.id, to: .playing)
      
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
                                           .playArchiveForward : false ]) {
                                            player.playerMutedStateView.isHidden = false
                                           }
       
       player.showAlert(alert: .warning(message: "Трансляция производится с выключенным звуком! "))
       
       do {
         ///TRY TO SET KEEP ALIVE STATE NOW **PLAYING** FROM LIVE STREAMING ASSET...
        
        try updateKeepAliveState(to: .init(mode: .unchanged, state: .playing, archive: nil))
       } catch {
        player.playerState = Failed<P>(player: player,
                                       error: .keepAliveStateUpdateFailed(error: error))
       }
       
       player.playerStateDelegate?
        .playerDidChangeState(deviceID: player.inputVSSSearchResult.id, to: .playing)
       
      }
      
     case .failure(let error):
      
      debugPrint ("FAILURE!!! PLAYER CONTEXT IS NOT READY!")
      
      player.playerStateDelegate?
       .playerWillChangeState(deviceID: player.inputVSSSearchResult.id, to: .error)
      
      player.playerState = Failed<P>(player: player, error: .playerContextFailed(error: error))
      
      
    }
   }
  }
  
  private func resumeAfterPause() {
   
   debugPrint (#function)
   
   player.showAlert(alert: .warning(message: "Возобновление трансляции с текущей СВН!"))
   
   guard player.playerContext.isReadyToPlay else  {
    
    player.playerStateDelegate?
     .playerWillChangeState(deviceID: player.inputVSSSearchResult.id, to: .loading)
    
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
   animateControlsEnabledState(mask: [.play: false, .pause: true, .toggleMuting: true]) {
    
    player.playerStateDelegate?
     .playerDidChangeState(deviceID: player.inputVSSSearchResult.id, to: .playing)
   }
   
  }
  
  
  internal func handle(priorState: (any NTXPlayerState)?) throws {
   debugPrint ("<<< ***** PLAYER STREAMING STATE ***** >>>")
   
   switch priorState {
    case is Self                  : pauseStreaming() // toggle streming/pause
    case is Paused<P>             : resumeAfterPause()
     
    case is PlayingArchive<P>     : fallthrough
    case is Connected<P>          : startLiveStreaming()
     
      ///KEEP ALIVE **SUSPENDED** UNTIL PLAYER IS READY TO PLAY FROM LIVE STREAMING ASSET...
     try updateKeepAliveState(to: .init(mode: .unchanged,
                                        state: .suspended,
                                        archive: nil))
     
    case let failure as Failed<P> :
     if case .playerContextFailed(error: _ ) = failure.error { startLiveStreaming() }
     
    default: break
   }
   
  }
  
 }
 
  //MARK: <<< ***** PLAYER PAUSED STATE ***** >>>
 internal struct Paused<P: NTXMobileNativePlayerProtocol>:  NTXPlayerState
 where P.Delegate.Device == P.Manager.InputDevice{
  
  internal unowned let player: P
  
  internal let streamURL: URL
  
  let archiveDepth: Int
  
  private func pausePlayer() {
   
   player.showAlert(alert: .warning(message: "Приостановка трансляции с текущей СВН!"))
   
   player.playerContext.pause()
   player.playerContext.isMuted = true
   player.playerMutedStateView.isHidden = false
   animateControlsEnabledState(mask: [.play: true, .pause: false]) {
    player.playerStateDelegate?
     .playerDidChangeState(deviceID: player.inputVSSSearchResult.id, to: .paused)
    
   }
   
  }
  
  private func resumeStreaming() {
   
   player.playerStateDelegate?
    .playerWillChangeState(deviceID: player.inputVSSSearchResult.id, to: .playing)
   
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
 internal struct Stopped<P: NTXMobileNativePlayerProtocol>: NTXPlayerState
 where P.Delegate.Device == P.Manager.InputDevice {
  
  internal unowned let player: P
  
  private func stopAfterPause() throws {
   
   player.showAlert(alert: .warning(message: "Трансляция с текущей СВН остановлена без возобновления!"))
   
   UIView.transition(from:      player.playerContext,
                     to:        player.playerPreloadView,
                     duration:  player.transitionDurationOfContexts,
                     options:  [.showHideTransitionViews, .transitionCrossDissolve]) {_ in
    
    animateControlsEnabledState(mask: allControlsExcept([.stop, .refresh], state: false)) {
     player[.stop]?.tintColor = .systemRed.withAlphaComponent(0.85)
     player[.stop]?.transform = .init(scaleX: 1.1, y: 1.1)
     
     player.playerStateDelegate?.playerFinishedLiveStreaming(deviceID: player.inputVSSSearchResult.id)
     
     player.playerStateDelegate?
      .playerDidChangeState(deviceID: player.inputVSSSearchResult.id, to: .stopped)
    }
    do {
      ///TRY TO SET KEEP ALIVE STATE NOW **STOPPED**
     try updateKeepAliveState(to: .init(mode: .unchanged,
                                        state: .suspended,
                                        archive: nil))
    } catch {
     
     player.playerStateDelegate?
      .playerWillChangeState(deviceID: player.inputVSSSearchResult.id, to: .error)
     
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
    
    animateControlsEnabledState(mask: allControlsExcept([.stop, .refresh], state: false)) {
     player[.stop]?.tintColor = .systemRed.withAlphaComponent(0.85)
     player[.stop]?.transform = .init(scaleX: 1.1, y: 1.1)
     player.playerContext.pause()
     
     player.playerStateDelegate?.playerFinishedLiveStreaming(deviceID: player.inputVSSSearchResult.id)
     
     player.playerStateDelegate?
      .playerDidChangeState(deviceID: player.inputVSSSearchResult.id, to: .stopped)
    }
    
    do {
      ///TRY TO SET KEEP ALIVE STATE NOW **STOPPED**
     try updateKeepAliveState(to: .init(mode: .unchanged,
                                        state: .suspended,
                                        archive: nil))
    } catch {
     
     player.playerStateDelegate?
      .playerWillChangeState(deviceID: player.inputVSSSearchResult.id, to: .error)
     
     player.playerState = Failed<P>(player: player,
                                    error: .keepAliveStateUpdateFailed(error: error))
    }
    
   }
   
   
  }
  
  private func stopWhenConnecting(){
    //TODO: Stop HTTPS request here...
   player.showAlert(alert: .warning(message: "Подключение к СВН отменено пользователем!"))
   player.playerActivityIndicator.stopAnimating()
   
   animateControlsEnabledState(mask: allControlsExcept([.stop, .refresh], state: false)){
    player[.stop]?.tintColor = .systemRed.withAlphaComponent(0.85)
    player[.stop]?.transform = .init(scaleX: 1.1, y: 1.1)
    
    player.requests.forEach{ $0.cancel() }
    
    player.playerStateDelegate?
     .playerDidChangeState(deviceID: player.inputVSSSearchResult.id, to: .stopped)
   }
   
   
  }
  
  private func playerShutdown() {
   
   player.playerStateDelegate?.playerWillShutdown(deviceID: player.inputVSSSearchResult.id)
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
 
 internal struct PlayingArchive<P: NTXMobileNativePlayerProtocol>:  NTXPlayerState
 where P.Delegate.Device == P.Manager.InputDevice {
  
  internal unowned let player: P
  
  internal let depthSeconds: Int
  
  let liveStreamURL: URL
  
  private func startFinishedPlayingObservation() {
   
   let item = player.playerContext.mediaAssetItem
   
   if #available(iOS 13.0, *) {
    
    let didFinishPlayingArchiveItem = NotificationCenter.default
     .publisher(for: .AVPlayerItemDidPlayToEndTime, object: player.playerContext.mediaAssetItem)
     .receive(on: DispatchQueue.main)
     .sink { [id = player.inputVSSSearchResult.id, depth = depthSeconds ] _ in
      player.playerStateDelegate?.playerFinishedPlayingArchive(deviceID: id, depthSeconds: depth)
     }
    
    (player.playArchiveRecordEndToken as? AnyCancellable)?.cancel()
    player.playArchiveRecordEndToken = didFinishPlayingArchiveItem
    
   } else {
    let didFinishPlayingArchiveItem = NotificationCenter.default
     .addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main)
    { [id = player.inputVSSSearchResult.id, depth = depthSeconds ] _ in
     
     player.playerStateDelegate?
      .playerFinishedPlayingArchive(deviceID: id, depthSeconds: depth)
    }
    
    if let token = player.playArchiveRecordEndToken {
     NotificationCenter.default.removeObserver(token)
    }
    
    player.playArchiveRecordEndToken = didFinishPlayingArchiveItem
   }
  }
  
  private func startArchiveStreaming(from streamURL: URL) {
   
   player.playerContext.pause()
   
   player.playerContext.startPlayback(from: streamURL,
                                      useLiveStreamingWhilePaused: true,
                                      retryCount: .max) { result in
    switch result {
     case .success(_ ):
      
      debugPrint ("SUCCESS!! PLAYING ARCHIVE RECORD!")
      
      player.showAlert(alert: .info(message: "Архивная запись успешно загружена!"))
      
      startFinishedPlayingObservation()
      
      UIView.transition(from:     player.playerPreloadView,
                        to:       player.playerContext,
                        duration: player.transitionDurationOfContexts,
                        options:  [.showHideTransitionViews, .transitionCrossDissolve]) { _ in
       
       
       player.playerActivityIndicator.stopAnimating()
       
       animateControlsEnabledState(mask: [.playArchiveBack    : true,
                                          .playArchiveForward : true,
                                          .play               : false,
                                          .pause              : true]) {
                                           player.playerStateDelegate?
                                            .playerWillPlayArchiveVideo(deviceID: player.inputVSSSearchResult.id,
                                                                        depthSeconds: depthSeconds)
                                           
                                           player.playerStateDelegate?
                                            .playerDidChangeState(deviceID: player.inputVSSSearchResult.id, to: .playing)
                                           
                                           player.playerMutedStateView.isHidden = false
                                           player.showAlert(alert: .warning(message: "Архив воспроизводится с выключенным звуком!"))
                                           
                                           
                                          }
       
       
       
       do {
         ///TRY TO SET KEEP ALIVE STATE NOW **PLAYING ARCHIVE ** FROM ARCHIVE ASSET...
        try updateKeepAliveState(to: .init(mode: .archiveVideo, state: .playing, archive: nil))
       } catch {
        
        player.playerStateDelegate?
         .playerWillChangeState(deviceID: player.inputVSSSearchResult.id, to: .error)
        
        player.playerState = Failed<P>(player: player,
                                       error: .keepAliveStateUpdateFailed(error: error))
       }
       
      }
      
     case .failure(let error):
      
      debugPrint ("FAILURE!!! PLAYER CONTEXT IS NOT READY TO PLAY ARCHIVE RECORD!")
      
      player.playerStateDelegate?
       .playerWillChangeState(deviceID: player.inputVSSSearchResult.id, to: .error)
      
      player.playerState = Failed<P>(player: player, error: .playerContextFailed(error: error))
      
      
      
      
    }
   }
  }
  
  func resumeLiveStreaming() {
   
   debugPrint(#function)
   
   player.removeDebounceTimer(for: .playArchiveForward)
   player.removeDebounceTimer(for: .playArchiveBack)
   
   guard let liveURL = player.currentVSSStreamingURL else { return }
   
   player.playerStateDelegate?
    .playerWillChangeState(deviceID: player.inputVSSSearchResult.id, to: .loading)
   
   player.playerState = Streaming<P>(player: player,
                                     streamURL: liveURL,
                                     tryRestartCount: NTXPlayerStates.maxVSSStreamingRequests,
                                     archiveDepth: 0)
   
  }
  
  private func moveArchiveRecord(from prevDepth: Int , to depthSeconds: Int){
   guard depthSeconds < 0 else {
    player.timeLine.isHidden = true
    player.timeLine.setStartPosition(0)
    player.playerMutedStateView.isHidden = true
    resumeLiveStreaming()
    return
   }
   
   guard let archiveContext = player.currentVSSArchiveControls else { return }
   guard let archiveURLString = player.currentVSS?.getArchiveIosUrls()?.first else { return }
   
   let startSec = (archiveContext.start ?? 0) / 1000
   let endSec   = (archiveContext.end   ?? 0) / 1000
   
   let timePoint = endSec + depthSeconds
   
   guard timePoint >= startSec else { return  }
   
   print("ARCHIVE DEPTH SEC: Start - \(startSec) |===>| End - \(endSec) ")
   
   let action: NTXPlayerActions = prevDepth > depthSeconds ? .playArchiveBack : .playArchiveForward
   
   player.playerMutedStateView.isHidden = true
   player.playerContext.isHidden = true
   player.playerPreloadView.isHidden = false
   player.timeLine.isHidden = false
   player.timeLine.setTime(depthSeconds)
   //DEBOUNCE...
   player.setDebounceTimer(for: action){ _ in
    guard let depthURL = URL(string: "\(archiveURLString)&ts=\(timePoint)") else { return }
    
    player.showAlert(alert: .warning(message:
        """
         Запрос на воспроизведение записи архива
         видеонаблюдения с глубиной \(depthSeconds) секунд назад!
        """))
    
    player.timeLine.isHidden = true
    player.timeLine.setStartPosition(depthSeconds)
    player.playerActivityIndicator.startAnimating()
    startArchiveStreaming(from: depthURL)
    
   }
   
  }
  
  internal func handle(priorState: (any NTXPlayerState)?) throws {
   
   debugPrint ("<<< ***** PLAYER PLAYING ARCHIVE STATE ***** >>>")
   
   
   switch priorState {
     
    case let state as Paused<P>         :
     player.playerStateDelegate?.playerFinishedLiveStreaming(deviceID: player.inputVSSSearchResult.id)
     moveArchiveRecord(from: state.archiveDepth, to: depthSeconds)
     
    case let state as Streaming<P>      :
     player.playerStateDelegate?.playerFinishedLiveStreaming(deviceID: player.inputVSSSearchResult.id)
     moveArchiveRecord(from: state.archiveDepth, to: depthSeconds)
     
    case let state as PlayingArchive<P> :
     moveArchiveRecord(from: state.depthSeconds, to: depthSeconds)
     
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
 internal class Failed<P: NTXMobileNativePlayerProtocol>: NSObject, NTXPlayerState
 where P.Delegate.Device == P.Manager.InputDevice {
  
  internal unowned let player: P
  
  internal var error: NTXPlayerError
  
  private func alert(_ message: String) {
   player.showAlert(alert: .error(message: message))
  }
  
  internal func handle(priorState: (any NTXPlayerState)?) throws {
   
   debugPrint ("<<< ***** PLAYER FAILED STATE ***** >>>")
   
   player.playerStateDelegate?
    .playerDidChangeState(deviceID: player.inputVSSSearchResult.id, to: .error)
   
   switch (priorState, error) {
     
    case ( is Connecting<P>, .VSSConnectionRetryCountEcxeeded):
     alert("Не возможно подключиться к данной СВН. Ошибка сервера! Кол-во попыток подключения исчерпано!")
     
     player.playerStateDelegate?
      .playerDidFailedWithError(deviceID: player.inputVSSSearchResult.id,
                                with: .playerFailedToConnect(error: error,
                                                             deviceID: player.inputVSSSearchResult.id))
     
     player.playerStateDelegate?
      .playerWillChangeState(deviceID: player.inputVSSSearchResult.id, to: .stopped)
     
     player.playerState = Stopped(player: player)
     
    case  (is Connecting<P>, .unauthorized(code: let code)):
     debugPrint("*** VSS Connection Failed! *** UNAUTHORIZED PLAYER CLIENT: <\(code)>")
     alert("Ошибка авторизации! Клиент не авторизован! Статус - \(code)!")
     
     player.playerStateDelegate?
      .playerDidFailedWithError(deviceID: player.inputVSSSearchResult.id,
                                with: .playerFailedToAuth(error: error,
                                                          deviceID: player.inputVSSSearchResult.id))
     
     player.playerStateDelegate?
      .playerWillChangeState(deviceID: player.inputVSSSearchResult.id, to: .stopped)
     
     player.playerState = Stopped(player: player)
     
    case let (state as Connecting<P>, .VSSConnectionFailed(error: error)):
     debugPrint("VSS Connection Failed: <\(error.localizedDescription)>")
     
      ///RETRY CONNECT VSS AFTER CONNECTON ERROR!
     player.playerState = Connecting(player: player, tryCount: state.tryCount - 1)
     
    case (_ , .noStreamingURL):
     debugPrint("NO VSS CDN URL in received JSON data after parsing: <\(error.localizedDescription)>")
     alert("Контент ресурс для подключения вещания данной СВН отсутсвует на сервере!")
     
     player.playerStateDelegate?
      .playerDidFailedWithError(deviceID: player.inputVSSSearchResult.id,
                                with: .playerFailedToGetInfo(error: error,
                                                             deviceID: player.inputVSSSearchResult.id))
     
     player.playerStateDelegate?
      .playerWillChangeState(deviceID: player.inputVSSSearchResult.id, to: .stopped)
     
     player.playerState = Stopped(player: player)
     
     
    case let (priorState?, .snapshotPreloadFailed(error: error)) :
     
     debugPrint("VSS Snapshot Preload Failed: <\(error.localizedDescription)>")
     
     alert("Не удалось загрузить предварительный снимок с данной СВН. Подключение к СВН будет продолжено!")
     
     player.playerState = priorState
     
    case let (state as Streaming<P>,  .playerContextFailed) :
     debugPrint("Player AVPlayer Context Error: <\(error.localizedDescription)>")
     
     alert("Вещание с данного ресурса СВН временно не доступно! Запрос будет отправлен повторно!")
     
      ///TRY RESTART STREAMING FROM VSS AFTER INTERNAL CONTEXT AV PLAYER ERROR!
     player.playerState = Streaming(player: player,
                                    streamURL: state.streamURL,
                                    tryRestartCount: state.tryRestartCount - 1,
                                    archiveDepth: state.archiveDepth)
     
    case (is Streaming<P>,  .playerContextRetryCountEcxeeded) :
     
     alert("Вещание полученного ресурса СВН не возможно! Кол-во попыток подключения исчерпано!")
     
     player.playerStateDelegate?
      .playerDidFailedWithError(deviceID: player.inputVSSSearchResult.id,
                                with: .playerFailedToPlay(error: error,
                                                          deviceID: player.inputVSSSearchResult.id))
     
     player.playerStateDelegate?
      .playerWillChangeState(deviceID: player.inputVSSSearchResult.id, to: .stopped)
     
     player.playerState = Stopped(player: player)
     
    case let (state as PlayingArchive<P>,  .playerContextFailed) :
     debugPrint("Player AVPlayer Archive Context Error: <\(error.localizedDescription)>")
     
     let depthSeconds = state.depthSeconds - player.archiveTimeStepSeconds
     
     alert("""
           Не возможно воспроизвести запись из архива c глубиной \(state.depthSeconds) сек.
           Будет воспроизведена следующая -\(depthSeconds) cек.
           """)
     
     player.playerStateDelegate?
      .playerDidFailedWithError(deviceID: player.inputVSSSearchResult.id,
                                with: .playerFailedToPlayArchive(error: error,
                                                                 deviceID: player.inputVSSSearchResult.id,
                                                                 depthSeconds: state.depthSeconds))
     
     player.playerState = PlayingArchive(player: player,
                                         depthSeconds: depthSeconds,
                                         liveStreamURL: state.liveStreamURL)
     
    case let (priorState? , .archiveRequestFailed(error: error)) :
     
     debugPrint("Archive Preload Failed: <\(error.localizedDescription)>")
     alert("Не возможно загрузить архивные данные СВН с сервера")
     
     player.playerState = priorState
     
    case (_, .stateError(error: let error)):
     debugPrint("Player State Transition Error: <\(error.localizedDescription)>")
     
    case (_, .noLastEnteredBackground):
     debugPrint("Last entered background time stamp missing: <\(error.localizedDescription)>")
     
    default:
     debugPrint("Undefined Failure State: <\(String(describing: priorState)) - \(error.localizedDescription)>")
     
     alert("Внутреняя ошибка плеера! Остановка плеера...")
     
     player.playerStateDelegate?
      .playerWillChangeState(deviceID: player.inputVSSSearchResult.id, to: .stopped)
     
     player.playerState = Stopped(player: player)
   }
   
   try updateKeepAliveState(to: .init(mode: .unchanged, state: .error, archive: nil))
  }
  
  
  
  
  internal init(player: P, error: NTXPlayerError){
   self.error = error
   self.player = player
   super.init()
  }
  
  
  
  
  
 }
 
 internal struct Invalidated<P: NTXMobileNativePlayerProtocol>: NTXPlayerState
 where P.Delegate.Device == P.Manager.InputDevice {
  
  internal unowned let player: P
  
  internal func handle(priorState: (any NTXPlayerState)?) throws {
   
   debugPrint ("<<< ***** PLAYER INVALIDATED STATE ***** >>>")
   
   guard priorState is Stopped<P> else {
    throw StateError.unexpectedState(prior: priorState, current: self)
   }
   
   invalidateNotificationsObservations()
   player.shutdownHandler(player.inputVSSSearchResult)
  }
  
  
  
  
  
  private func invalidateNotificationsObservations() {
   
   debugPrint(#function)
   
   if #available(iOS 13.0, *) {
    player.notificationsTokens.compactMap{ $0 as? AnyCancellable }.forEach{ $0.cancel() }
    player.notificationsTokens.removeAll()
    (player.playArchiveRecordEndToken as? AnyCancellable)?.cancel()
    
   } else {
    player.notificationsTokens.forEach { NotificationCenter.default.removeObserver($0) }
    
    if let token = player.playArchiveRecordEndToken {
     NotificationCenter.default.removeObserver(token)
    }
   }
  }
  
  
  
 }
 
}
