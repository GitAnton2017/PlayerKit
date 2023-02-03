//
//  Player Protocol.swift
//  PlayerKitFramework
//
//  Created by Anton V. Kalinin on 16.12.2022.
//

import Foundation
import UIKit
import AVFoundation

 // VSS - Visual Surveillance System | СВН - система видеонаблюдения

internal protocol NTXMobileNativePlayerProtocol : ArchiveImagesCacheDelegate where Self: NSObject {
 
 associatedtype PlayerContext:    NTXPlayerContext
  //The generic type that defines wrapper of audiovisual interface for playing streaming media asset.
  //Обобщенный тип определяющий обертку аудио и видео интерфеса для проигрывания стриминг ресурсов.
 
 associatedtype PlayerVRContext:  NTXPlayerContext
  //The generic type that difines wrapper of visual interface for 3D translation 360C VSS
  //Обобщенный тип определяющий обертку интерфеса для моделирования 3D трансляции СВН 360.
 
 associatedtype Manager:          NTXPlayerConnectionsManager
  //The generic type that provides interface for steraming data loading and connections to such resources.
 
 associatedtype Delegate:  NTXVideoPlayerDelegate
 
 var  playerStateDelegate: Delegate? { get set }
 
 var  playerArchiveImagesCache: ArchiveImagesCache { get set }
 
 var  shutdownHandler: (Delegate.Device) -> ()  { get }
 
 init(playerOwnerView:         UIView,
      playerContainerView:     UIView,
      playerPreloadView:       UIImageView,
      inputVSSSearchResult:    Manager.InputDevice, //Context for connecting with live streaming VSS.
      playerContext:           PlayerContext,
      playerVRContext:         PlayerVRContext,
      playerMutedStateView:    UIView,
      playerAlertView:         NTXPlayerAlertRepresentable,
      connectionsManager:      Manager,
      playerActivityIndicator: NTXPlayerActivityIndicator,
      timeLine:                NTXPlayerTimeLine,
      shutdownHandler:         @escaping (Delegate.Device) -> () )
 
 
 var currentState:                    VideoPlayerStateEnum   { get set } /// External state for public interface
                                                                         
 var playerState:                         any NTXPlayerState { get set } /// PLAYER STATE OBJECTS!!
 
 var appBackgroundTimeLimitForPlayer:     TimeInterval       { get set }
 
 var lastTimeAppEnteredBackground:        Date?              { get set }
 
 var notificationsTokens:                 [ Any ]            { get set }
 
 var playerContainerView:                 UIView             { get     }
 
 var timeLine:                            NTXPlayerTimeLine  { get     }
 
 var currentVSS:                          Manager.Device?    { get set }
 
 var currentVSSDescription:               VSSShortDescription? { get set }
 
 var currentVSSArchiveControls: Manager.ArchiveControl?      { get set }
 
 var currentPhotoShot: Manager.PhotoShot?                    { get set }
 
 var currentVSSStreamingURL: URL?                            { get set }
  //Player current live streaming URL of VSS received by request in ConnectionsManager.
 
 var currentPhotoShotURL: URL?                               { get set }
  //Player current photo shot image data URl
 
 var playerOwnerView: UIView { get set }
  //Player Owner (Client) View. The View to which the player instance is attached as a subview.
  //May be modified and player can change the hosting view provided by client.
 
 var inputVSSSearchResult: Manager.InputDevice { get set }
  // The generic type that defines context as a result of VSS preliminary search by the client.
  // This input value may be changed by the client which will reload the player state.
 
 var playerContext: PlayerContext { get }
  // The generic type that defines the player context for streaming media playback.
  // The default type is the UIView subclass with backing layer class set to AVPlayerLayer
  // The default player is AVPlayer
 
 var playerVRContext: PlayerVRContext { get }
 
 var playerActivityIndicator: NTXPlayerActivityIndicator { get }
 
 var playerMutedStateView: UIView { get }
 
 var playerAlertView: NTXPlayerAlertRepresentable { get }
 
 var alertViewShowDelay: CGFloat { get }
 
 var playerPreloadView: UIImageView { get }
 
 var connectionsManager: Manager { get }
 
 var transitionDurationOfContexts: CGFloat { get }
 
 var archiveTimeStepSeconds: Int { get set }
 
 var viewModeInterval: TimeInterval { get set }
 
 var viewModePolling : Bool  { get set }
 
 var admixtureResizeToken: NSKeyValueObservation? { get set }
 
