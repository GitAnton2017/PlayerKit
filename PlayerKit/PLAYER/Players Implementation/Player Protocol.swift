//
//  Player Protocol.swift
//  PlayerKitFramework
//
//  Created by Anton2016 on 16.12.2022.
//

import Foundation
import UIKit
import AVFoundation

 // VSS - Visual Surveillance System | СВН - система видеонаблюдения

internal protocol NTXMobileNativePlayerProtocol where Self: NSObject {
 
 associatedtype PlayerContext:    NTXPlayerContext
  //The generic type that defines wrapper of audiovisual interface for playing streaming media asset.
  //Обобщенный тип определяющий обертку аудио и видео интерфеса для проигрывания стриминг ресурсов.
 
 associatedtype PlayerVRContext:  NTXPlayerContext
  //The generic type that difines wrapper of visual interface for 3D translation 360C VSS
  //Обобщенный тип определяющий обертку интерфеса для моделирования 3D трансляции СВН 360.
 
 associatedtype Manager:          NTXPlayerConnectionsManager
  //The generic type that provides interface for steraming data loading and connections to such resources.
 
 associatedtype Delegate:  NTXVideoModuleDelegate
 
 var  playerStateDelegate: Delegate? { get set }
 
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
 
 
 var playerState:                         any NTXPlayerState { get set } ///PLAYER STATE OBJECTS!!
 
 var appBackgroundTimeLimitForPlayer:     TimeInterval       { get set }
 
 var lastTimeAppEnteredBackground:        Date?              { get set }
 
 var notificationsTokens:                 [ Any ]            { get set }
 
 var playerContainerView:                 UIView             { get }
 
 var timeLine:                            NTXPlayerTimeLine  { get }
 
 var currentVSS:                          Manager.Device?    { get set }
 
 var currentVSSArchiveControls: Manager.ArchiveControl? { get set }
 
 var currentPhotoShot: Manager.PhotoShot? { get set }
 
 var currentVSSStreamingURL: URL? { get set }
  //Player current live streaming URL of VSS received by request in ConnectionsManager.
 
 var currentPhotoShotURL: URL? { get set }
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
 
 func showAlert(alert: NTXPlayerAlert)
 
 var requests: [AbstractRequest]  { get set }
 
 var playArchiveRecordEndToken: Any? { get set }
 
 var controlDebouceTimers: [NTXPlayerActions : Timer] { get set }
 
}



internal extension NTXMobileNativePlayerProtocol where Manager.InputDevice == Delegate.Device{
 func start() throws  {
  
  playerStateDelegate?
   .playerWillChangeState(deviceID: inputVSSSearchResult.id, to: .started)
  
  try playerState.handle(priorState: nil)
 }
 
 
 var controlGroups: [ UIStackView ] {
  playerContainerView.subviews.compactMap{ $0 as? UIStackView }
 }
 
 var playerControls: [ any NTXPlayerControl ] {
  controlGroups.flatMap { $0.subviews }.compactMap{$0 as? (any NTXPlayerControl)}
 }
 
 subscript(_ action: NTXPlayerActions) -> (any NTXPlayerControl)?{
  playerControls.first{ $0.playerAction == action }
 }
 
 
 var isMuted: Bool { playerContext.isMuted }
 
