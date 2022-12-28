 ///PLAYER INTERNAL CORE OBJECTS OF STATES.

import Combine
import UIKit


internal protocol NTXPlayerState  {
 
 associatedtype Player: NTXMobileNativePlayerProtocol
 
 var player: Player { get }
 
 func handle(priorState: (any NTXPlayerState)?) throws
}

internal extension NTXPlayerState where Player.Delegate.Device == Player.Manager.InputDevice {
 
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
  UIView.animate(withDuration: duration) { [ weak player ] in
   player?.playerControls.forEach{ $0.alpha = NTXPlayerStates.controlDisabledOpacity }
  } completion: { [ weak player ]  _ in
   player?.playerControls.forEach { $0.isUserInteractionEnabled = false }
   completion?()
  }
  
 }
 
 func animateEnableAllControls(duration: TimeInterval = NTXPlayerStates.controlStateAnimationDuration,
                               completion: (() -> ())? = nil){
  UIView.animate(withDuration: duration) { [ weak player ] in
   player?.playerControls.forEach { $0.alpha = 1.0 }
  } completion: { [ weak player ] _ in
   player?.playerControls.forEach { $0.isUserInteractionEnabled = false }
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
  UIView.animate(withDuration: duration) { [ weak player ] in
   statesMap.forEach { (action, state) in
    player?[action]?.alpha = state ? 1.0 : NTXPlayerStates.controlDisabledOpacity
   }
   
  } completion: { [ weak player ] _ in
   statesMap.forEach { (action, state) in
    player?[action]?.isUserInteractionEnabled = state
   }
   completion?()
  }
  
 }
 
}

internal enum NTXPlayerError: Error {
 
 case snapshotPreloadFailed           (error: Error)
 case liveviewModeLoadFailed          (error: Error, date: Date)
 case VSSConnectionFailed             (error: Error)
 case VSSConnectionRetryCountEcxeeded
 case playerContextFailed             (error: Error)
 case playerContextRetryCountEcxeeded
 case archiveRequestFailed            (error: Error)
 case noStreamingURL
 case keepAliveStateUpdateFailed      (error: Error)
 
 case stateError                      (error: NTXPlayerStates.StateError)
 case noLastEnteredBackground
 case unauthorized                    (code: Int)
 
 case noArchiveShotsURL
 case archiveShotsPrefetchFailed      (error: Error, depth: Int, url: URL?)
 case contextFailedToPlayArchive      (error: Error, from: URL?)
 case failedToFetchDescriptionInfo    (error: Error)
 
}

internal enum NTXPlayerStates {
 
 internal static let controlStateAnimationDuration: TimeInterval = 0.25
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
 
   
    //Can be handled only initially when there is no prior state at all!
   
   if let priorState = priorState {
    throw StateError.unexpectedState(prior: priorState, current: self)
     //this error is processed in player...
   }
   
   initNotificationsObservations()
   disableAllControls()
   