 var showsInternalControls : Bool  { get set }
 var showsInternalAlerts :   Bool  { get set }
 
 func showAlert(alert: NTXPlayerAlert)
 
 var archivePhotoShotsPrefetchRequests  :    [ URLSessionRequestRepresentable ]    { get set }
 var viewModeLivePhotoShotsRequests     :    [ URLSessionRequestRepresentable ]    { get set }
 var viewModeArchivePhotoShotsRequests  :    [ URLSessionRequestRepresentable ]    { get set }
 var deviceConnectionRequest            :      URLSessionRequestRepresentable?     { get set }
 var archiveControlsRequest             :      URLSessionRequestRepresentable?     { get set }
 var livePhotoShotRequest               :      URLSessionRequestRepresentable?     { get set }
 var securityMarkerRequest              :      URLSessionRequestRepresentable?     { get set }
 var descriptionInfoRequest             :      URLSessionRequestRepresentable?     { get set }
 
 var playArchiveRecordEndToken: Any? { get set }
 
 var controlDebouceTimers: [NTXPlayerActions : Timer] { get set }
 
 var viewModeTimer: Timer? { get set }
 
 var controlsActivityTimer: Timer? { get set }
 
 var viewModeArchiveCurrentTimePoint: Int? {  get set  }
}



internal extension NTXMobileNativePlayerProtocol where Manager.InputDevice == Delegate.Device{
 
 var startSeconds: Int { ( currentVSSArchiveControls? .start ?? 0 ) / 1000  }
 var endSeconds:   Int { ( currentVSSArchiveControls? .end   ?? 0 ) / 1000  }
 
 func fetchArchiveImage(depthSeconds: Int, handler: @escaping ( UIImage? ) -> () ) {
  
//  debugPrint(#function, depthSeconds)
  
  guard let deviceContext = currentVSS else { handler(nil); return }
  
  var request: URLSessionRequestRepresentable?
  request = connectionsManager.requestVSSArchiveShot(for:  deviceContext,
                                                     depth: depthSeconds){ [ weak request ] result in
   
   defer {
    DispatchQueue.main.async { [ weak self ] in
     self?.archivePhotoShotsPrefetchRequests.removeAll{ $0 === request }
    }
   }
   
   switch result {
    case let .success(imageData) : handler(imageData.uiImage)
    case  .failure(_ )           : handler(nil)
     
//     self.playerState = NTXPlayerStates.Failed(player: self,
//                                               error: .archiveShotsPrefetchFailed(error : error,
//                                                                                  depth : depthSeconds,
//                                                                                  url   : request?.requestURL))
   }
  }
  
  if let request = request {
   DispatchQueue.main.async { [ weak self ] in
    self?.archivePhotoShotsPrefetchRequests.append(request)
   }
  }
 }
 
 func start() throws  {
  
  playerStateDelegate?
   .playerWillChangeState(deviceID: inputVSSSearchResult.id, to: .loading)
  
  try playerState.handle(priorState: nil)
 }
 
 var isAudioAvailable: Bool { currentVSSDescription?.hasAudio ?? false }
 
 var isVRAvailable: Bool { currentVSSDescription?.isVR ?? false }
 
 var isMuted: Bool { playerContext.isMuted }
 
