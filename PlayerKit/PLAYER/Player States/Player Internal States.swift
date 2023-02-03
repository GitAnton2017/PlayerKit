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
 
// typealias KeepAliveState         = ConnectionManager.KeepAliveState
// typealias KeepAlivePlayerMode    = KeepAliveState.Mode
// typealias KeepAlivePlayerState   = KeepAliveState.State
// typealias KeepAlivePlayerArchive = KeepAliveState.Archive
 
 var inputSearchVSS: Player.Manager.InputDevice { player.inputVSSSearchResult }
 
 var connectionsManager: ConnectionManager  { player.connectionsManager }
 
// func updateKeepAliveState(to state: KeepAliveState) throws {
//
//  debugPrint (#function, state)
//
// try connectionsManager.changeVSSStateForBeating(activePlayerState: state,
//                                               for: inputSearchVSS)
// }
 
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
 
 func animateControlsEnabledState( mask statesMap: [ NTXPlayerActions : Bool] ,
                                   duration: TimeInterval = NTXPlayerStates.controlStateAnimationDuration,
                                   completion: ( () -> () )? = nil) {
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

internal enum NTXPlayerError: Error, CustomDebugStringConvertible {
 
 var prefix: String { "PLAYER STATES ERROR: "}
 
 var debugDescription: String {
  switch self {
   case .VSSConnectionFailed(error: let error):
    return prefix + "VSS (Camera) Initial Connection Request Failed - [\(error)]"
   case .snapshotPreloadFailed(error: let error):
    return prefix + "VSS (Camera) Live Snapshot Request Failed - [\(error)]"
   case .liveviewModeLoadFailed(error: let error, date: let date):
    return prefix + "VSS (Camera) Live View Mode Request Failed at timepoint: [\(date)] - [\(error)]"
   case .invalidVSSConnectionJSONObject(json: let json):
    return prefix + "Invalid VSS (Camera) Request JSON Object: [\(json)]"
   case .invalidArchiveControlsJSONObject(json: let json):
    return prefix + "Invalid VSS (Camera) Archive Controls Request JSON Object: [\(json)]"
   case .invalidSettingsJSONObject(json: let json):
    return prefix + "Invalid VSS (Camera) Settings Request JSON Object: [\(json)]"
   case .invalidVSSListJSONObject(json: let json):
    return prefix + "Invalid VSS (Camera) List Request JSON Object: [\(json)]"
   case .VSSConnectionRetryCountEcxeeded:
    return prefix + "VSS (Camera) Initial Connection Retry Count Ecxeeded"
   case .playerContextFailed(error: let error):
    return prefix + "VSS (Camera) Playback Context Failed to play from provided resource - [\(error)]"
   case .playerContextRetryCountEcxeeded:
    return prefix + "VSS (Camera) Playback Context Retry Count Ecxeeded"
   case .archiveRequestFailed(error: let error):
    return prefix + "VSS (Camera) Archive Controls Request Failed - [\(error)]"
   case .noStreamingURL:
    return prefix + "No streaming URL was found for live streaming"
   case .keepAliveStateUpdateFailed(error: let error):
    return prefix + "Keep Alive Service Failure - [\(error)]"
   case .stateError(error: let error):
    return prefix + "Internal Player State Processing Failure - [\(error)]"
   case .noLastEnteredBackground:
    return prefix + "No Last Entered Background Time Found!"
   case .unauthorized(code: let code):
    return prefix + "Player is not Authorised to Play from VSS Resource. Status Code - \(code)"
   case .noArchiveShotsURL:
    return prefix + "No Archive Shots URL Found"
   case .archiveShotsPrefetchFailed(error: let error, depth: let depth, url: let url):
    return prefix + """
                    Archive Shots Prefetch Failed - \(error)
                    at depth: [\(depth)]
                    from url: [\(String(describing: url))]
                    """
   
   case .contextFailedToPlayArchive(error: let error, from: let from):
    return prefix + "Context Failed to Play Archive - \(error) from url: [\(String(describing: from))]"
   case .failedToFetchDescriptionInfo(error: let error):
    return prefix + "Failed To Fetch VSS (Camera) Description Info - \(error)"
  }
 }
 

 case snapshotPreloadFailed           (error: Error)
 case liveviewModeLoadFailed          (error: Error, date: Date)
 case VSSConnectionFailed             (error: Error)
 
 case invalidVSSConnectionJSONObject  (json: Any)
 case invalidArchiveControlsJSONObject(json: Any)
 case invalidSettingsJSONObject       (json: Any)
 case invalidVSSListJSONObject        (json: Any)
 
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
   player.controlGroups.forEach{
    $0.isHidden = !player.showsInternalControls
    player.playerContainerView.bringSubviewToFront($0)
   }
   
    //ZP = 6
   player.playerContainerView.bringSubviewToFront(player.playerAlertView)
   
    //ZP = 7
   player.timeLine.isHidden = true
   player.playerContainerView.bringSubviewToFront(player.timeLine)
   
    ///GO TO CONNECTING STATE...
   
    //ZP = 7
   
   player.playerContainerView.bringSubviewToFront(player.playerActivityIndicator)
   player.playerActivityIndicator.startAnimating()
   
   player.playerAlertView.isHidden = !player.showsInternalAlerts
   
   player.playerStateDelegate?
    .playerWillChangeState(deviceID: player.inputVSSSearchResult.id, to: .loading)
   
   player.playerState = Connecting(player: player, tryCount: NTXPlayerStates.maxVSSContextRequests)
   
   
  }
  
  
  private func willResignActiveHandler(_ n: Notification) {
   
   debugPrint ("[ INFO MESSAGE! ] APP STATE WILL CHANGE TO <BACKGROUND>", #function)
   
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
   
   debugPrint ("[ INFO MESSAGE! ] APP STATE WILL CHANGE TO <FOREGROUND>", #function)
   
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
       debugPrint ("[+ SUCCESS INFO +] VSS CONNECTION REQUEST SUCCESSFUL: \(deviceContext)", #function)
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
    player?[.stop]?.tintColor = .systemOrange
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
     
//     try updateKeepAliveState(to: .init(mode:   .liveVideo, state:  .loading, archive: nil))
     
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
     
     fetchDescriptionInfo()
     requestArchiveControls()
     fetchingLivePhotoShot()
     player.playerArchiveImagesCache.prefetch() //prefetch max batch once here
     fallthrough
     
    case is Failed<P>: try startLiveStreamingFromConnectedVSS()
     
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
       debugPrint("[+ SUCCESS INFO +] VSS DESCRIPTION DATA RECEIVED SUCCESSFULLY: {\(String(describing: description))}")
       
       
      }
     
      
     case let .failure(error):
      DispatchQueue.main.async { [ weak player ] in
       player?.currentVSSDescription = .empty
       debugPrint("[- ERROR INFO -] FAILED TO LOAD VSS DESCRIPTION DATA: \(error)")
      }
      player.playerStateDelegate?
       .playerWillChangeState(deviceID: player.inputVSSSearchResult.id, to: .error)
      
      player.playerState = Failed<P>(player: player, error: .failedToFetchDescriptionInfo(error: error))
    }
   }
   
  }
  
  private func fetchingLivePhotoShot()   {
   
   debugPrint(#function)
   
   if let currentImage = player.currentPhotoShot?.uiImage {
    debugPrint("[ INFO MESSAGE! ] Using Exisiting Preload", #function)
    player.playerPreloadView.image = currentImage
    return
   }
   
   let request = player.connectionsManager.requestVSSPhotoShot(for: deviceContext){ [ weak player ] result in
    
    guard let player = player else { return }
    
    switch result {
     case let .success(photoShot):
      debugPrint("[+ SUCCESS INFO +] LIVE PHOTO SHOT DATA RECEIVED SUCCESSFULLY: {\(photoShot)}>")
      let pv = player.playerPreloadView
      DispatchQueue.main.async { [ weak player, weak pv ] in
       guard let player = player else { return }
       pv?.image = photoShot.uiImage
       player.currentPhotoShot = photoShot
       
      }
      
     case let .failure(error):
      
      debugPrint("[- ERROR INFO -] FAILED TO LOAD LIVE PHOTO SHOT DATA: {\(error)}")
      
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
      
      debugPrint("[+ SUCCESS INFO +] VSS ARCHIVED CONTROLS RECEIVED SUCCESSFULLY: \(archiveContext)")
      
      player.currentVSSArchiveControls = archiveContext
      
      let begin = TimeInterval( archiveContext.start ?? 0 ) / 1000
      let end   = TimeInterval( archiveContext.end   ?? 0 ) / 1000
      
      let depth = (end - begin) / (24 * 60 * 60)
      
      guard depth > 0 else {
       debugPrint("[ INFO MESSAGE! ] NO ARCHIVE DEPTH AVAILABLE FOR THIS VSS!")
       break
      }
      
      let SD = Date(timeIntervalSince1970: begin)
      let ED = Date(timeIntervalSince1970: end)
      
      debugPrint("[ INFO MESSAGE! ] ARCHIVE DEPTH AVAILABLE (DAYS): \(depth) FROM DATE: [\(SD)] TO DATE: [\(ED)]")
      
     case let .failure(error):
      
      debugPrint("[- ERROR INFO -] FAILED TO LOAD VSS ARCHIVE CONTROLS INFO: {\(error)}")
      
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
       
       debugPrint("[+ SUCCESS INFO +] SECURITY MARKER RECEIVED SUCCESSFULLY: [\(marker)]", #function)
       
       AdmixtureView.createAdmixture(videoRect      : context.videoRect,
                                     attachedTo     : context,
                                     securityMarker : marker)
       
       addAdmixtureResizeObservation(player, marker)
      }
      
     case let .failure(error):
      debugPrint("[- ERROR INFO -] FAILED TO FETCH SECURITY MARKER!", #function, error.localizedDescription)
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
      
      debugPrint ("[+ SUCCESS INFO +] PLAYER CONTEXT IS READY TO STREAM VIDEO FROM VSS!")
      
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
       
       
       
//       do {
//         ///TRY TO SET KEEP ALIVE STATE NOW **PLAYING** FROM LIVE STREAMING ASSET...
//
//      try updateKeepAliveState(to: .init(mode: .unchanged, state: .playing, archive: nil))
//
//       } catch {
//        player.playerState = Failed<P>(player: player,
//                                       error: .keepAliveStateUpdateFailed(error: error))
//       }
//
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
      
      debugPrint ("[- FAILURE INFO -] PLAYER CONTEXT IS NOT READY TO STREAM FROM VSS!")
      
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
   var request: URLSessionRequestRepresentable?
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
      debugPrint("[+ SUCCESS INFO +] LIVE VIDEO MODE PHOTOSHOT DATA AT: [\(now)] RECEIVED SUCCESSFULLY: \(photoShot)")
      
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
   
   debugPrint("[ INFO ] POLL LIVE", #function, "next request in: ", String(format:"%.3f", fireIn))
   
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
    debugPrint("[- ERROR INFO -] FAILED TO GET CURRENT PLAYER VSS OBJECT IN: ", #function)
    return
   }
   
   player.showAlert(alert: .warning(message: "Возобновление покадрового авторежима живой трансляции с текущей СВН !"))
   
   
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
  
  private func startManualViewMode() {
   
   debugPrint(#function)
   
   animateControlsEnabledState(mask: [.viewMode: false ])
   
   guard let deviceContext = player.currentVSS else {
    debugPrint("[- ERROR INFO -] FAILED TO GET CURRENT PLAYER VSS OBJECT")
    return
   }
   
   player.showAlert(alert: .warning(message: "Трансляция с текущей СВН переводится в покадровый ручной режим!"))
   
   showViewModeSnapshot(player, deviceContext)
   
  }
  
  private func nextViewModeSnapshot() {
   
   debugPrint(#function)
   
   animateControlsEnabledState(mask: [.viewMode: false ])
   
   guard let deviceContext = player.currentVSS else {
    debugPrint("[- ERROR INFO -] FAILED TO GET CURRENT PLAYER VSS OBJECT")
    return
   }
 
   showViewModeSnapshot(player, deviceContext)
   
  }
  
  
  private func startPollingViewMode(){
  
   debugPrint(#function)
   
   animateControlsEnabledState(mask: [.viewMode: false ])
   
   guard let deviceContext = player.currentVSS else {
    debugPrint("[- ERROR INFO -] FAILED TO GET CURRENT PLAYER VSS OBJECT")
    return
   }
   
   player.showAlert(alert: .warning(message: "Трансляция с текущей СВН переводится в покадровый авторежим!"))
   
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
  
  func restartPollingViewMode() {
   debugPrint(#function)
   stopViewMode()
   startPollingViewMode()
  }
  
  internal func handle(priorState: (any NTXPlayerState)?) throws {
   
   debugPrint ("<<< ***** PLAYER STREAMING STATE ***** >>>")
   
   switch priorState {
     
    case let state as Self where !state.viewMode && viewMode:
     
     if player.viewModePolling { startPollingViewMode() } else { startManualViewMode() }
    
    case let state as Self where !state.viewMode && !viewMode : pauseStreaming() //play pressed when playing no VM
     
    case let state as Self where  state.viewMode && viewMode :   //play pressed when playing in VM
     
    ///`check if viewMode interval changed while streaming & restart viewMode with new interval set by player!
     if state.viewModeInterval !=  viewModeInterval && player.viewModePolling {
      state.restartPollingViewMode()
      break
     }
     
     if player.viewModePolling { fallthrough } else { nextViewModeSnapshot() }
     
    case let state as Self where  state.viewMode && !viewMode : state.stopViewMode() //toggle VM & resume live...
                                                                startLiveStreaming()
     
    case let state as Paused<P> where !state.viewMode && !viewMode : resumeLiveStreamingAfterPause()
    case let state as Paused<P> where  state.viewMode && !viewMode : startLiveStreaming()
    case let state as Paused<P> where !state.viewMode &&  viewMode : fallthrough
    case let state as Paused<P> where  state.viewMode &&  viewMode : resumeViewModeAfterPause()
     
    case let state as PlayingArchive<P> where  state.viewMode &&  viewMode  : state.stopViewMode()
     if player.viewModePolling { startPollingViewMode() } else { startManualViewMode() }
                                                                              
     
    case let state as PlayingArchive<P> where  state.viewMode && !viewMode  : state.stopViewMode()
                                                                              startLiveStreaming()
                                                                              
                                                                              
    case let state as PlayingArchive<P> where !state.viewMode &&  viewMode  :
     if player.viewModePolling { startPollingViewMode() } else { startManualViewMode() }
     
    case let state as PlayingArchive<P> where !state.viewMode && !viewMode  : startLiveStreaming()
     
    case is Connected<P> : startLiveStreaming()
     
     player.playerStateDelegate?
      .playerDidChangeState(deviceID: player.inputVSSSearchResult.id, to: .started)
     
     player.currentState = .started
     
     ///#KEEP ALIVE **SUSPENDED** UNTIL PLAYER IS READY TO PLAY FROM LIVE STREAMING ASSET...
    
//     try updateKeepAliveState(to: .init(mode: .unchanged, state: .suspended,  archive: nil))
     
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
     
//     try updateKeepAliveState(to: .init(mode: .unchanged, state: .paused, archive: nil))
     
     
     
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
   
//   do { ///TRY TO SET KEEP ALIVE STATE NOW **STOPPED**
//    try updateKeepAliveState(to: .init(mode: .unchanged,  state: .suspended, archive: nil))
//   } catch {
//
//    player.playerStateDelegate?
//     .playerWillChangeState(deviceID: player.inputVSSSearchResult.id, to: .error)
//
//    player.playerState = Failed<P>(player: player,
//                                   error: .keepAliveStateUpdateFailed(error: error))
//   }
   
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
    
//    do { ///TRY TO SET KEEP ALIVE STATE NOW **STOPPED**
//     try updateKeepAliveState(to: .init(mode: .unchanged, state: .suspended, archive: nil))
//    } catch {
//
//     player.playerStateDelegate?
//      .playerWillChangeState(deviceID: player.inputVSSSearchResult.id, to: .error)
//
//     player.playerState = Failed<P>(player: player,
//                                    error: .keepAliveStateUpdateFailed(error: error))
//    }
    
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
   
   player.viewModeArchiveCurrentTimePoint = nil
   
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
   
   let ai = player.playerActivityIndicator
   ai.startAnimating()
   
   player.playerContext.startPlayback(from: streamURL,
                                      useLiveStreamingWhilePaused: true,
                                      retryCount: .max) { [ weak ai, weak player ] result in
    
    guard let player = player else { return }
    
    switch result {
     case .success(_ ):
      
      debugPrint ("<<< [+ SUCCESS INFO +] - READY TO PLAY ARCHIVE RECORD! >>>")
      
      player.showAlert(alert: .info(message: "Архивная запись успешно загружена!"))
      
      startFinishedPlayingObservation()
      
      
     
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
       
       
       
//       do {
//         ///TRY TO SET KEEP ALIVE STATE NOW **PLAYING ARCHIVE ** FROM ARCHIVE ASSET...
//        try updateKeepAliveState(to: .init(mode: .archiveVideo, state: .playing, archive: nil))
//       } catch {
//
//        player.playerStateDelegate?
//         .playerWillChangeState(deviceID: player.inputVSSSearchResult.id, to: .error)
//
//        player.playerState = Failed<P>(player: player,
//                                       error: .keepAliveStateUpdateFailed(error: error))
//       }
       
      }
      
     case .failure(let error):
      
      debugPrint ("[- ERROR INFO -] PLAYER CONTEXT IS NOT READY TO PLAY ARCHIVE RECORD!")
      
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
                                     archiveDepth      : 0,
                                     viewMode          : viewMode,
                                     viewModeInterval  : viewModeInterval)
   
  }
  
  private func playArchiveRecord(at depthSeconds: Int) {
   debugPrint(#function, depthSeconds)
   
   animateControlsEnabledState(mask: [.viewMode: false ])
   
   guard depthSeconds <= 0 else {
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
  
   player.playerMutedStateView.isHidden = true
   player.playerContext.isHidden = true
   player.playerPreloadView.isHidden = false
   
   player.playerArchiveImagesCache.image(with: timePoint) { image in
    guard let image = image else { return }
    player.playerPreloadView.image = image
   }
   
   guard let depthURL = URL(string: "\(archiveURLString)&ts=\(timePoint)") else { return }
   
   player.showAlert(alert: .warning(message:
                                        """
                                         Воспроизведение записи архива
                                         видеонаблюдения с глубиной: (\(depthSeconds)) сек. назад!
                                        """))
   
  

   startArchiveStreaming(from: depthURL)
     
    
 
  }
  
  private func moveArchiveRecord(from prevDepth: Int , to depthSeconds: Int){
   
   debugPrint(#function, prevDepth, depthSeconds)
   
   animateControlsEnabledState(mask: [.viewMode: false ])
   
   guard depthSeconds <= 0 else {
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
   
   //print("ARCHIVE DEPTH SEC: Start - \(startSec) |===>| End - \(endSec) ")
   
   let action: NTXPlayerActions = prevDepth > depthSeconds ? .playArchiveBack : .playArchiveForward
   
   player.playerMutedStateView.isHidden = true
   player.playerContext.isHidden = true
   player.playerPreloadView.isHidden = false
   
   if !viewMode { player.timeLine.setTime(depthSeconds) }
  
   player.playerArchiveImagesCache.image(with: timePoint) { image in
    guard let image = image else { return }
    player.playerPreloadView.image = image
   }
   
   ///``DEBOUNCE ACTION...
   
   let tl = player.timeLine
   
   player.setDebounceTimer(for: action){ [ weak tl ] _ in
    
    guard let depthURL = URL(string: "\(archiveURLString)&ts=\(timePoint)") else { return }
    
    player.showAlert(alert: .warning(message:
        """
         Запрос на воспроизведение записи архива
         видеонаблюдения \(viewMode ? "в покадровом режиме" : "") с глубиной: (\(depthSeconds)) сек. назад!
        """))
    
    tl?.stopAnimating{
     if viewMode {
      startPollingViewMode(at: timePoint, to: endSec)
     } else {
      startArchiveStreaming(from: depthURL)
     }
    }
    
    
   
    
   }
   
  }
  
  
  private let viewModeDispatcher = DispatchSemaphore(value: 1)
  private let viewModeQueue = DispatchQueue(label: "Player.PlayingArchiveState.Queue")
  
  
  private func pollArchive (_ player: P, _ timePoint: Int, delay: TimeInterval, _ endTimePoint: Int ) {
   
   let fireIn = max(viewModeInterval - delay, viewModeInterval * 0.01)
   
   debugPrint("[ INFO ] POLL ARCHIVE", #function, "at: \(timePoint) with delay: \(String(format:"%.3f", fireIn))")
   
   guard timePoint <= endTimePoint else {
    debugPrint("[ INFO ] POLL ARCHIVE STOPPED!", #function)
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
     let requestedTime = Date().timeIntervalSince1970
     player.playerArchiveImagesCache.image(with: timePoint) { [ weak pv, weak player ] image in
      defer { viewModeDispatcher.signal() }
      guard let player = player else { return }
      let currentDelay = Date().timeIntervalSince1970 - requestedTime
      if let image = image { pv?.image = image }
 
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
   ai.startAnimating()
   player.playerArchiveImagesCache.image(with: timePoint) { [ weak player, weak pv, weak ai ] image in
    guard let player = player else { return }
    
    let delay = Date().timeIntervalSince1970 - requestedTime
    
    if let image = image { pv?.image = image }
    
    animateControlsEnabledState(mask: [.viewMode: true ]) { [ weak ai ] in ai?.stopAnimating() }
    
    pollArchive(player, timePoint + Int(viewModeInterval), delay: delay, endTimePoint)
   }
  }
  
  private func fetchArchiveImage(at timePoint: Int, to endTimePoint: Int) {
   
   debugPrint(#function, timePoint)
   
   let ai = player.playerActivityIndicator
   
   guard timePoint <= endTimePoint else {
    ai.stopAnimating()
    stopViewMode()
    resumeLiveStreaming()
    return
   }
   
   let pv = player.playerPreloadView
   
   player.playerArchiveImagesCache.image(with: timePoint) { [ weak pv, weak ai ] image in
    if let image = image { pv?.image = image }
    animateControlsEnabledState(mask: [.viewMode: true ]) { [ weak ai ] in ai?.stopAnimating() }
   }
   
   
  }
  
  private func startPollingViewMode(at timePoint: Int, to endTimePoint: Int) {
   
   debugPrint(#function, timePoint)
   
   guard player.viewModePolling else {
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
     if state.viewMode {
      state.stopViewMode()
      if !viewMode {
       playArchiveRecord(at: state.depthSeconds)
       break
      }
     }
     
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
  
  private var VSSID: P.Delegate.Device.VSSIDType { player.inputVSSSearchResult.id }
  
  private var connectionURL            : URL? { player.deviceConnectionRequest?.requestURL }
  private var archiveControlsURL       : URL? { player.archiveControlsRequest?.requestURL }
  private var livePhotoShotURL         : URL? { player.livePhotoShotRequest?.requestURL }
  private var securityMarkerURL        : URL? { player.securityMarkerRequest?.requestURL }
  private var descriptionInfoURL       : URL? { player.descriptionInfoRequest?.requestURL }
  
  internal func handle( priorState: (any NTXPlayerState)? ) throws {
   
   debugPrint ("<<< ***** PLAYER FAILED STATE ***** >>>")
   
   player.playerStateDelegate?
    .playerDidChangeState(deviceID: player.inputVSSSearchResult.id, to: .error)
   
   player.currentState = .error
   
   switch (priorState, error) {
     
    case ( is Connecting<P>, .VSSConnectionRetryCountEcxeeded ):
     
     debugPrint("""
                <<< ********************* PORTAL CONNECTION ERROR ******************* >>>
                Не возможно подключиться к СВН ID [\(VSSID)]. Ошибка сервера!
                Кол-во попыток подключения исчерпано! Плеер по данной СВН будет остановлен!
                REQUEST URL:  [\(connectionURL?.absoluteString ?? "N/A")]
                PLAYER ERROR: [\(error)>]
                <<< ***************************************************************** >>>
                """)
     
     alert("""
           Не возможно подключиться к СВН ID [\(VSSID)]. Ошибка сервера!
           Кол-во попыток подключения исчерпано!
           Плеер по данной СВН будет остановлен!
           """)
     
     
     
     player.playerStateDelegate?  ///``PlayerDelegate.didFailToConnect(1)``
      .playerDidFailedWithError(deviceID: player.inputVSSSearchResult.id,
                                with: .playerFailedToConnect(error: error,
                                                             deviceID: VSSID,
                                                             url: connectionURL))
     
     player.playerStateDelegate?
      .playerWillChangeState(deviceID: player.inputVSSSearchResult.id, to: .stopped)
     
     player.playerState = Stopped(player: player)
     
    case  ( is Connecting<P>, let .unauthorized(code: code) ) :
     
     debugPrint("""
                <<< ********************* PORTAL AUTHORIZATION ERROR ******************** >>>
                Ошибка авторизации на портале для вещания с СВН ID [\(VSSID)]!
                Клиент не авторизован для вещания на портале! Статус код - \(code)!
                REQUEST URL: [\(connectionURL?.absoluteString ?? "N/A")]
                PLAYER ERROR: [\(error)]
                <<< ********************************************************************* >>>
                """)
     
     alert("""
           Ошибка авторизации СВН ID [\(VSSID)]!
           Клиент не авторизован на портале вещания!
           Статус код ошибки сети - \(code)!
           """)
     
     player.playerStateDelegate?  ///``PlayerDelegate.playerFailedToAuth(2)``
      .playerDidFailedWithError(deviceID: player.inputVSSSearchResult.id,
                                with: .playerFailedToAuth(error: error, deviceID: VSSID, url: connectionURL))
     
     player.playerStateDelegate?
      .playerWillChangeState(deviceID: player.inputVSSSearchResult.id, to: .stopped)
     
     player.playerState = Stopped(player: player)
     
    case let ( state as Connecting<P>, .VSSConnectionFailed(error: error) ):
     debugPrint("""
                <<< *************** VSS (CAMERA) CONNECTION FAILED ****************** >>>
                Ошибка первичного подключения к СВН ID [\(VSSID)]!
                Запрос будет повторен! Кол-во попыток ограничено - [\(state.tryCount)]!!!
                REQUEST URL: [\(connectionURL?.absoluteString ?? "N/A")]
                PLAYER ERROR: [\(error)>]
                <<< ***************************************************************** >>>
                """)
     
      ///``RETRY CONNECT VSS AFTER CONNECTON ERROR!
      
     alert("""
           Ошибка первичного подключения к СВН ID [\(VSSID)]!
           Запрос будет повторен! Кол-во попыток ограничено - [\(state.tryCount)]!
           """)
     
     player.playerState = Connecting(player: player, tryCount: state.tryCount - 1)
     
    case (_ , .noStreamingURL):
     
     debugPrint("""
                <<< *********** NO CAMERA CDN URL FOUND IN RECEIVED SERVER DATA ******* >>>
                Контент ресурс для подключения вещания СВН ID [\(VSSID)] отсутсвует на сервере!
                JSON объект не содежит требуемого поля для получения CDN URL вещания СВН!
                REQUEST URL: [\(connectionURL?.absoluteString ?? "N/A")]
                PLAYER ERROR: [\(error)>]
                <<< ******************************************************************** >>>
                """)
     
     alert("Контент ресурс для подключения вещания СВН ID [\(VSSID)] отсутсвует на сервере!")
     
     player.playerStateDelegate? /// ``PlayerDelegate.playerFailedToGetInfo(3)``
      .playerDidFailedWithError(deviceID: player.inputVSSSearchResult.id,
                                with: .playerFailedToGetInfo(error: error, deviceID: VSSID, url: connectionURL))
     
     player.playerStateDelegate?
      .playerWillChangeState(deviceID: player.inputVSSSearchResult.id, to: .stopped)
     
     player.playerState = Stopped(player: player)
     
    
    ///``VSS Live Snapshot Preload Failed...
    
    case let (priorState as Streaming<P>, .snapshotPreloadFailed(error: error)) :
     
     debugPrint("""
                <<< ************* VSS STREAMING - Live Snapshot Preload Failed ********** >>>
                Не удалось загрузить предварительный снимок СВН ID [\(VSSID)]!
                Подключение для дальнешего вещания с данной СВН будет продолжено!
                REQUEST URL: [\(livePhotoShotURL?.absoluteString ?? "N/A")]
                PLAYER ERROR: [\(error)>]
                <<< ********************************************************************* >>>
                """)
     
     alert("""
           Не удалось загрузить предварительный снимок с данной СВН ID [\(VSSID)] во время подключения!
           Подключение для дальнешего вещания с данной СВН будет продолжено!
           """)
     
     player.playerStateDelegate? /// ``PlayerDelegate.playerFailedToGetInfo(3)``
      .playerDidFailedWithError(deviceID: player.inputVSSSearchResult.id,
                                with: .playerFailedToGetInfo(error: error, deviceID: VSSID, url: livePhotoShotURL))
     
     player.playerState = priorState ///``Go back to the same state after alerting...
                                     ///
    case let (priorState as Connecting<P>, .snapshotPreloadFailed(error: error)) :
     
     debugPrint("""
                <<< *********** VSS CONNECTED - Live Snapshot Preload Failed ************ >>>
                Не удалось загрузить предварительный снимок СВН ID [\(VSSID)]!
                Подключение для дальнешего вещания с данной СВН будет продолжено!
                REQUEST URL: [\(livePhotoShotURL?.absoluteString ?? "N/A")]
                PLAYER ERROR: [\(error)>]
                <<< ********************************************************************* >>>
                """)
     
     alert("""
           Не удалось загрузить предварительный снимок с данной СВН ID [\(VSSID)] во время подключения!
           Подключение для дальнешего вещания с данной СВН будет продолжено!
           """)
     
     player.playerStateDelegate? /// ``PlayerDelegate.playerFailedToGetInfo(3)``
      .playerDidFailedWithError(deviceID: player.inputVSSSearchResult.id,
                                with: .playerFailedToGetInfo(error: error, deviceID: VSSID, url: livePhotoShotURL))
     
     player.playerState = priorState ///``Go back to the same state after alerting...
                                     
    
    case let (priorState as Connected<P>, .failedToFetchDescriptionInfo(error: error)) :
     
     debugPrint("""
                <<< *********** CONNECTED STATE ERROR - VSS Fetch Description Failed ************ >>>
                Не удалось загрузить информацию о технических возможностях СВН ID [\(VSSID)]!
                Подключение для дальнешего вещания будет продолжено c ограничениями!
                REQUEST URL: [\(descriptionInfoURL?.absoluteString ?? "N/A")]
                PLAYER ERROR: [\(error)>]
                <<< ***************************************************************************** >>>
                """)
     
     alert("""
           Не удалось загрузить информацию о технических возможностях СВН ID [\(VSSID)]!
           Подключение для дальнешего вещания с данной СВН будет продолжено c ограничениями!
           """)
     
     player.playerStateDelegate? /// ``PlayerDelegate.playerFailedToGetInfo(3)``
      .playerDidFailedWithError(deviceID: player.inputVSSSearchResult.id,
                                with: .playerFailedToGetInfo(error: error, deviceID: VSSID, url: descriptionInfoURL))
     
     player.playerState = priorState ///``Go back to the same state after alerting...
                                     
    case let (priorState as Streaming<P>, .failedToFetchDescriptionInfo(error: error)) :
     
     debugPrint("""
                <<< ************ STREAMING STATE ERROR - VSS Fetch Description Failed *********** >>>
                Не удалось загрузить информацию о технических возможностях СВН ID [\(VSSID)]!
                Подключение для дальнешего вещания будет продолжено c ограничениями!
                REQUEST URL: [\(descriptionInfoURL?.absoluteString ?? "N/A")]
                PLAYER ERROR: [\(error)>]
                <<< ***************************************************************************** >>>
                """)
     
     alert("""
           Не удалось загрузить информацию о технических возможностях СВН ID [\(VSSID)]!
           Подключение для дальнешего вещания с данной СВН будет продолжено!
           """)
     
     player.playerStateDelegate? /// ``PlayerDelegate.playerFailedToGetInfo(3)``
      .playerDidFailedWithError(deviceID: player.inputVSSSearchResult.id,
                                with: .playerFailedToGetInfo(error: error,
                                                             deviceID: VSSID, url: descriptionInfoURL))
     
     player.playerState = priorState ///``Go back to the same state after alerting...
     
     ///``VSS Video Mode Snapshot Load Failed...``
     
    case let (priorState as Streaming<P>, .liveviewModeLoadFailed(error: error, date: date)):
     
     debugPrint("""
                <<< ******* STREAMING STATE ERROR - VSS Video Mode Snapshot Load Failed ********* >>>:
                Не удалось загрузить текущий снимок СВН ID [\(VSSID)]
                в момент запроса - [\(date)] во время живого просмотра кадрами!
                Загрузка снимка отменена последней операцией плеера!
                REQUEST URL: [\(player.currentPhotoShotURL?.absoluteString ?? "N/A")]
                PLAYER ERROR: [\(error)>]
                <<< ***************************************************************************** >>>
                """)
     
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
                                                          deviceID: VSSID,
                                                          url: player.currentPhotoShotURL))
     
     player.playerState = priorState ///``Go back to the same state after alerting...``
                                     
     
    case let (priorState as PlayingArchive<P>, .liveviewModeLoadFailed(error: error, date: date)):
     
     debugPrint("""
                [- ARCHIVE STATE ERROR -] LIVE MODE Fetch Snapshot Image Error:
                Не удалось загрузить снимок СВН ID [\(VSSID)] за \(date) во время живой трансляции!
                Загрузка снимка отменена последней операцией плеера!
                REQUEST URL: [\(player.currentPhotoShotURL?.absoluteString ?? "N/A")]
                PLAYER ERROR: [\(error)>]
                """)
     
     alert("""
           Не удалось загрузить снимок за \(date) во время живой трансляции!
           Загрузка снимка отменена последней операцией плеера!
           """)
     
     player.playerState = priorState ///``Go back to the same state after alerting...
     
     
    case let (priorState as PlayingArchive<P>, .archiveShotsPrefetchFailed(error: error, depth: depth, url: url)):
   
     guard priorState.viewMode else {
      player.playerState = priorState ///``Go back to the same state without alerting...``
                                  
      break
     }
     
     debugPrint("""
                [- ARCHIVE STATE ERROR -] VIEW MODE Snapshot Fetch Failed at <\(depth)>:
                Не удалось загрузить текущий снимок СВН ID [\(VSSID)] в режиме архивного просмотра кадрами!
                REQUEST URL: [\(player.currentPhotoShotURL?.absoluteString ?? "N/A")]
                PLAYER ERROR: [\(error)>]
                """)
     
     alert("Не удалось загрузить текущий снимок СВН ID [\(VSSID)]в режиме архивного просмотра кадрами!")
     
     player.playerStateDelegate? ///``PlayerDelegate.playerFailedToPlay(4)``
      .playerDidFailedWithError(deviceID: player.inputVSSSearchResult.id,
                                with: .playerFailedToPlay(error: error,
                                                          deviceID: player.inputVSSSearchResult.id,
                                                          url: url))
     
     player.playerState = priorState ///``Go back to the same state after alerting...``
                                     
                          
    case let (priorState as Connected<P>, .archiveShotsPrefetchFailed(error: error, depth: depth, url: url)):
     
     debugPrint("""
                [- CONNECTED STATE ERROR -] Prefetch Image Error:
                Не удалось загрузить архивный снимок с глубиной: [\(depth)]
                во время подключения вещания с данной СВН!
                Подключение вещания данной СВН будет продолжено!
                <\(error)> from URL: \(url as Any)
                """)
     
     alert("""
           Не удалось загрузить архивный снимок с глубиной: [\(depth)] во время подключения вещания с данной СВН!
           Подключение вещания данной СВН будет продолжено!
           """)
     
     player.playerState = priorState ///``Go back to the same state after alerting...
                                     
     
    case let (priorState as Paused<P>, .liveviewModeLoadFailed(error: error, date: date)):
     
     debugPrint("""
                [- PAUSED STATE ERROR -] Live Fetch Snapshot Image Error:
                Не удалось загрузить снимок за \(date) во время живой трансляции!
                Загрузка снимка отменена последней операцией плеера!
                <\(error)>
                """)
     
     alert("""
           Не удалось загрузить снимок за \(date) во время живой трансляции!
           Загрузка снимка отменена последней операцией плеера!
           """)
     
     player.playerState = priorState ///``Go back to the same state after alerting...
                                    
     
     
     
    case let (priorState as Paused<P>, .archiveShotsPrefetchFailed(error: error, depth: depth, url: url)):
     
     debugPrint("""
                [- PAUSED STATE ERROR -] Fetch Archive Image Error:
                Не удалось загрузить архивный снимок с глубиной \(depth)!
                Загрузка архивного снимка отменена последней операцией плеера!
                <\(error)> from URL: \(url as Any)
                """)
     
     alert("""
           Не удалось загрузить архивный снимок с глубиной \(depth)!
           Загрузка архивного снимка отменена последней операцией плеера!
           """)
     
     player.playerState = priorState ///``Go back to the same state after alerting...
                                     
                                   
    case let (priorState as Streaming<P>, .archiveShotsPrefetchFailed(error: error, depth: depth, url: url)):
     
     debugPrint("""
                [- STREAMING STATE ERROR -] Fetch Archive Image Error:
                Не удалось загрузить архивный снимок с глубиной \(depth)!
                Загрузка архивного снимка отменена последней операцией плеера!
                <\(error)> from URL: \(url as Any)
                """)
     
     alert("""
           Не удалось загрузить архивный снимок с глубиной \(depth)!
           Загрузка архивного снимка отменена последней операцией плеера!
           """)
     
     player.playerState = priorState ///``Go back to the same state after alerting...
                                  
                                   
    case let (state as Streaming<P>,  .playerContextFailed(error: error)) :
     
     debugPrint("""
                [- STREAMING STATE ERROR -] Player AVPlayer Context Error:
                Вещание с данного ресурса СВН временно не доступно!
                Запрос будет отправлен повторно на сервер!
                Количество попыток ограничено!
                <\(error)>
                """)
     
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
     
     debugPrint("""
                [- STREAMING STATE ERROR -] Player AVPlayer Context Error:
                Вещание полученного ресурса СВН не возможно!
                Количество попыток подключения исчерпано!
                Плеер будет остановлен.
                <\(error)>
                """)
     
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
     
     let depthSeconds = state.depthSeconds - player.archiveTimeStepSeconds
     
     debugPrint("""
               [- ARCHIVE STATE ERROR -] Player AVPlayer Archive Context Error:
               Не возможно воспроизвести запись из архива c глубиной [ -\(state.depthSeconds) сек. ]
               Будет воспроизведена следующая запись с глубиной [ -\(depthSeconds) cек. ]
               <\(error)>
               """)
     
     
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
                                         depthSeconds      : depthSeconds ,
                                         liveStreamURL     : state.liveStreamURL,
                                         viewMode          : state.viewMode,
                                         viewModeInterval  : state.viewModeInterval)
     
    case let (priorState as Connected<P> , .archiveRequestFailed(error: error)) :
     
     debugPrint("""
                [- CONNECTED STATE ERROR -] Archive Controls Preload Failed:
                Не возможно загрузить архивные данные СВН ID [\(VSSID)],
                во время подключения. Вещание будет продолжено в живом режиме!
                Архивные записи будут не доступны!
                REQUEST URL: [\(archiveControlsURL?.absoluteString ?? "N/A")]
                PLAYER ERROR: [\(error)>]
                """)
     
     alert("""
           Не возможно загрузить архивные данные СВН ID [\(VSSID)] во время подключения.
           Вещание будет продолжено в живом режиме!
           Архивные записи будут не доступны!
           """)
     
     player.playerStateDelegate? /// ``PlayerDelegate.playerFailedToGetInfo(3)``
      .playerDidFailedWithError(deviceID: player.inputVSSSearchResult.id,
                                with: .playerFailedToGetInfo(error: error,
                                                             deviceID: player.inputVSSSearchResult.id,
                                                             url: player.deviceConnectionRequest?.requestURL))
     
     
     player.playerState = priorState ///``Go back to the same state after alerting...
                                    
    case let (priorState as Streaming<P> , .archiveRequestFailed(error: error)) :
    
     
     debugPrint("""
                [- STREAMING STATE ERROR -] Archive Controls Preload Failed:
                Не возможно загрузить архивные данные СВН ID [\(VSSID)],
                во время подключения. Вещание будет продолжено в живом режиме!
                Архивные записи будут не доступны!
                REQUEST URL: [\(archiveControlsURL?.absoluteString ?? "N/A")]
                PLAYER ERROR: [\(error)>]
                """)
     
     alert("""
           Не возможно загрузить архивные данные СВН ID [\(VSSID)] во время подключения.
           Вещание будет продолжено в живом режиме!
           Архивные записи будут не доступны!
           """)
     
     player.playerState = priorState ///``Go back to the same state after alerting...
                                     
    case let (state as Streaming<P>,  _ ) :
     debugPrint("""
                Внутренняя ошибка плеера при трансляции живого потока!
                Остановка плеера...
                PLAYER ERROR: [\(error)>]
                """)
     
     alert("Внутренняя ошибка плеера при трансляции живого потока!\nОстановка плеера...")
     state.stopViewMode()
     
     player.playerState = Stopped(player: player)
     
    case let (state as PlayingArchive<P>,  _ ) :
     
     debugPrint("""
                Внутренняя ошибка плеера при трансляции живого потока!
                Остановка плеера...
                PLAYER ERROR: [\(error)>]
                """)
     
     alert("Внутренняя ошибка плеера при трансляции видео из архива!\nОстановка плеера...")
     state.stopViewMode()
     player.playerState = Stopped(player: player)
     
     
     
    case (_, .stateError(error: let error)):
     debugPrint("Player State Transition Error:\n<\(error)>")
     
    case (_, .noLastEnteredBackground):
     debugPrint("Last entered background time stamp missing: <\(error)>")
     
    default:
     debugPrint("Undefined Failure State:\n \(error)")
     
     alert("Внутреняя ошибка состояния плеера!\nОстановка плеера...")
     
     player.playerStateDelegate?
      .playerWillChangeState(deviceID: player.inputVSSSearchResult.id, to: .stopped)
     
     player.playerState = Stopped(player: player)
   }
   
//   try updateKeepAliveState(to: .init(mode: .unchanged, state: .error, archive: nil))
   
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