   if player.playerContainerView.superview == player.playerOwnerView {
    player.playerStateDelegate?
     .playerMovedToOwner(deviceID: player.inputVSSSearchResult.id, ownerView: player.playerOwnerView)
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
   
    //ZP = 4.1 in Owner view
   if let tv = player.playerTouchView{
    tv.isHidden = true
    player.playerContainerView.bringSubviewToFront(tv)
    tv.handler = { [ weak tv, weak player ] in
     tv?.isHidden = true
     player?.animateControlsPanels(hidden: false) { [ weak player ] in
      player?.controlsActivityTimer = Timer.scheduledTimer(withTimeInterval: 5.0,
                                                           repeats: false){ [ weak player ] _ in
       guard let tv = player?.playerTouchView else { return }
       player?.animateControlsPanels(hidden: true) { [ weak tv ] in
        tv?.isHidden = false
       }?.startAnimation()
      }
     }?.startAnimation()
    }
   }
   
   
    //ZP = 5
   player.controlGroups.forEach{player.playerContainerView.bringSubviewToFront($0)}
   
    //ZP = 6
   player.playerContainerView.bringSubviewToFront(player.playerAlertView)
   
    //ZP = 7
   player.timeLine.isHidden = true
   player.playerContainerView.bringSubviewToFront(player.timeLine)
   
    ///GO TO CONNECTING STATE...
   
    //ZP = 7
   
   player.playerStateDelegate?
    .playerWillChangeState(deviceID: player.inputVSSSearchResult.id, to: .loading)
   
   player.playerState = Connecting(player: player, tryCount: NTXPlayerStates.maxVSSContextRequests)
   
   
  }
  
  
  private func willResignActiveHandler(_ n: Notification) {
   
   debugPrint ("APP STATE CHANGE TO ", #function)
   
   player.lastTimeAppEnteredBackground = Date()
   
   switch player.playerState {
    case let state as Streaming<P>:
     
     player.playerStateDelegate?
      .playerWillChangeState(deviceID: player.inputVSSSearchResult.id,  to: .paused)
     
     player.playerState = Paused(player: player,
                                 streamURL: state.streamURL,
                                 archiveDepth: state.archiveDepth,
                                 viewMode: state.viewMode,
                                 viewModeInterval: state.viewModeInterval)
     
    case let state as PlayingArchive<P>:
     
     player.playerStateDelegate?
      .playerWillChangeState(deviceID: player.inputVSSSearchResult.id,  to: .paused)
     
     player.playerState = Paused(player: player,
                                 streamURL: state.liveStreamURL,
                                 archiveDepth: state.depthSeconds,
                                 viewMode: state.viewMode,
                                 viewModeInterval: state.viewModeInterval)
     
     
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
     
     player.playerState = Streaming(player            : player,
                                    streamURL         : state.streamURL,
                                    tryRestartCount   : 0,
                                    archiveDepth      : state.archiveDepth,
                                    viewMode          : state.viewMode,
                                    viewModeInterval  : state.viewModeInterval)
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
   
   let vss = player.inputVSSSearchResult
   
   let request = player.connectionsManager.requestVSSConnection(from: vss) { [ weak player ] result in
    
    guard let player = player else { return }
    
    switch result {
     case let .success(deviceContext):
      DispatchQueue.main.async { [ weak player ] in
       debugPrint ("<<<VSS CONNECTION REQUEST SUCCESSFUL>>>: \(deviceContext)", #function)
       player?.currentVSS = deviceContext
      }
        ///``GO TO CONNECTED STATE WITH OBTAINED VSS CONTEXT OBJECT!!!
     player.playerState = Connected<P>(player: player, deviceContext: deviceContext)
    
      
     case let .failure(error):
      
      player.playerStateDelegate?
       .playerWillChangeState(deviceID: player.inputVSSSearchResult.id, to: .error)
      
      player.playerState = Failed<P>(player: player, error: .VSSConnectionFailed(error: error))
    }
    
   }
   
    //keep reference to MAIN VSS CONNECTION request for cancellation in Stopped State.
   player.deviceConnectionRequest = request
   
   
  }
  
  private func refreshed() {
   
   let mv = player.playerMutedStateView
   let ai = player.playerActivityIndicator
 
   UIView.transition(from:     player.playerContext,
                     to:       player.playerPreloadView,
                     duration: player.transitionDurationOfContexts,
                     options:  [.showHideTransitionViews, .transitionCrossDissolve])
   { [ weak player, weak mv, weak ai ] _ in
    mv?.isHidden = true
    ai?.startAnimating()
    player?[.stop]?.tintColor = .white
    player?[.stop]?.transform = .init(scaleX: 1.05, y: 1.05)
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
     
     try updateKeepAliveState(to: .init(mode:   .liveVideo, state:  .loading, archive: nil))
     
     player.playerStateDelegate?
      .playerDidChangeState(deviceID: player.inputVSSSearchResult.id, to: .loading)
     
     player.currentState = .loading
     
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
   
   
   switch priorState {
     
   
    case is Connecting<P>  :
     
     try startLiveStreamingFromConnectedVSS()
     
     fetchDescriptionInfo()
     requestArchiveControls()
     fetchingLivePhotoShot()
     player.playerArchiveImagesCache.prefetch() //prefetch max batch once here
     
    case let state as Failed<P>:
     switch state.error {
      case .failedToFetchDescriptionInfo (error: _)         : fetchDescriptionInfo()
      case .snapshotPreloadFailed        (error: _)         : fetchingLivePhotoShot()
      case .archiveRequestFailed         (error: _)         : requestArchiveControls()
      default: break
     }
     
    default: break
   }
   
  }
  
  
  
  private func startLiveStreamingFromConnectedVSS() throws {
   
   debugPrint(#function)
   
   
   animateControlsEnabledState(mask: allControlsExcept([.stop, .refresh], state: false))
   
    ///#GO TO STREAMING STATE WITH OBTAINED VSS URL...
   
   player.playerStateDelegate?
    .playerWillChangeState(deviceID: player.inputVSSSearchResult.id, to: .loading)
   
   player.playerState = Streaming(player: player,
                                  streamURL: try streamingURL,
                                  tryRestartCount: NTXPlayerStates.maxVSSStreamingRequests,
                                  archiveDepth: 0,
                                  viewMode: false,
                                  viewModeInterval: player.viewModeInterval)
   
  }
  
  
  private func fetchDescriptionInfo() {
   
   debugPrint(#function)
   
   let ID = player.inputVSSSearchResult
   let manager = player.connectionsManager
   player.descriptionInfoRequest = manager.requestVSSShortDescription(for: ID) { [ weak player ] result in
    
    guard let player = player else { return }
    
    switch result {
     case let .success(description):
      DispatchQueue.main.async { [ weak player ] in
       player?.currentVSSDescription = description
       debugPrint("<+VSS DESCRIPTION DATA RECEIVED SUCCESSFULLY+>: \(String(describing: description))")
       
       
      }
     
      
     case let .failure(error):
      DispatchQueue.main.async { [ weak player ] in
       player?.currentVSSDescription = .empty
       debugPrint("<<<***** FAILED TO LOAD DESCRIPTION DATA *****>>>: \(error.localizedDescription)")
      }
      player.playerStateDelegate?
       .playerWillChangeState(deviceID: player.inputVSSSearchResult.id, to: .error)
      
      player.playerState = Failed<P>(player: player, error: .failedToFetchDescriptionInfo(error: error))
    }
   }
   
  }
  
  private func fetchingLivePhotoShot()   {
   
   debugPrint(#function)
   
   guard player.playerPreloadView.image == nil else {
    debugPrint("Using Exisiting Preload", #function)
    return
   }
   
   let request = player.connectionsManager.requestVSSPhotoShot(for: deviceContext){ [ weak player ] result in
    
    guard let player = player else { return }
    
    switch result {
     case let .success(photoShot):
      debugPrint("<+++++ LIVE PHOTO SHOT DATA RECEIVED SUCCESSFULLY +++++>: \(photoShot)")
      let pv = player.playerPreloadView
      DispatchQueue.main.async { [ weak player, weak pv ] in
       guard let player = player else { return }
       pv?.image = photoShot.uiImage
       player.currentPhotoShot = photoShot
       
      }
      
     case let .failure(error):
      
      debugPrint("<<<***** FAILED TO LOAD LIVE PHOTO SHOT DATA *****>>>: \(error.localizedDescription)")
      
      player.playerStateDelegate?
       .playerWillChangeState(deviceID: player.inputVSSSearchResult.id, to: .error)
      
      player.playerState = Failed<P>(player: player, error: .snapshotPreloadFailed(error: error))
      
    }
    
   }
   
   player.archiveControlsRequest = request
    //keep reference to Live Photo Shot request for cancellation in Stopped State.
   
  }
  
  
  private func requestArchiveControls ()  {
   
   debugPrint(#function)
   
   let request = player.connectionsManager.requestVSSArchive(for: deviceContext){ [ weak player ] result in
    
    guard let player = player else { return }
    
    switch result {
     case let .success(archiveContext):
      
      debugPrint("<++++ ARCHIVED CONTROLS RECEIVED SUCCESSFULLY ++++>: \(archiveContext)")
      
      player.currentVSSArchiveControls = archiveContext
      
      let depth = ((archiveContext.end ?? 0) - (archiveContext.start ?? 0)) / 1000
      
      guard depth > 0 else { break }
      
      debugPrint("ARCHIVE DEPTH AVAILABLE (SEC): \(depth)")
      
      
     case let .failure(error):
      
      debugPrint("<<<***** FAILED TO LOAD ARCHIVE CONTROL INFO *****>>>: \(error.localizedDescription)")
      
      player.playerStateDelegate?
       .playerWillChangeState(deviceID: player.inputVSSSearchResult.id,  to: .error)
      
      player.playerState = Failed<P>(player: player, error: .archiveRequestFailed(error: error))
      
    }
    
   }
   
   player.archiveControlsRequest = request
    //keep reference to Archive Controls request for cancellation in Stopped State.
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
  
  let viewMode: Bool
  
  let viewModeInterval: TimeInterval
  
  private func pauseStreaming() {
   
   debugPrint (#function)
   
   player.playerStateDelegate?
    .playerWillChangeState(deviceID: player.inputVSSSearchResult.id, to: .paused)
   
   player.playerState = Paused<P>(player              : player,
                                  streamURL           : streamURL,
                                  archiveDepth        : archiveDepth,
                                  viewMode            : viewMode,
                                  viewModeInterval    : viewModeInterval)
   
  }
  
   ///#PREPARE LIVE STREAMING ASSET FOR PLAYING AND WAIT WHILE IT IS NO READY...
  
  
  private var isArchiveAvailable: Bool {
   guard let archiveControls = player.currentVSSArchiveControls else { return false }
   return archiveControls.end ?? 0 > archiveControls.start ?? 0
  }
  
  
  private func addAdmixtureResizeObservation(_ player: P, _ marker: String ) {
   
   debugPrint(#function)
   
   let context = player.playerContext

   player.admixtureResizeToken = player.playerContext.observe(\.bounds, options: [.new])
   { [ weak context, weak player ] _ , change  in
    
    guard let player = player else { return }
    guard let _ = change.newValue else { return }
    guard let context = context else { return }
    
    DispatchQueue.main.async { [ weak player ] in
     
     guard let player = player else { return }
    
     
     AdmixtureView.createAdmixture(videoRect      : context.videoRect,
                                   attachedTo     : context,
                                   securityMarker : marker)
     
     addAdmixtureResizeObservation(player, marker)
     
    }
    
   }
  }
  
  private func addAdmixture() {
   
   debugPrint(#function)
   
   let context = player.playerContext
   player.securityMarkerRequest = player.connectionsManager.requestClientSecurityMarker
   { [ weak context, weak player  ] result in
    
    guard let player = player else { return }
    guard let context = context else { return }
    
    switch result {
     case let .success(marker):
      DispatchQueue.main.async { [ weak player ] in
       
       guard let player = player else { return }
       
       debugPrint("<+++$ SECURITY MARKER RECEIVED SUCCESSFULLY $+++>", #function)
       
       AdmixtureView.createAdmixture(videoRect      : context.videoRect,
                                     attachedTo     : context,
                                     securityMarker : marker)
       
       addAdmixtureResizeObservation(player, marker)
      }
      
     case let .failure(error):
      debugPrint("SECURITY MARKER REQUEST ERROR", #function, error.localizedDescription)
    }
   }
  }
  
  private func startLiveStreaming() {
   
   debugPrint (#function)
   
   animateControlsEnabledState(mask: [.viewMode: false ])
   
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
                                      retryCount: 100) { [ weak player ] result in
    
    guard let player = player else { return }
    
    switch result {
     case .success(_ ):
      
      player.playerStateDelegate?.playerWillStreamLiveVideo(deviceID: player.inputVSSSearchResult.id)
      
      player.playerStateDelegate?
       .playerWillChangeState(deviceID: player.inputVSSSearchResult.id, to: .playing)
      
      debugPrint ("<<<+++++ SUCCESS!!! PLAYER CONTEXT IS READY TO STREAM +++++>>> ")
      
      player.showAlert(alert: .info(message: "Успешное подключение к выбранной СВН в режиме живого вещания! "))
      
      let ai = player.playerActivityIndicator
      let mutedView = player.playerMutedStateView
      
      UIView.transition(from:     player.playerPreloadView,
                        to:       player.playerContext,
                        duration: player.transitionDurationOfContexts,
                        options:  [.showHideTransitionViews, .transitionCrossDissolve]) { [ weak player,
                                                                                            weak ai,
                                                                                            weak mutedView ] _ in
       
       guard let player = player else { return }
       
       player.showAlert(alert: .warning(message: "Трансляция производится с выключенным звуком! "))
       
       ai?.stopAnimating()
       
       addAdmixture()
       
       guard let mutedView = mutedView else { return }
       
       animateControlsEnabledState(mask: [ .play               : false,
                                           .pause              : true ,
                                           .toggleMuting       : player.isAudioAvailable ,
                                           .playArchiveBack    : isArchiveAvailable ,
                                           .playArchiveForward : false,
                                           .viewMode           : true ])
       { [ weak mutedView, weak player ] in
     
         mutedView?.isHidden = !(player?.isAudioAvailable ?? true)
       }
       
       
       
       do {
         ///TRY TO SET KEEP ALIVE STATE NOW **PLAYING** FROM LIVE STREAMING ASSET...
        
        try updateKeepAliveState(to: .init(mode: .unchanged, state: .playing, archive: nil))
       } catch {
        player.playerState = Failed<P>(player: player,
                                       error: .keepAliveStateUpdateFailed(error: error))
       }
       
       player.playerStateDelegate?
        .playerDidChangeState(deviceID: player.inputVSSSearchResult.id, to: .playing)
       
       player.currentState = .playing
       
       
       
       player.controlsActivityTimer = Timer.scheduledTimer(withTimeInterval: 5.0,
                                                           repeats: false){ [ weak player ] _ in
         guard let tv = player?.playerTouchView else { return }
        
         player?.animateControlsPanels(hidden: true) { [ weak tv ] in
          tv?.isHidden = false
         }?.startAnimation()
        }
       
      }
      
     case .failure(let error):
      
      debugPrint ("<-- FAILURE!!! PLAYER CONTEXT IS NOT READY! -->")
      
      player.playerStateDelegate?
       .playerWillChangeState(deviceID: player.inputVSSSearchResult.id, to: .error)
      
      player.playerState = Failed<P>(player: player,  error: .playerContextFailed(error: error))
      
      
    }
   }
  }
  
  private func resumeLiveStreamingAfterViewMode() {
   
   debugPrint (#function)
   
   player.showAlert(alert: .warning(message: "Возобновление режима живой трансляции с текущей СВН!"))
   
   guard player.playerContext.isReadyToPlay else  {
    
    player.playerStateDelegate?
     .playerWillChangeState(deviceID: player.inputVSSSearchResult.id, to: .loading)
    
    let ai = player.playerActivityIndicator
    
    UIView.transition(from:     player.playerContext,
                      to:       player.playerPreloadView,
                      duration: player.transitionDurationOfContexts,
                      options:  [ .showHideTransitionViews, .transitionCrossDissolve ]) { [ weak ai ] _ in
     
     ai?.startAnimating()
     
     startLiveStreaming()
    }
    
    return
   }
   
   
   let context = player.playerContext
   UIView.transition(from:     player.playerPreloadView,
                     to:       player.playerContext,
                     duration: player.transitionDurationOfContexts,
                     options:  [.showHideTransitionViews, .transitionCrossDissolve]) { [ weak player,
                                                                                         weak context] _ in
    
    guard let player = player else { return }
    
    context?.play()
    
    addAdmixture()
    
    animateControlsEnabledState(mask: [.play         : false,
                                       .pause        : true,
                                       .toggleMuting : player.isAudioAvailable]) { [ weak player ] in
                                        
     guard let player = player else { return }
     player.playerStateDelegate?
      .playerDidChangeState(deviceID: player.inputVSSSearchResult.id, to: .playing)
     
     player.currentState = .playing
     
    }
   }
  }
  
  private func resumeLiveStreamingAfterPause() {
   
   debugPrint (#function)
   
   player.showAlert(alert: .warning(message: "Возобновление режима живой трансляции с текущей СВН!"))
   
   guard player.playerContext.isReadyToPlay else  {
    
    player.playerStateDelegate?
     .playerWillChangeState(deviceID: player.inputVSSSearchResult.id, to: .loading)
    
    let ai = player.playerActivityIndicator
    
    UIView.transition(from:     player.playerContext,
                      to:       player.playerPreloadView,
                      duration: player.transitionDurationOfContexts,
                      options:  [.showHideTransitionViews, .transitionCrossDissolve]) { [ weak ai ] _ in
    
     ai?.startAnimating()
     startLiveStreaming()
    }
    
    return
   }
   
   player.playerContext.play()
  
   animateControlsEnabledState(mask: [.play          :   false,
                                      .pause         :   true,
                                      .toggleMuting  :   player.isAudioAvailable,
                                      .viewMode      :   true ]) { [ weak player ] in
    
    guard let player = player else { return }
    
    player.playerStateDelegate?
     .playerDidChangeState(deviceID: player.inputVSSSearchResult.id, to: .playing)
    
    player.currentState = .playing
    
   }
   
  }
  
  internal func cancelViewModeRequests() {
   
   debugPrint(#function)
   
   player.viewModeLivePhotoShotsRequests.forEach{$0.cancel()}
   player.viewModeLivePhotoShotsRequests.removeAll()
  }
  
  private let liveModeDispatcher = DispatchSemaphore(value: 1)
  
  private let liveModeQueue = DispatchQueue(label: "Player.StreamingState.liveMode.Queue")
  
  ///``VIDEO MODE WHEN STREAMING...``
  
  private func requestLiveVideoShot(_ player: P, _ deviceContext: P.Manager.Device, _ completion: (() -> ())? = nil) {
   
   debugPrint(#function)
   let now = Date()
   var request: AbstractRequest?
   request = player.connectionsManager.requestVSSPhotoShot(for: deviceContext){ [ weak request, weak player ] result in
    
    guard let player = player else { return }
    
    defer {
     DispatchQueue.main.async { [ weak player ] in
      player?.viewModeLivePhotoShotsRequests.removeAll{ $0 === request }
      completion?()
     }
    }
    
    switch result {
      
     case let .success(photoShot):
      debugPrint("LIVE VIDEO MODE PHOTO SHOT DATA AT: [\(now)] RECEIVED SUCCESSFULLY: \(photoShot)")
      
      let pv = player.playerPreloadView
      DispatchQueue.main.async { [ weak player, weak pv ] in
       guard let player = player else { return }
       pv?.image = photoShot.uiImage
       player.currentPhotoShot = photoShot
      }
      
     case let .failure(error):
      player.playerStateDelegate?
       .playerWillChangeState(deviceID: player.inputVSSSearchResult.id, to: .error)
      
      player.playerState = Failed<P>(player: player, error: .liveviewModeLoadFailed(error: error, date: now))
      
    }
    
   }
   
   if let request = request {
    DispatchQueue.main.async { [ weak player ] in
     player?.viewModeLivePhotoShotsRequests.append(request)
    }
   }
  }
 
  private func showViewModeSnapshot(_ player: P, _ deviceContext: P.Manager.Device) {
   
   debugPrint(#function)
   
   let pc = player.playerContext
   let pv = player.playerPreloadView
  
   
   requestLiveVideoShot(player, deviceContext){ [ weak pc, weak pv ] in
    pc?.pause()
    pc?.isHidden = true
    pv?.isHidden = false
    
    animateControlsEnabledState(mask: [.viewMode: true])
   }
  }
  
  private func pollLive(_ player: P, _ deviceContext: P.Manager.Device, delay: TimeInterval) {
 
   let fireIn = max(viewModeInterval - delay, viewModeInterval * 0.01)
   
   debugPrint(#function, "next request in: ", String(format:"%.3f", fireIn))
   
   player.viewModeTimer = Timer.scheduledTimer(withTimeInterval: fireIn, repeats: false){ [ weak player ] _ in
    guard let player = player else { return }
    liveModeQueue.async { [ weak player ] in
     guard let player = player else { return }
     liveModeDispatcher.wait()
     let requestedTime = Date().timeIntervalSince1970
     requestLiveVideoShot(player, deviceContext) { [ weak player ] in
      defer { liveModeDispatcher.signal()}
      guard let player = player else { return }
      let currentDelay = Date().timeIntervalSince1970 - requestedTime
      pollLive(player, deviceContext, delay: (currentDelay + delay) / 2 )
      
     }
    }
   }
  }
  
  private func startLivePolling(_ player: P, _ deviceContext: P.Manager.Device) {
   
   debugPrint(#function)
   
   let ai = player.playerActivityIndicator
   let requestedTime = Date().timeIntervalSince1970
   requestLiveVideoShot(player, deviceContext) { [ weak player, weak ai ] in
    guard let player = player else { return }
    let delay = Date().timeIntervalSince1970 - requestedTime
    pollLive(player, deviceContext, delay: delay)
    animateControlsEnabledState(mask: [.viewMode: true]) { [ weak ai ] in
     ai?.stopAnimating()
    }
   }
   
  }
  
  private func resumeLiveViewModeAfterPause() {
   
   debugPrint(#function)
   
   animateControlsEnabledState(mask: [.viewMode: false ])
   
   guard let deviceContext = player.currentVSS else {
    debugPrint("<VIEW MODE ERROR> NO CURRENT VSS!!!", #function)
    return
   }
   
   player.showAlert(alert: .warning(message: "Возобновление покадрового режима живой трансляции с текущей СВН!"))
   
   guard player.viewModePolling else {
    player.viewModePolling = true
    showViewModeSnapshot(player, deviceContext)
    return
   }
   
   startLivePolling(player, deviceContext)
   
  }
  
  
  private func resumeViewModeAfterPause() {
   
   debugPrint(#function)
   
   defer {
    animateControlsEnabledState(mask: [ .pause: true, .play : false, .viewMode: true])
   }
   
   guard let timePoint = player.viewModeArchiveCurrentTimePoint else {
    resumeLiveViewModeAfterPause()
    return
   }
   
   player.playerState = PlayingArchive(player: player,
                                       depthSeconds: timePoint - player.endSeconds,
                                       liveStreamURL: streamURL,
                                       viewMode: true,
                                       viewModeInterval: viewModeInterval)
   
   
   
  }
  
  private func startViewMode(){
  
   debugPrint(#function)
   
   animateControlsEnabledState(mask: [.viewMode: false ])
   
   guard let deviceContext = player.currentVSS else {
    debugPrint("<VIEW MODE ERROR> NO CURRENT VSS!!!", #function)
    return
   }
   
   player.showAlert(alert: .warning(message: "Трансляция с текущей СВН переводится в покадровый режим!"))
   
   guard player.viewModePolling else {
    player.viewModePolling = true
    showViewModeSnapshot(player, deviceContext)
    return
   }
   
   let ai = player.playerActivityIndicator
   let pc = player.playerContext
   UIView.transition(from:     player.playerContext,
                     to:       player.playerPreloadView,
                     duration: player.transitionDurationOfContexts,
                     options:  [.showHideTransitionViews, .transitionCrossDissolve]) { [ weak player,
                                                                                         weak ai,
                                                                                         weak pc ] _ in
    
    guard let player = player else { return }
    ai?.startAnimating()
    pc?.pause()
    
    startLivePolling(player, deviceContext)
   }
  }
  
  func stopViewMode(){
   
   debugPrint(#function)
   animateControlsEnabledState(mask: [.viewMode: false ])
   
   player.viewModeTimer?.invalidate()
   player.viewModeTimer = nil
//   cancelViewModeRequests()
   
   animateControlsEnabledState(mask: [.viewMode: true  ])
  }
  
  func restartViewMode() {
   debugPrint(#function)
   stopViewMode()
   startViewMode()
  }
  
  internal func handle(priorState: (any NTXPlayerState)?) throws {
   
   debugPrint ("<<< ***** PLAYER STREAMING STATE ***** >>>")
   
   switch priorState {
     
    case let state as Self where !state.viewMode &&  viewMode : startViewMode()  //toggle VM
    case let state as Self where !state.viewMode && !viewMode : pauseStreaming() //play pressed when playing no VM
    case let state as Self where  state.viewMode &&  viewMode :                  //play pressed when playing in VM
     
    ///`check if viewMode interval changed while streaming & restart viewMode with new interval set by player!
     if state.viewModeInterval !=  viewModeInterval {
      state.restartViewMode()
      break
     }
     
     fallthrough
     
    case let state as Self where  state.viewMode && !viewMode : state.stopViewMode() //toggle VM & resume live...
                                                                startLiveStreaming()
     
    case let state as Paused<P> where !state.viewMode && !viewMode : resumeLiveStreamingAfterPause()
    case let state as Paused<P> where  state.viewMode && !viewMode : startLiveStreaming()
    case let state as Paused<P> where !state.viewMode &&  viewMode : fallthrough
    case let state as Paused<P> where  state.viewMode &&  viewMode : resumeViewModeAfterPause()
     
    case let state as PlayingArchive<P> where  state.viewMode &&  viewMode  : state.stopViewMode()
                                                                              startViewMode()
                                                                              
     
    case let state as PlayingArchive<P> where  state.viewMode && !viewMode  : state.stopViewMode()
                                                                              startLiveStreaming()
                                                                              
                                                                              
    case let state as PlayingArchive<P> where !state.viewMode &&  viewMode  : startViewMode()
    case let state as PlayingArchive<P> where !state.viewMode && !viewMode  : startLiveStreaming()
     
    case is Connected<P> : startLiveStreaming()
     
     player.playerStateDelegate?
      .playerDidChangeState(deviceID: player.inputVSSSearchResult.id, to: .started)
     
     player.currentState = .started
     
     ///#KEEP ALIVE **SUSPENDED** UNTIL PLAYER IS READY TO PLAY FROM LIVE STREAMING ASSET...
    
     try updateKeepAliveState(to: .init(mode: .unchanged, state: .suspended,  archive: nil))
     
    case let failure as Failed<P> :
     switch failure.error {
      case .playerContextFailed: startLiveStreaming()
      default: break
     }
    
    default: break
   }
   
  }
  
 }
 
  //MARK: <<< ***** PLAYER PAUSED STATE ***** >>>
 
 internal struct Paused<P: NTXMobileNativePlayerProtocol>:  NTXPlayerState
  where P.Delegate.Device == P.Manager.InputDevice{
  
  internal unowned let player: P
  
  internal let streamURL: URL
  
  internal let archiveDepth: Int
  
  internal let viewMode: Bool
  
  internal let viewModeInterval: TimeInterval
  
  private func pauseViewMode(after state: PlayingArchive<P>) {
   
   state.stopViewMode()
   
   player.showAlert(alert: .warning(message: "Покадровый режим трансляции архивного видео приостановлен!"))
   
   animateControlsEnabledState(mask: [.play: true, .pause: false]) { [ weak player ] in
    guard let player = player else { return }
    player.playerStateDelegate?
     .playerDidChangeState(deviceID: player.inputVSSSearchResult.id, to: .paused)
    
    player.currentState = .paused
    
   }
  }
  
  private func pauseViewMode(after state: Streaming<P>) {
   
   state.stopViewMode()
   
   player.showAlert(alert: .warning(message: "Покадровый режим живой трансляции приостановлен!"))
   
   animateControlsEnabledState(mask: [.play: true, .pause: false]) { [ weak player ] in
    guard let player = player else { return }
    player.playerStateDelegate?
     .playerDidChangeState(deviceID: player.inputVSSSearchResult.id, to: .paused)
    
    player.currentState = .paused
    
   }
   
  }
  
  private func pauseLivePlayer() {
   
   player.showAlert(alert: .warning(message: "Приостановка живой трансляции с текущей СВН!"))
   
   player.playerContext.pause()
   player.playerContext.isMuted = true
  
   animateControlsEnabledState(mask: [.play: true, .pause: false]) { [ weak player ] in
    guard let player = player else { return }
    
    player.playerStateDelegate?
     .playerDidChangeState(deviceID: player.inputVSSSearchResult.id, to: .paused)
    
    player.currentState = .paused
    
   }
   
  }
  
  private func resumeStreaming() {
   
   player.playerStateDelegate?
    .playerWillChangeState(deviceID: player.inputVSSSearchResult.id, to: .playing)
   
   player.playerState = Streaming(player            : player,
                                  streamURL         : streamURL,
                                  tryRestartCount   : 0, //no retry count nedeed in this state!
                                  archiveDepth      : archiveDepth,
                                  viewMode          : viewMode,
                                  viewModeInterval  : viewModeInterval)
  }
  
  
  internal func handle(priorState: ( any NTXPlayerState )? ) throws {
   
   debugPrint ("<<< ***** PLAYER PAUSED STATE ***** >>>")
   
   switch priorState {
     
    case let state as Self where state.viewMode && viewMode: //toggle pause/streaming...
     
     if state.viewModeInterval != viewModeInterval { break } //check if viewMode interval changed when paused
     resumeStreaming()
    
    case let state as Self where !state.viewMode && !viewMode  : resumeStreaming()
     
    case let state as PlayingArchive<P> where !state.viewMode  : pauseLivePlayer()
    case let state as Streaming<P>      where !state.viewMode  : pauseLivePlayer()
     
    case let state as Streaming<P>      where  state.viewMode  : pauseViewMode(after: state)
    case let state as PlayingArchive<P> where  state.viewMode  : pauseViewMode(after: state)
   
      ///KEEP ALIVE **PAUSED** UNTIL PLAYER IS READY TO PLAY FROM LIVE STREAMING ASSET...
     
     try updateKeepAliveState(to: .init(mode: .unchanged, state: .paused, archive: nil))
     
     
     
    default: break
   }
   
  }
  
  
  
 }
 
 
  //MARK: <<< ***** PLAYER STOPPED STATE ***** >>>
 internal struct Stopped<P: NTXMobileNativePlayerProtocol>: NTXPlayerState
 where P.Delegate.Device == P.Manager.InputDevice {
  
  internal unowned let player: P
  
  private func stopAfterPause() throws {
   
   player.showAlert(alert: .warning(message: """
                                             Трансляция с текущей СВН остановлена без возобновления!
                                             Необходимо обновить плеер для повторного подключения к СВН.
                                             """))
   
   
   animateControlsEnabledState(mask: allControlsExcept([.stop, .refresh], state: false)) { [ weak player ] in
    guard let player = player else { return }
    
    player[.stop]?.tintColor = .systemRed.withAlphaComponent(0.85)
    player[.stop]?.transform = .init(scaleX: 1.1, y: 1.1)
    
    player.playerStateDelegate?.playerFinishedLiveStreaming(deviceID: player.inputVSSSearchResult.id)
    
    player.playerStateDelegate?
     .playerDidChangeState(deviceID: player.inputVSSSearchResult.id, to: .stopped)
    
    player.currentState = .stopped
    
   }
   do { ///TRY TO SET KEEP ALIVE STATE NOW **STOPPED**
    try updateKeepAliveState(to: .init(mode: .unchanged,  state: .suspended, archive: nil))
   } catch {
    
    player.playerStateDelegate?
     .playerWillChangeState(deviceID: player.inputVSSSearchResult.id, to: .error)
    
    player.playerState = Failed<P>(player: player,
                                   error: .keepAliveStateUpdateFailed(error: error))
   }
  }
  
  
  private func stopAfterStreaming() throws {
   
   player.playerContext.pause()
   
   player.showAlert(alert: .warning(message: """
                                             Трансляция с текущей СВН остановлена без возобновления!
                                             Необходимо обновить плеер для повторного подключения к СВН.
                                             """))
   
   UIView.transition(from:      player.playerContext,
                     to:        player.playerPreloadView,
                     duration:  player.transitionDurationOfContexts,
                     options:  [.showHideTransitionViews, .transitionCrossDissolve]) { _ in
    
    animateControlsEnabledState(mask: allControlsExcept([.stop, .refresh], state: false)) { [ weak player ] in
     guard let player = player else { return }
     player[.stop]?.tintColor = .systemRed.withAlphaComponent(0.85)
     player[.stop]?.transform = .init(scaleX: 1.1, y: 1.1)
     
     player.playerStateDelegate?.playerFinishedLiveStreaming(deviceID: player.inputVSSSearchResult.id)
     
     player.playerStateDelegate?
      .playerDidChangeState(deviceID: player.inputVSSSearchResult.id, to: .stopped)
     
     player.currentState = .stopped
     
    }
    
    do { ///TRY TO SET KEEP ALIVE STATE NOW **STOPPED**
     try updateKeepAliveState(to: .init(mode: .unchanged, state: .suspended, archive: nil))
    } catch {
     
     player.playerStateDelegate?
      .playerWillChangeState(deviceID: player.inputVSSSearchResult.id, to: .error)
     
     player.playerState = Failed<P>(player: player,
                                    error: .keepAliveStateUpdateFailed(error: error))
    }
    
   }
   
   
  }
  
  private func cancelAllRequests() {
   
   player.descriptionInfoRequest?  .cancel()
   player.deviceConnectionRequest? .cancel()
   player.archiveControlsRequest?  .cancel()
   player.securityMarkerRequest?   .cancel()
   player.livePhotoShotRequest?    .cancel()
   
   player.archivePhotoShotsPrefetchRequests .forEach{ $0.cancel() }
   player.viewModeLivePhotoShotsRequests    .forEach{ $0.cancel() }
   player.viewModeArchivePhotoShotsRequests .forEach{ $0.cancel() }
  
   
  }
  
  private func stopWhenConnecting(){
  
   player.showAlert(alert: .warning(message: "Подключение к СВН отменено пользователем!"))
   player.playerActivityIndicator.stopAnimating()
   cancelAllRequests()
   animateControlsEnabledState(mask: allControlsExcept([.stop, .refresh], state: false)){ [ weak player ] in
    guard let player = player else { return }
    player[.stop]?.tintColor = .systemRed.withAlphaComponent(0.85)
    player[.stop]?.transform = .init(scaleX: 1.1, y: 1.1)
    
    player.playerStateDelegate?
     .playerDidChangeState(deviceID: player.inputVSSSearchResult.id, to: .stopped)
    
    player.currentState = .stopped
    
   }
   
   
  }
  
  private func playerShutdown() {
   
   player.playerStateDelegate?.playerWillShutdown(deviceID: player.inputVSSSearchResult.id)
   player.playerState = Invalidated(player: player)
  }
  
  internal func handle(priorState: ( any NTXPlayerState )? ) throws {
   
   debugPrint ("<<< ***** PLAYER STOPPED STATE ***** >>>")
   
   
   switch priorState {
     
    case is Self                   : playerShutdown()
     
    case let state as PlayingArchive<P>      :  state.stopViewMode(); try stopAfterStreaming()
 
    case let state as Streaming<P>           :  state.stopViewMode(); try stopAfterStreaming()
     
    case is Paused<P>              : try stopAfterPause()
    case is Connected<P>           : fallthrough
    case is Connecting<P>          : stopWhenConnecting()
    
 
  
    default: break
   }
   
  }
  
 }
 
  //MARK: <<< ***** PLAYER ARCHIVE STATE ***** >>>
 
 internal struct PlayingArchive<P: NTXMobileNativePlayerProtocol>:  NTXPlayerState
  where P.Delegate.Device == P.Manager.InputDevice {
  
  internal unowned let player: P
  
  internal let depthSeconds: Int
  
  internal let liveStreamURL: URL
  
  internal let viewMode: Bool
  
  internal let viewModeInterval: TimeInterval
  
  private func startFinishedPlayingObservation() {
   
   let item = player.playerContext.mediaAssetItem
   
   if #available(iOS 13.0, *) {
    
    let didFinishPlayingArchiveItem = NotificationCenter.default
     .publisher(for: .AVPlayerItemDidPlayToEndTime, object: item)
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
   
   debugPrint(#function)
   
   player.playerContext.pause()
   
   player.playerContext.startPlayback(from: streamURL,
                                      useLiveStreamingWhilePaused: true,
                                      retryCount: .max) { [ weak player ] result in
    
    guard let player = player else { return }
    
    switch result {
     case .success(_ ):
      
      debugPrint ("<<< SUCCESS! READY TO PLAY ARCHIVE RECORD! >>>")
      
      player.showAlert(alert: .info(message: "Архивная запись успешно загружена!"))
      
      startFinishedPlayingObservation()
      
      let ai = player.playerActivityIndicator
      UIView.transition(from:     player.playerPreloadView,
                        to:       player.playerContext,
                        duration: player.transitionDurationOfContexts,
                        options:  [.showHideTransitionViews, .transitionCrossDissolve])
      { [ weak player, weak ai ] _ in
       
       guard let player = player else { return }
       
       ai?.stopAnimating()
       
       animateControlsEnabledState(mask: [.playArchiveBack    : true,
                                          .playArchiveForward : true,
                                          .play               : false,
                                          .pause              : true,
                                          .viewMode: true ] ) { [ weak player ] in
                                           
        guard let player = player else { return }
                                           
        player.playerStateDelegate?
         .playerWillPlayArchiveVideo(deviceID: player.inputVSSSearchResult.id,
                                     depthSeconds: depthSeconds)
        
        player.playerStateDelegate?
         .playerDidChangeState(deviceID: player.inputVSSSearchResult.id, to: .playing)
        
        player.currentState = .playing
        player.playerMutedStateView.isHidden = !player.isAudioAvailable
        player.showAlert(alert: .warning(message: "Архив воспроизводится с выключенным звуком!")) }
       
       
       
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
      
      player.playerState = Failed<P>(player: player,
                                     error: .contextFailedToPlayArchive(error: error, from: streamURL))
      
      
      
      
    }
   }
  }
  
  func resumeLiveStreaming() {
   
   debugPrint(#function)
   
   player.removeDebounceTimer(for: .playArchiveForward)
   player.removeDebounceTimer(for: .playArchiveBack)
   
   guard let liveURL = player.currentVSSStreamingURL else { return }
   
   
   player.playerState = Streaming<P>(player            : player,
                                     streamURL         : liveURL,
                                     tryRestartCount   : NTXPlayerStates.maxVSSStreamingRequests,
                                     archiveDepth      : 0, //no retry state here
                                     viewMode          : viewMode,
                                     viewModeInterval  : viewModeInterval)
   
  }
  
  private func moveArchiveRecord(from prevDepth: Int , to depthSeconds: Int){
   
   debugPrint(#function, prevDepth, depthSeconds)
   
   animateControlsEnabledState(mask: [.viewMode: false ])
   
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
   
   guard timePoint >= startSec else { return }
   
   print("ARCHIVE DEPTH SEC: Start - \(startSec) |===>| End - \(endSec) ")
   
   let action: NTXPlayerActions = prevDepth > depthSeconds ? .playArchiveBack : .playArchiveForward
   
   player.playerMutedStateView.isHidden = true
   player.playerContext.isHidden = true
   player.playerPreloadView.isHidden = false
   player.timeLine.isHidden = false
   player.timeLine.setTime(depthSeconds)
  
   player.playerArchiveImagesCache.image(with: timePoint) { image in
    player.playerPreloadView.image = image
   }
   
   
   ///``DEBOUNCE ACTION...
   player.setDebounceTimer(for: action){ _ in
    guard let depthURL = URL(string: "\(archiveURLString)&ts=\(timePoint)") else { return }
    
    player.showAlert(alert: .warning(message:
        """
         Запрос на воспроизведение записи архива
         видеонаблюдения \(viewMode ? "в покадровом режиме" : "") с глубиной: (\(depthSeconds)) сек. назад!
        """))
    
    player.timeLine.isHidden = true
    player.timeLine.setStartPosition(depthSeconds)
    player.playerActivityIndicator.startAnimating()
    
    if viewMode {
     startViewMode(at: timePoint, to: endSec)
    } else {
     startArchiveStreaming(from: depthURL)
    }
    
   }
   
  }
  
  
  private let viewModeDispatcher = DispatchSemaphore(value: 1)
  private let viewModeQueue = DispatchQueue(label: "Player.PlayingArchiveState.Queue")
  
  
  
  private func pollArchive (_ player: P, _ timePoint: Int, delay: TimeInterval, _ endTimePoint: Int ) {
   
   let fireIn = max(viewModeInterval - delay, viewModeInterval * 0.01)
   
   debugPrint(#function, "at: \(timePoint) with delay: \(String(format:"%.3f", fireIn))")
   
   guard timePoint <= endTimePoint else {
    stopViewMode()
    resumeLiveStreaming()
    return
   }
   
   player.viewModeArchiveCurrentTimePoint = timePoint
   
   player.viewModeTimer = Timer.scheduledTimer(withTimeInterval: fireIn, repeats: false){ [ weak player ]  _ in
  
    guard let player = player else { return }
    
    viewModeQueue.async { [ weak player ] in
     guard let player = player else { return }
     viewModeDispatcher.wait()
     let pv = player.playerPreloadView
     let ai = player.playerActivityIndicator
     let requestedTime = Date().timeIntervalSince1970
     player.playerArchiveImagesCache.image(with: timePoint) { [ weak pv, weak player, weak ai ] image in
      defer { viewModeDispatcher.signal() }
      guard let player = player else { return }
      let currentDelay = Date().timeIntervalSince1970 - requestedTime
      if let image = image {
       pv?.image = image
       if ai?.isAnimating ?? false { ai?.stopAnimating() }
      }
      pollArchive(player, timePoint + Int(viewModeInterval), delay: (delay + currentDelay) / 2 , endTimePoint)
      
     }
    }
   }
  }
  
  private func startPollingArchive (_ player: P, _ timePoint: Int, _ endTimePoint: Int) {
   
   debugPrint(#function)
   
   let requestedTime = Date().timeIntervalSince1970
   let pv = player.playerPreloadView
   let ai = player.playerActivityIndicator
   player.playerArchiveImagesCache.image(with: timePoint) { [ weak player, weak pv, weak ai ] image in
    guard let player = player else { return }
    let delay = Date().timeIntervalSince1970 - requestedTime
    
    if let image = image {
     pv?.image = image
     ai?.stopAnimating()
    }
    
    animateControlsEnabledState(mask: [.viewMode: true ])
    
    pollArchive(player, timePoint + Int(viewModeInterval), delay: delay, endTimePoint)
   }
  }
  
  private func fetchArchiveImage(at timePoint: Int, to endTimePoint: Int) {
   
   debugPrint(#function, timePoint)
   
   guard timePoint <= endTimePoint else {
    stopViewMode()
    resumeLiveStreaming()
    return
   }
   
   let pv = player.playerPreloadView
   player.playerArchiveImagesCache.image(with: timePoint) { [ weak pv ] image in pv?.image = image }
   
   animateControlsEnabledState(mask: [.viewMode: true ])
  }
  
  private func startViewMode(at timePoint: Int, to endTimePoint: Int) {
   
   debugPrint(#function, timePoint)
   
   guard player.viewModePolling else {
    player.viewModePolling = true
    fetchArchiveImage(at: timePoint, to: endTimePoint)
    return
   }
   
   startPollingArchive(player, timePoint, endTimePoint)
   
  }
  
  internal func cancelViewModeRequests() {
   player.archivePhotoShotsPrefetchRequests.forEach{ $0.cancel() }
   player.archivePhotoShotsPrefetchRequests.removeAll()
  }
  
  internal func stopViewMode() {
   
   debugPrint(#function)
  
   player.viewModeTimer?.invalidate()
   player.viewModeTimer = nil
//   cancelViewModeRequests()
  
  }
  
  internal func handle(priorState: (any NTXPlayerState)? ) throws {
   
   debugPrint ("<<< ***** PLAYER PLAYING ARCHIVE STATE ***** >>>")
   
   switch priorState {
     
    case let state as Paused<P>         :
     player.playerStateDelegate?.playerFinishedLiveStreaming(deviceID: player.inputVSSSearchResult.id)
     moveArchiveRecord(from: state.archiveDepth, to: depthSeconds)
     
    case let state as Streaming<P>      :
     if state.viewMode { state.stopViewMode() }
     player.playerStateDelegate?.playerFinishedLiveStreaming(deviceID: player.inputVSSSearchResult.id)
     moveArchiveRecord(from: state.archiveDepth, to: depthSeconds)
     
    case let state as PlayingArchive<P> :
     if state.viewMode { state.stopViewMode() }
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
  
  internal func handle( priorState: (any NTXPlayerState)? ) throws {
   
   debugPrint ("<<< ***** PLAYER FAILED STATE ***** >>>")
   
   player.playerStateDelegate?
    .playerDidChangeState(deviceID: player.inputVSSSearchResult.id, to: .error)
   
   player.currentState = .error
   
   switch (priorState, error) {
     
    case ( is Connecting<P>, .VSSConnectionRetryCountEcxeeded ):
     
     alert("""
           Не возможно подключиться к данной СВН. Ошибка сервера!
           Кол-во попыток подключения исчерпано!
           """)
     
     player.playerStateDelegate?  ///``PlayerDelegate.playerFailedToAuth(1)``
      .playerDidFailedWithError(deviceID: player.inputVSSSearchResult.id,
                                with: .playerFailedToConnect(error: error,
                                                             deviceID: player.inputVSSSearchResult.id,
                                                             url: player.deviceConnectionRequest?.requestURL))
     
     player.playerStateDelegate?
      .playerWillChangeState(deviceID: player.inputVSSSearchResult.id, to: .stopped)
     
     player.playerState = Stopped(player: player)
     
    case  ( is Connecting<P>, let .unauthorized(code: code) ) :
     
     debugPrint("*** VSS Connection Failed! *** UNAUTHORIZED PLAYER CLIENT: <\(code)> ")
     
     alert("Ошибка авторизации! Клиент не авторизован для вещания СВН на портале! Статус - \(code)!")
     
     player.playerStateDelegate?  ///``PlayerDelegate.playerFailedToAuth(2)``
      .playerDidFailedWithError(deviceID: player.inputVSSSearchResult.id,
                                with: .playerFailedToAuth(error: error,
                                                          deviceID: player.inputVSSSearchResult.id,
                                                          url: player.deviceConnectionRequest?.requestURL))
     
     player.playerStateDelegate?
      .playerWillChangeState(deviceID: player.inputVSSSearchResult.id, to: .stopped)
     
     player.playerState = Stopped(player: player)
     
    case let ( state as Connecting<P>, .VSSConnectionFailed(error: error) ):
     debugPrint("VSS Connection Failed: <\(error.localizedDescription)> ")
     
      ///``RETRY CONNECT VSS AFTER CONNECTON ERROR!
     player.playerState = Connecting(player: player, tryCount: state.tryCount - 1)
     
    case (_ , .noStreamingURL):
     
     debugPrint("NO VSS CDN URL in received JSON data after parsing: <\(error.localizedDescription)>")
     
     alert("Контент ресурс для подключения вещания данной СВН отсутсвует на сервере!")
     
     player.playerStateDelegate? ///``PlayerDelegate.playerFailedToGetInfo(3)``
      .playerDidFailedWithError(deviceID: player.inputVSSSearchResult.id,
                                with: .playerFailedToGetInfo(error: error,
                                                             deviceID: player.inputVSSSearchResult.id,
                                                             url: player.deviceConnectionRequest?.requestURL))
     
     player.playerStateDelegate?
      .playerWillChangeState(deviceID: player.inputVSSSearchResult.id, to: .stopped)
     
     player.playerState = Stopped(player: player)
     
     
     
    ///``VSS Live Snapshot Preload Failed...
    ///
    case let (priorState as Streaming<P>, .snapshotPreloadFailed(error: error)) :
     
     debugPrint("VSS STREAMING - Live Snapshot Preload Failed: <\(error.localizedDescription)>")
     
     alert("""
           Не удалось загрузить предварительный снимок с данной СВН во время подключения!
           Подключение для дальнешего вещания с данной СВН будет продолжено!
           """)
     
     player.playerState = priorState ///``Go back to the same state after alerting...
                                     ///
    case let (priorState as Connecting<P>, .snapshotPreloadFailed(error: error)) :
     
     debugPrint("VSS CONNECTED - Live Snapshot Preload Failed: <\(error.localizedDescription)>")
     
     alert("""
           Не удалось загрузить предварительный снимок с данной СВН во время подключения!
           Подключение для дальнешего вещания с данной СВН будет продолжено!
           """)
     
     player.playerState = priorState ///``Go back to the same state after alerting...
    
    case let (priorState as Connected<P>, .failedToFetchDescriptionInfo(error: error)) :
     
     debugPrint("VSS CONNECTING - VSS Fetch Description Failed: <\(error.localizedDescription)>")
     
     alert("""
           Не удалось загрузить информацию о технических возможностях СВН!
           Подключение для дальнешего вещания с данной СВН будет продолжено!
           """)
     
     player.playerState = priorState ///``Go back to the same state after alerting...
                                     
    case let (priorState as Streaming<P>, .failedToFetchDescriptionInfo(error: error)) :
     
     debugPrint("VSS STREAMING - VSS Fetch Description Failed: <\(error.localizedDescription)>")
     
     alert("""
           Не удалось загрузить информацию о технических возможностях СВН!
           Подключение для дальнешего вещания с данной СВН будет продолжено!
           """)
     
     player.playerState = priorState ///``Go back to the same state after alerting...
     
     ///``VSS Video Mode Snapshot Load Failed...``
    case let (priorState as Streaming<P>, .liveviewModeLoadFailed(error: error, date: date)):
     
     debugPrint("VSS Video Mode Snapshot Load Failed at <\(date)>: <\(error.localizedDescription)>")
     
     guard priorState.viewMode else {
      
      alert("""
           Не удалось загрузить текущий снимок во время живого просмотра кадрами!
           Загрузка снимка отменена последней операцией плеера!
           """)
      
      player.playerState = priorState ///``Go back to the same state without alerting...``
      break
     }
     
     alert("Не удалось загрузить текущий снимок с данной СВН в режиме живого просмотра кадрами!")
     
     player.playerStateDelegate? ///``PlayerDelegate.playerFailedToPlay(4)``
      .playerDidFailedWithError(deviceID: player.inputVSSSearchResult.id,
                                with: .playerFailedToPlay(error: error,
                                                          deviceID: player.inputVSSSearchResult.id,
                                                          url: player.currentPhotoShotURL))
     
     player.playerState = priorState ///``Go back to the same state after alerting...``
                                     
     
    case let (priorState as PlayingArchive<P>, .liveviewModeLoadFailed(error: error, date: date)):
     
     debugPrint("VSS ARCHIVE - Live Fetch Snapshot Image Error: <\(error.localizedDescription)>")
     
     alert("""
           Не удалось загрузить снимок за \(date) во время живой трансляции!
           Загрузка снимка отменена последней операцией плеера!
           """)
     
     player.playerState = priorState ///``Go back to the same state after alerting...
     
     
    case let (priorState as PlayingArchive<P>, .archiveShotsPrefetchFailed(error: error, depth: depth, url: url)):
     
     debugPrint("VSS ARCHIVE - VIEW Mode Snapshot Fetch Failed at <\(depth)>: <\(error.localizedDescription)>")
     
     guard priorState.viewMode else {
      
      alert("""
           Не удалось загрузить снимок во время просмотра архивного видео кадрами!
           Загрузка снимка отменена последней операцией плеера!
           """)
      
      player.playerState = priorState ///``Go back to the same state without alerting...``
                                     
      break
     }
     
     alert("Не удалось загрузить текущий снимок с данной СВН в режиме архивного просмотра кадрами!")
     
     player.playerStateDelegate? ///``PlayerDelegate.playerFailedToPlay(4)``
      .playerDidFailedWithError(deviceID: player.inputVSSSearchResult.id,
                                with: .playerFailedToPlay(error: error,
                                                          deviceID: player.inputVSSSearchResult.id,
                                                          url: url))
     
     player.playerState = priorState ///``Go back to the same state after alerting...``
                                     
                          
    case let (priorState as Connected<P>, .archiveShotsPrefetchFailed(error: error, depth: depth, url: url)):
     
     debugPrint("VSS CONNECTED - Prefetch Image Error: <\(error.localizedDescription)> from URL: \(url as Any)")
     
     alert("""
           Не удалось загрузить архивный снимок с глубиной: [\(depth)] во время подключения вещания с данной СВН!
           Подключение вещания данной СВН будет продолжено!
           """)
     
     player.playerState = priorState ///``Go back to the same state after alerting...
    
    case let (priorState as Paused<P>, .liveviewModeLoadFailed(error: error, date: date)):
     
     debugPrint("VSS PAUSED Live Fetch Snapshot Image Error: <\(error.localizedDescription)>")
     
     alert("""
           Не удалось загрузить снимок за \(date) во время живой трансляции!
           Загрузка снимка отменена последней операцией плеера!
           """)
     
     player.playerState = priorState ///``Go back to the same state after alerting...
                                    
     
     
     
    case let (priorState as Paused<P>, .archiveShotsPrefetchFailed(error: error, depth: depth, url: url)):
     
     debugPrint("VSS PAUSED - Fetch Archive Image Error: <\(error.localizedDescription)> from URL: \(url as Any)")
     
     alert("""
           Не удалось загрузить архивный снимок с глубиной \(depth)!
           Загрузка архивного снимка отменена последней операцией плеера!
           """)
     
     player.playerState = priorState ///``Go back to the same state after alerting...
                                     
                                   
    case let (priorState as Streaming<P>, .archiveShotsPrefetchFailed(error: error, depth: depth, url: url)):
     
     debugPrint("VSS STREAMING - Fetch Archive Image Error: <\(error.localizedDescription)> from URL: \(url as Any)")
     
     alert("""
           Не удалось загрузить архивный снимок с глубиной \(depth)!
           Загрузка архивного снимка отменена последней операцией плеера!
           """)
     
     player.playerState = priorState ///``Go back to the same state after alerting...
                                  
                                   
    case let (state as Streaming<P>,  .playerContextFailed(error: error)) :
     
     debugPrint("Player AVPlayer Context Error: <\(error.localizedDescription)>")
     
     alert("""
           Вещание с данного ресурса СВН временно не доступно!
           Запрос будет отправлен повторно на сервер!
           Количество попыток ограничено!
           """)
     
      ///``TRY RESTART STREAMING FROM VSS AFTER INTERNAL CONTEXT AV PLAYER ERROR!
      
     player.playerState = Streaming(player            : player,
                                    streamURL         : state.streamURL,
                                    tryRestartCount   : state.tryRestartCount - 1,
                                    archiveDepth      : state.archiveDepth,
                                    viewMode          : state.viewMode,
                                    viewModeInterval  : state.viewModeInterval)
     
    case let ( state as Streaming<P>,  .playerContextRetryCountEcxeeded) :
     
     alert("""
           Вещание полученного ресурса СВН не возможно!
           Количество попыток подключения исчерпано!
           Плеер будет остановлен.
           """)
     
     player.playerStateDelegate? ///``PlayerDelegate.playerFailedToPlay(4)``
      .playerDidFailedWithError(deviceID: player.inputVSSSearchResult.id,
                                with: .playerFailedToPlay(error: error,
                                                          deviceID: player.inputVSSSearchResult.id,
                                                          url: state.streamURL))
     
     player.playerStateDelegate?
      .playerWillChangeState(deviceID: player.inputVSSSearchResult.id, to: .stopped)
     
     player.playerState = Stopped(player: player)
     
    case let (state as PlayingArchive<P>,  .contextFailedToPlayArchive(error: error, from: url)) :
     debugPrint("Player AVPlayer Archive Context Error: <\(error.localizedDescription)>")
     
     let depthSeconds = state.depthSeconds - player.archiveTimeStepSeconds
     
     alert("""
           Не возможно воспроизвести запись из архива c глубиной [ -\(state.depthSeconds) сек. ]
           Будет воспроизведена следующая запись с глубиной [ -\(depthSeconds) cек. ]
           """)
     
     player.playerStateDelegate? ///``PlayerDelegate.playerFailedToPlayArchive(5)``
      .playerDidFailedWithError(deviceID: player.inputVSSSearchResult.id,
                                with: .playerFailedToPlayArchive(error        : error,
                                                                 deviceID     : player.inputVSSSearchResult.id,
                                                                 depthSeconds : state.depthSeconds,
                                                                 url          : url ))
     //swith to the next (-10 s) record request...
     player.playerState = PlayingArchive(player            : player,
                                         depthSeconds      : depthSeconds,
                                         liveStreamURL     : state.liveStreamURL,
                                         viewMode          : state.viewMode,
                                         viewModeInterval  : state.viewModeInterval)
     
    case let (priorState as Connected<P> , .archiveRequestFailed(error: error)) :
     
     debugPrint("Archive Preload Failed: <\(error.localizedDescription)>")
     
     alert("""
           Не возможно загрузить архивные данные СВН во время подключения.
           Вещание будет продолжено в живом режиме!
           Архивные записи будут не доступны!
           """)
     
     player.playerState = priorState ///``Go back to the same state after alerting...
                                     ///
    case let (priorState as Streaming<P> , .archiveRequestFailed(error: error)) :
     
     debugPrint("Archive Preload Failed: <\(error.localizedDescription)>")
     
     alert("""
           Не возможно загрузить архивные данные СВН во время подключения.
           Вещание будет продолжено в живом режиме!
           Архивные записи будут не доступны!
           """)
     
     player.playerState = priorState ///``Go back to the same state after alerting...
                                     
    case let (state as Streaming<P>,  _ ) :
     alert("Внутренняя ошибка плеера при трансляции живого потока!\nОстановка плеера...")
     state.stopViewMode()
     player.playerState = Stopped(player: player)
     
    case let (state as PlayingArchive<P>,  _ ) :
     alert("Внутренняя ошибка плеера при трансляции видео из архива!\nОстановка плеера...")
     state.stopViewMode()
     player.playerState = Stopped(player: player)
     
    case (_, .stateError(error: let error)):
     debugPrint("Player State Transition Error:\n<\(error.localizedDescription)>")
     
    case (_, .noLastEnteredBackground):
     debugPrint("Last entered background time stamp missing: <\(error.localizedDescription)>")
     
    default:
     debugPrint("Undefined Failure State:\n \(error.localizedDescription)")
     
     alert("Внутреняя ошибка состояния плеера!\nОстановка плеера...")
     
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
 
 //MARK: <<< ***** PLAYER INVALIDATED STATE ***** >>>
 
 internal struct Invalidated<P: NTXMobileNativePlayerProtocol>: NTXPlayerState
 where P.Delegate.Device == P.Manager.InputDevice {
  
  internal unowned let player: P
  
  internal func handle(priorState: (any NTXPlayerState)?) throws {
   
   debugPrint ("<<< ***** PLAYER INVALIDATED STATE ***** >>>")
   
   guard priorState is Stopped<P> else {
    throw StateError.unexpectedState(prior: priorState, current: self)
   }
  
   player.shutdownHandler(player.inputVSSSearchResult)
   
  }
  
  
  
  
  
//  private func invalidateNotificationsObservations() {
//
//   debugPrint(#function)
//
//   if #available(iOS 13.0, *) {
//    player.notificationsTokens.compactMap{ $0 as? AnyCancellable }.forEach{ $0.cancel() }
//    player.notificationsTokens.removeAll()
//    (player.playArchiveRecordEndToken as? AnyCancellable)?.cancel()
//
//   } else {
//    player.notificationsTokens.forEach { NotificationCenter.default.removeObserver($0) }
//
//    if let token = player.playArchiveRecordEndToken {
//     NotificationCenter.default.removeObserver(token)
//    }
//   }
//  }
  
  
  
 }
 
}