 @discardableResult func toggleMuting() -> Bool {
  
  debugPrint (#function)
  
  guard currentVSSDescription?.hasAudio ?? false else { return false }
  
  playerContext.toggleMuted()
  
  playerMutedStateView.isHidden.toggle()
  
  playerStateDelegate?.playerMutedStateDidChange(deviceID: inputVSSSearchResult.id, muted: isMuted)
  
  return true
 }
 
 @discardableResult func setPlayerMutedState(isMuted: Bool) -> Bool {
  
  debugPrint (#function)
  
  guard currentVSSDescription?.hasAudio ?? false else { return false }
  
  playerContext.isMuted = isMuted
  
  playerMutedStateView.isHidden = !isMuted
  
  playerStateDelegate?.playerMutedStateDidChange(deviceID: inputVSSSearchResult.id, muted: isMuted)
  
  return true
 }
 
 @discardableResult func play() -> Bool  {
  
  debugPrint (#function)
  
  playerStateDelegate?
   .playerControlDidPressed(deviceID: inputVSSSearchResult.id, for: .play)
  
  playerStateDelegate?
   .playerWillChangeState(deviceID: inputVSSSearchResult.id, to: .playing)
  
  switch playerState {
    
   case is NTXPlayerStates.Stopped<Self>: return refresh()
    
   case let state as NTXPlayerStates.Paused<Self>:
    
    let retryCount = state.viewMode ? NTXPlayerStates.maxVSSStreamingRequests : 0
    
    playerState = NTXPlayerStates.Streaming(player             : self,
                                            streamURL          : state.streamURL,
                                            tryRestartCount    : retryCount,
                                            archiveDepth       : state.archiveDepth,
                                            viewMode           : state.viewMode,
                                            viewModeInterval   : state.viewModeInterval)
    return true
    
   case let state as NTXPlayerStates.Streaming<Self>:
    
    let retryCount = state.viewMode ? NTXPlayerStates.maxVSSStreamingRequests : 0
    
    playerState = NTXPlayerStates.Streaming(player             : self,
                                            streamURL          : state.streamURL,
                                            tryRestartCount    : retryCount,
                                            archiveDepth       : state.archiveDepth,
                                            viewMode           : state.viewMode,
                                            viewModeInterval   : state.viewModeInterval)
    
    return true
    
   case let state as NTXPlayerStates.PlayingArchive<Self>:
    
    let retryCount = NTXPlayerStates.maxVSSStreamingRequests
    
    playerState = NTXPlayerStates.Streaming(player             : self,
                                            streamURL          : state.liveStreamURL,
                                            tryRestartCount    : retryCount,
                                            archiveDepth       : state.depthSeconds,
                                            viewMode           : state.viewMode,
                                            viewModeInterval   : state.viewModeInterval)
    return true
    
   default: return false
    
  }
  
  
 }
 
 @discardableResult func pause() -> Bool {
  debugPrint (#function)
  
  playerStateDelegate?
   .playerControlDidPressed(deviceID: inputVSSSearchResult.id, for: .pause)
  
  playerStateDelegate?
   .playerWillChangeState(deviceID: inputVSSSearchResult.id, to: .paused)
  
  switch playerState {
   case let state as NTXPlayerStates.Streaming<Self>:
    playerState = NTXPlayerStates.Paused(player             : self,
                                         streamURL          : state.streamURL,
                                         archiveDepth       : state.archiveDepth,
                                         viewMode           : state.viewMode,
                                         viewModeInterval   : state.viewModeInterval)
    
    return true
    
   case let state as NTXPlayerStates.PlayingArchive<Self>:
    playerState = NTXPlayerStates.Paused(player             : self,
                                         streamURL          : state.liveStreamURL,
                                         archiveDepth       : state.depthSeconds,
                                         viewMode           : state.viewMode,
                                         viewModeInterval   : state.viewModeInterval)
    
    return true
    
   case let state as NTXPlayerStates.Paused<Self>:
    playerState = NTXPlayerStates.Paused(player             : self,
                                         streamURL          : state.streamURL,
                                         archiveDepth       : state.archiveDepth,
                                         viewMode           : state.viewMode,
                                         viewModeInterval   : state.viewModeInterval)
    
    return true
    
   default: return false
    
  }
  
 }
 
 
 
 
 func setDebounceTimer(for action: NTXPlayerActions, handler: @escaping (Timer) -> ()) {
  
  let delta = 0.25
  removeDebounceTimer(for: action)
  guard let interval = self[action]?.debounceInterval, interval > 0 else { return }
  controlDebouceTimers[action] = Timer.scheduledTimer(withTimeInterval: interval * (1 + delta),
                                                      repeats: false,
                                                      block: handler)
 }
 
 func removeDebounceTimer(for action: NTXPlayerActions) {
  controlDebouceTimers[action]?.invalidate()
  controlDebouceTimers[action] = nil
  
 }
 
 var archiveDepthInterval: (start: Int, end: Int){
  let start = (currentVSSArchiveControls?.start ?? 0) / 1000
  let end   = (currentVSSArchiveControls?.end   ?? 0) / 1000
  
  return (start: start, end: end)
 }
 
 
 var archiveDateInterval: DateInterval{
  
  let startDate = Date(timeIntervalSince1970: TimeInterval(archiveDepthInterval.start))
  let endDate   = Date(timeIntervalSince1970: TimeInterval(archiveDepthInterval.end  ))
  
  return .init(start: startDate, end: endDate)
 }
 
 @discardableResult func playArchive(at timePoint: UInt) -> Bool {
  
  debugPrint (#function)
  
  guard let archiveContext = currentVSSArchiveControls else { return false }
  
  let startSec = (archiveContext.start ?? 0) / 1000
  let endSec   = (archiveContext.end   ?? 0) / 1000
  
  guard timePoint >= startSec && timePoint <= endSec else { return false }
  
  playArchive(with: Int(timePoint) - endSec)
  
  return true
  
 }
 
 @discardableResult func playArchive(with depthSeconds: Int) -> Bool {
  
  debugPrint (#function)
  
  guard depthSeconds <= 0 else {  return false }
  
  playerStateDelegate?
   .playerControlDidPressed(deviceID: inputVSSSearchResult.id, for: .playArchiveBack)
  
  playerStateDelegate?
   .playerWillChangeState(deviceID: inputVSSSearchResult.id, to: .playing)
  
  switch playerState {
    
   case let state as NTXPlayerStates.PlayingArchive<Self>:
    
    playerState = NTXPlayerStates.PlayingArchive(player             : self,
                                                 depthSeconds       : depthSeconds,
                                                 liveStreamURL      : state.liveStreamURL,
                                                 viewMode           : state.viewMode,
                                                 viewModeInterval   : state.viewModeInterval)
    
    return true
    
   case let state as NTXPlayerStates.Paused<Self>:
    
    playerState = NTXPlayerStates.PlayingArchive(player             : self,
                                                 depthSeconds       : depthSeconds,
                                                 liveStreamURL      : state.streamURL,
                                                 viewMode           : state.viewMode,
                                                 viewModeInterval   : state.viewModeInterval)
    
    return true
    
   case let state as NTXPlayerStates.Streaming<Self>:
    
    playerState = NTXPlayerStates.PlayingArchive(player             : self,
                                                 depthSeconds       : depthSeconds,
                                                 liveStreamURL      : state.streamURL,
                                                 viewMode           : state.viewMode,
                                                 viewModeInterval   : state.viewModeInterval)
    return true
    
   default: return false
  }
 }
 
 func playArchiveBack() {
  
  debugPrint (#function)
  
  playerStateDelegate?
   .playerControlDidPressed(deviceID: inputVSSSearchResult.id, for: .playArchiveBack)
  
  playerStateDelegate?
   .playerWillChangeState(deviceID: inputVSSSearchResult.id, to: .playing)
  
  switch playerState {
    
   case let state as NTXPlayerStates.PlayingArchive<Self>:
    
    playerState = NTXPlayerStates.PlayingArchive(player            : self,
                                                 depthSeconds      : -archiveTimeStepSeconds + state.depthSeconds,
                                                 liveStreamURL     : state.liveStreamURL,
                                                 viewMode          : state.viewMode,
                                                 viewModeInterval  : state.viewModeInterval)
    
    
   case let state as NTXPlayerStates.Paused<Self>:
    
    playerState = NTXPlayerStates.PlayingArchive(player            : self,
                                                 depthSeconds      : -archiveTimeStepSeconds + state.archiveDepth,
                                                 liveStreamURL     : state.streamURL,
                                                 viewMode          : state.viewMode,
                                                 viewModeInterval  : state.viewModeInterval)
    
   case let state as NTXPlayerStates.Streaming<Self>:
    
    playerState = NTXPlayerStates.PlayingArchive(player            : self,
                                                 depthSeconds      : -archiveTimeStepSeconds + state.archiveDepth,
                                                 liveStreamURL     : state.streamURL,
                                                 viewMode          : state.viewMode,
                                                 viewModeInterval  : state.viewModeInterval)
   default: break
  }
  
 }
 
 func playArchiveForward() {
  
  debugPrint (#function)
  
  playerStateDelegate?
   .playerControlDidPressed(deviceID: inputVSSSearchResult.id, for: .playArchiveForward)
  
  playerStateDelegate?
   .playerWillChangeState(deviceID: inputVSSSearchResult.id, to: .playing)
  
  switch playerState {
    
   case let state as NTXPlayerStates.PlayingArchive<Self>:
    
    playerState = NTXPlayerStates.PlayingArchive(player            : self,
                                                 depthSeconds      : +archiveTimeStepSeconds + state.depthSeconds,
                                                 liveStreamURL     : state.liveStreamURL,
                                                 viewMode          : state.viewMode,
                                                 viewModeInterval  : state.viewModeInterval)
    
    
   case let state as NTXPlayerStates.Paused<Self>:
    
    playerState = NTXPlayerStates.PlayingArchive(player            : self,
                                                 depthSeconds      : +archiveTimeStepSeconds + state.archiveDepth,
                                                 liveStreamURL     : state.streamURL,
                                                 viewMode          : state.viewMode,
                                                 viewModeInterval  : state.viewModeInterval)
    
   case let state as NTXPlayerStates.Streaming<Self>:
    
    playerState = NTXPlayerStates.PlayingArchive(player            : self,
                                                 depthSeconds      : +archiveTimeStepSeconds + state.archiveDepth,
                                                 liveStreamURL     : state.streamURL,
                                                 viewMode          : state.viewMode,
                                                 viewModeInterval  : state.viewModeInterval)
   default: break
    
  }
 }
 
 @discardableResult func refresh() -> Bool {
  
  debugPrint (#function)
  
  playerStateDelegate?
   .playerControlDidPressed(deviceID: inputVSSSearchResult.id, for: .refresh)
  
  playerStateDelegate?
   .playerWillChangeState(deviceID: inputVSSSearchResult.id, to: .loading)
  
  playerState = NTXPlayerStates.Connecting(player: self, tryCount: NTXPlayerStates.maxVSSContextRequests)
  
  return true
 }
 
 
 @discardableResult func stop() -> Bool {
  
  debugPrint (#function)
  
  playerStateDelegate?
   .playerControlDidPressed(deviceID: inputVSSSearchResult.id, for: .stop)
  
  playerStateDelegate?
   .playerWillChangeState(deviceID: inputVSSSearchResult.id, to: .stopped)
  
  playerState = NTXPlayerStates.Stopped(player: self)
  
  return true
 }
 
  ///#Updates currect video mode interval of periodic photo shot requests being sent to server.
 @discardableResult func updateViewMode(viewModeInterval: TimeInterval) -> Bool {
  
  debugPrint(#function)
  
  switch playerState {
   case let state as NTXPlayerStates.Streaming<Self>:
    
    playerState = NTXPlayerStates.Streaming(player                 :  self,
                                            streamURL              :  state.streamURL,
                                            tryRestartCount        :  0, //no restart in this state!
                                            archiveDepth           :  state.archiveDepth,
                                            viewMode               :  state.viewMode,
                                            viewModeInterval       :  viewModeInterval)
    return true
    
   case let state as NTXPlayerStates.Paused<Self>:
    playerState = NTXPlayerStates.Paused(player                    :  self,
                                         streamURL                 :  state.streamURL,
                                         archiveDepth              :  state.archiveDepth,
                                         viewMode                  :  state.viewMode,
                                         viewModeInterval          :  viewModeInterval)
    return true
    
   case let state as NTXPlayerStates.PlayingArchive<Self>:
    
    playerState = NTXPlayerStates.PlayingArchive(player            :  self,
                                                 depthSeconds      :  state.depthSeconds,
                                                 liveStreamURL     :  state.liveStreamURL,
                                                 viewMode          :  state.viewMode,
                                                 viewModeInterval  :  viewModeInterval)
    return true
    
   default: return false
  }
 }
 
 @discardableResult func setViewMode(isActive: Bool) -> Bool {
  
  debugPrint(#function)
  
  self.viewModePolling = false
  
  viewModeTimer?.invalidate()
  
  switch playerState {
   case let state as NTXPlayerStates.Streaming<Self>:
    
    let retryCount = NTXPlayerStates.maxVSSStreamingRequests
    
    playerState = NTXPlayerStates.Streaming(player                 :  self,
                                            streamURL              :  state.streamURL,
                                            tryRestartCount        :  retryCount,
                                            archiveDepth           :  state.archiveDepth,
                                            viewMode               :  isActive,
                                            viewModeInterval       :  state.viewModeInterval)
    return true
    
   case let state as NTXPlayerStates.Paused<Self>:
    playerState = NTXPlayerStates.Paused(player                    :  self,
                                         streamURL                 :  state.streamURL,
                                         archiveDepth              :  state.archiveDepth,
                                         viewMode                  :  isActive, //toggle state!
                                         viewModeInterval          :  state.viewModeInterval)
    return true
    
   case let state as NTXPlayerStates.PlayingArchive<Self>:
    playerState = NTXPlayerStates.PlayingArchive(player            :  self,
                                                 depthSeconds      :  state.depthSeconds + archiveTimeStepSeconds,
                                                 liveStreamURL     :  state.liveStreamURL,
                                                 viewMode          :  isActive, //toggle state!
                                                 viewModeInterval  :  state.viewModeInterval)
    return true
    
   default: return false
  }
  
 }
 
  ///#Toggles Player View Mode using current view mode time interval.
 @discardableResult func toggleViewMode() -> Bool {
  
  debugPrint(#function)
  
  self.viewModePolling = true
  
  switch playerState {
   case let state as NTXPlayerStates.Streaming<Self>:
    
    let retryCount = state.viewMode ? NTXPlayerStates.maxVSSStreamingRequests : 0
    
    playerState = NTXPlayerStates.Streaming(player                 :  self,
                                            streamURL              :  state.streamURL,
                                            tryRestartCount        :  retryCount,
                                            archiveDepth           :  state.archiveDepth,
                                            viewMode               : !state.viewMode,
                                            viewModeInterval       :  state.viewModeInterval)
    return true
    
   case let state as NTXPlayerStates.Paused<Self>:
    playerState = NTXPlayerStates.Paused(player                    :  self,
                                         streamURL                 :  state.streamURL,
                                         archiveDepth              :  state.archiveDepth,
                                         viewMode                  : !state.viewMode, //toggle state!
                                         viewModeInterval          :  state.viewModeInterval)
    return true
    
   case let state as NTXPlayerStates.PlayingArchive<Self>:
    
   
    playerState = NTXPlayerStates.PlayingArchive(player            :  self,
                                                 depthSeconds      :  state.depthSeconds,
                                                 liveStreamURL     :  state.liveStreamURL,
                                                 viewMode          : !state.viewMode, //toggle state!
                                                 viewModeInterval  :  state.viewModeInterval)
    return true
    
   default: return false
  }
 }
 
 func snapshot() {
  
  debugPrint (#function)
  
  playerStateDelegate?
   .playerControlDidPressed(deviceID: inputVSSSearchResult.id, for: .snapshot)
  
   //TODO: ---
 }
 
 func record() {
  debugPrint (#function)
  
  playerStateDelegate?
   .playerControlDidPressed(deviceID: inputVSSSearchResult.id, for: .record)
  
   //TODO: ---
 }
 
 func showVR() {
  debugPrint (#function)
  
  playerStateDelegate?
   .playerControlDidPressed(deviceID: inputVSSSearchResult.id, for: .showVR)
  
   //TODO: ---
 }
}
 
extension NTXMobileNativePlayerProtocol {
 
 var controlGroups: [ UIStackView ] {
  playerContainerView.subviews.compactMap{ $0 as? UIStackView }
 }
 
 var playerControls: [ any NTXPlayerControl ] {
  controlGroups.flatMap { $0.subviews }.compactMap{$0 as? (any NTXPlayerControl)}
 }
 
 subscript(_ action: NTXPlayerActions) -> (any NTXPlayerControl)?{
  playerControls.first{ $0.playerAction == action }
 }
 
 
 
 func controlGroup(for position: NTXPlayerControlGroup) -> UIStackView?{
  controlGroups.first {
   $0.arrangedSubviews
    .compactMap{$0 as? (any NTXPlayerControl)}
    .first{$0.group == position} != nil
  }
 }
 
 var playerTouchView: PlayerTouchView? {
  playerContainerView.subviews.compactMap{$0 as? PlayerTouchView}.first
 }
 
 func animateControlsPanels(hidden: Bool,
                            position: NTXPlayerControlGroup = .bottomCentered,
                            duration: TimeInterval = 0.75,
                            //delay: TimeInterval = 5.0,
                            completion: ( () -> () )? = nil) ->  UIViewPropertyAnimator? {
  
  guard let group = controlGroup(for: position) else { return nil }
  
  let bounds = group.bounds
  
  let pa = UIViewPropertyAnimator(duration: duration, curve: .easeInOut){ [ weak group ] in
   guard let group = group else { return }
   
   switch position {
     
    case .topLeading, .topCentered, .topTrailing:
     group.transform = hidden ? .init(translationX: 0, y: -2 * bounds.height) : .identity
     
    case .bottomTrailing, .bottomCentered, .bottomLeading:
     group.transform = hidden ? .init(translationX: 0, y:  2 * bounds.height) : .identity
     
    case .trailingCentered:
     group.transform = hidden ? .init(translationX:  2 * bounds.width, y: 0) : .identity
     
    case .leadingCentered:
     group.transform = hidden ? .init(translationX: -2 * bounds.width, y: 0) : .identity
   }
  }
  
  pa.addCompletion{ _ in completion?() }
  
  return pa
  
//  DispatchQueue.main.asyncAfter(deadline: .now() + (hidden ? delay : 0)) {
//   pa.startAnimation()
//  }
  
  
  
 }
 
 
}