 func toggleMuting() {
  
  debugPrint (#function)
  
  playerContext.toggleMuted()
  playerMutedStateView.isHidden.toggle()
  
  playerStateDelegate?
   .playerMutedStateDidChange(deviceID: inputVSSSearchResult.id, muted: isMuted)
 }
 
 
 func play()  {
  
  debugPrint (#function)
  
  playerStateDelegate?
   .playerControlDidPressed(deviceID: inputVSSSearchResult.id, for: .play)
  
  playerStateDelegate?
   .playerWillChangeState(deviceID: inputVSSSearchResult.id, to: .playing)
  
  switch playerState {
   case let state as NTXPlayerStates.Paused<Self>:
    playerState = NTXPlayerStates.Streaming(player: self,
                                            streamURL: state.streamURL,
                                            tryRestartCount: 0,
                                            archiveDepth: state.archiveDepth)
    
   case let state as NTXPlayerStates.Streaming<Self>:
    playerState = NTXPlayerStates.Streaming(player: self,
                                            streamURL: state.streamURL,
                                            tryRestartCount: 0,
                                            archiveDepth: state.archiveDepth)
    
   case let state as NTXPlayerStates.PlayingArchive<Self>:
    playerState = NTXPlayerStates.Streaming(player: self,
                                            streamURL: state.liveStreamURL,
                                            tryRestartCount: 0,
                                            archiveDepth: state.depthSeconds)
   default: break
    
  }
  
 }
 
 func pause() {
  debugPrint (#function)
  
  playerStateDelegate?
   .playerControlDidPressed(deviceID: inputVSSSearchResult.id, for: .pause)
  
  playerStateDelegate?
   .playerWillChangeState(deviceID: inputVSSSearchResult.id, to: .paused)
  
  switch playerState {
   case let state as NTXPlayerStates.Streaming<Self>:
    playerState = NTXPlayerStates.Paused(player: self,
                                         streamURL: state.streamURL,
                                         archiveDepth: state.archiveDepth)
    
   case let state as NTXPlayerStates.PlayingArchive<Self>:
    playerState = NTXPlayerStates.Paused(player: self,
                                         streamURL: state.liveStreamURL,
                                         archiveDepth: state.depthSeconds)
    
   case let state as NTXPlayerStates.Paused<Self>:
    playerState = NTXPlayerStates.Paused(player: self,
                                         streamURL: state.streamURL,
                                         archiveDepth: state.archiveDepth)
   default: break
    
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
 
 func playArchiveBack() {
  
  debugPrint (#function)
  
  playerStateDelegate?
   .playerControlDidPressed(deviceID: inputVSSSearchResult.id, for: .playArchiveBack)
  
  playerStateDelegate?
   .playerWillChangeState(deviceID: inputVSSSearchResult.id, to: .playingArchiveBack)
  
  switch playerState {
    
   case let state as NTXPlayerStates.PlayingArchive<Self>:
    
    playerState = NTXPlayerStates.PlayingArchive(player: self,
                                                 depthSeconds: -archiveTimeStepSeconds + state.depthSeconds,
                                                 liveStreamURL: state.liveStreamURL)
    
    
   case let state as NTXPlayerStates.Paused<Self>:
    
    playerState = NTXPlayerStates.PlayingArchive(player: self,
                                                 depthSeconds: -archiveTimeStepSeconds + state.archiveDepth,
                                                 liveStreamURL: state.streamURL)
    
   case let state as NTXPlayerStates.Streaming<Self>:
    
    playerState = NTXPlayerStates.PlayingArchive(player: self,
                                                 depthSeconds: -archiveTimeStepSeconds + state.archiveDepth,
                                                 liveStreamURL: state.streamURL)
   default: break
  }
  
 }
 
 func playArchiveForward() {
  
  debugPrint (#function)
  
  playerStateDelegate?
   .playerControlDidPressed(deviceID: inputVSSSearchResult.id, for: .playArchiveForward)
  
  playerStateDelegate?
   .playerWillChangeState(deviceID: inputVSSSearchResult.id, to: .playingArchiveForward)
  
  switch playerState {
    
   case let state as NTXPlayerStates.PlayingArchive<Self>:
    
    playerState = NTXPlayerStates.PlayingArchive(player: self,
                                                 depthSeconds: +archiveTimeStepSeconds + state.depthSeconds,
                                                 liveStreamURL: state.liveStreamURL)
    
    
   case let state as NTXPlayerStates.Paused<Self>:
    
    playerState = NTXPlayerStates.PlayingArchive(player: self,
                                                 depthSeconds: +archiveTimeStepSeconds + state.archiveDepth,
                                                 liveStreamURL: state.streamURL)
    
   case let state as NTXPlayerStates.Streaming<Self>:
    
    playerState = NTXPlayerStates.PlayingArchive(player: self,
                                                 depthSeconds: +archiveTimeStepSeconds + state.archiveDepth,
                                                 liveStreamURL: state.streamURL)
   default: break
  }
 }
 
 func refresh() {
  debugPrint (#function)
  
  playerStateDelegate?
   .playerControlDidPressed(deviceID: inputVSSSearchResult.id, for: .refresh)
  
  playerStateDelegate?
   .playerWillChangeState(deviceID: inputVSSSearchResult.id, to: .connecting)
  
  playerState = NTXPlayerStates.Connecting(player: self, tryCount: NTXPlayerStates.maxVSSContextRequests)
 }
 
 
 func stop() {
  debugPrint (#function)
  
  playerStateDelegate?
   .playerControlDidPressed(deviceID: inputVSSSearchResult.id, for: .stop)
  
  playerStateDelegate?
   .playerWillChangeState(deviceID: inputVSSSearchResult.id, to: .stopped)
  
  playerState = NTXPlayerStates.Stopped(player: self)
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
