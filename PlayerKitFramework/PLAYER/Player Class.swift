//
//  Player Class.swift
//  AreaSightDemo
//
//  Created by Anton V. Kalinin on 03.12.2022.
//  Copyright © 2022 Netris. All rights reserved.
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
 
 
 var  shutdownHandler: () -> ()  { get }
 
 init(playerOwnerView:         UIView,
      playerContainerView:     UIView,
      playerPreloadView:       UIImageView,
      inputVSSSearchResult:    Manager.SearchResult, //Context for connecting with live streaming VSS.
      playerContext:           PlayerContext,
      playerVRContext:         PlayerVRContext,
      playerMutedStateView:    UIView,
      playerAlertView:         NTXPlayerAlertRepresentable,
      connectionsManager:      Manager,
      playerActivityIndicator: NTXPlayerActivityIndicator,
      //timeLine:                NTXPlayerTimeLine,
      shutdownHandler:         @escaping () -> () )
 
 
 var playerState:                         any NTXPlayerState { get set } ///PLAYER STATE OBJECTS!!
 
 var appBackgroundTimeLimitForPlayer:     TimeInterval       { get set }
 
 var lastTimeAppEnteredBackground:        Date?              { get set }
 
 var notificationsTokens:                 [ Any ]            { get set }
 
 var playerContainerView:                 UIView             { get }
 
 //var timeLine:                            NTXPlayerTimeLine  { get }
 
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
 
 var inputVSSSearchResult: Manager.SearchResult { get set }
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
 
 
}

internal extension NTXMobileNativePlayerProtocol {
 func start() throws  { try playerState.handle(priorState: nil) }
 
 
 var controlGroups: [ UIStackView ] {
  playerContainerView.subviews.compactMap{ $0 as? UIStackView }
 }
 
 var playerControls: [ any NTXPlayerControl ] {
  controlGroups.flatMap { $0.subviews }.compactMap{$0 as? (any NTXPlayerControl)}
 }
 
 subscript(_ action: NTXPlayerActions) -> (any NTXPlayerControl)?{
  playerControls.first{ $0.playerAction == action }
 }
 
 
 func toggleMuting() {
  
  debugPrint (#function, self)
  
  playerContext.toggleMuted()
  playerMutedStateView.isHidden.toggle()
  
 }
 
 
 func play()  {
  
  debugPrint (#function)
  
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
 

 func playArchiveBack() {
  
  debugPrint (#function, self)
  
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
  
  debugPrint (#function, self)
  
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
  playerState = NTXPlayerStates.Connecting(player: self, tryCount: NTXPlayerStates.maxVSSContextRequests)
 }
 
 
 func stop() {
  debugPrint (#function, self)
  playerState = NTXPlayerStates.Stopped(player: self)
 }
 
 
 func snapshot() {
  debugPrint (#function, self)
   //TODO: ---
 }
 
 func record() {
  debugPrint (#function, self)
  //TODO: ---
 }
 
 func showVR() {
  debugPrint (#function, self)
   //TODO: ---
 }
 

}

///# КОНКРЕТНАЯ РЕАЛИЗАЦИЯ ОБОБЩЕННОГО ПЛЕЕРА (NTXMobileNativePlayer).
///
///# Для работы плеера в клиентком приложени  необходимо реализовать и предоставить следующие копмоненты для раьоты плеера.
///
/// - PlayerContext   = AVPlayerLayerView - для данной реализации используем транспорт AVFoundation на основе AVPlayer,
/// AVPlayerLayer упакованный в конкретную реализацию AVPlayerLayerView. Клинтское приложение может использовать любой транспорт для
/// проигрывания стриминговых ресурсов реализовав протокол контекста проигрывания ресурсов - NTXPlayerContext
///
/// - PlayerVRContext = MDVRPlayerView - реализацию ВР леера предоставляет приложение - клиент на основе реализации
/// протокола NTXPlayerContext для специфики проигрывания ВР контента.
///
/// - Manager  = EchdConnectionManager - Менеджер сетевых подключенний оеализованный согласно протокола NTXPlayerConnectionsManager
/// со стороный клиена. Например в приложени  ВГ используем   EchdConnectionManager - ЕЦХД.
///

internal final class NTXMobileNativePlayer<PlayerContext: NTXPlayerContext,
                                         PlayerVRContext: NTXPlayerContext,
                                         Manager: NTXPlayerConnectionsManager>: NSObject, NTXMobileNativePlayerProtocol  {
 
 
 internal let  shutdownHandler: () -> ()
 
 internal var requests = [AbstractRequest]()
 
 internal var currentVSS: Manager.Device? {
  didSet {
   if let VSSURLString = currentVSS?.getLiveIosUrls()?.first {
    self.currentVSSStreamingURL = URL(string: VSSURLString )
   }
   
   if let shotURLString = currentVSS?.getLiveShotUrls()?.first {
    self.currentPhotoShotURL = URL(string: shotURLString )
   }
   
  }
 }
 
 internal var currentVSSArchiveControls: Manager.ArchiveControl?
 
 internal var currentPhotoShot: Manager.PhotoShot?
 
 private let playerIQ = DispatchQueue(label: "NTXMobileNativePlayer.Player.Isolation.Queue")
 
 private var __url__: URL?
 
 internal var currentVSSStreamingURL: URL? {
  get { playerIQ.sync  { __url__ } }
  set { playerIQ.async { [ weak self ] in self?.__url__ = newValue } }
 }
 
 private var __shot_url__: URL?
 
 internal var currentPhotoShotURL: URL? {
  get { playerIQ.sync  { __shot_url__ } }
  set { playerIQ.async { [ weak self ] in self?.__shot_url__ = newValue } }
 }
 
 internal var lastTimeAppEnteredBackground: Date?
 
 internal var appBackgroundTimeLimitForPlayer: TimeInterval = 30.0
 
 internal var archiveTimeStepSeconds: Int = 10
 
 private let stateIQ = DispatchQueue(label: "NTXMobileNativePlayer.State.Isolation.Queue")
 
 internal var notificationsTokens = [ Any ]()
 
 internal var playerState: any NTXPlayerState {
  get { stateIQ.sync  { __state__ } }
  set { stateIQ.sync  { __state__ = newValue  }}
 }
 
 private lazy var __state__: any NTXPlayerState = NTXPlayerStates.Initial(player: self) {
  didSet {
   
   DispatchQueue.main.async { [ weak self ] in
    
    guard let self = self else { return }
    
    do {
     try self.__state__.handle(priorState: oldValue)
    } catch let error as  NTXPlayerError {
     self.playerState = NTXPlayerStates.Failed(player: self, error: error)
    } catch let error as NTXPlayerStates.StateError {
     self.playerState = NTXPlayerStates.Failed(player: self, error: .stateError(error: error))
    } catch {
     print ("Catch all")
    }
   }
  }
 }
 
 internal var admixtureView: UIView?
 
 internal var isVideoMode = false {
  didSet {
   if isVideoMode {
    playerPreloadView.isHidden = true
   } else {
    playerPreloadView.isHidden = false
    admixtureView?.removeFromSuperview()
    admixtureView = nil
   }
  }
 }
 
 internal let transitionDurationOfContexts: CGFloat = 1.0
 
 internal let alertViewShowDelay: CGFloat = 2.0
 
 internal var currentTime: CMTime? { playerContext.player.currentItem?.currentTime() }
 
 internal unowned let playerContainerView: UIView
 
 internal unowned var playerOwnerView: UIView
 
 internal var inputVSSSearchResult: Manager.SearchResult
 
 internal unowned var playerContext: PlayerContext
 
 internal unowned var playerVRContext: PlayerVRContext
 
 internal unowned var playerPreloadView: UIImageView
 
 internal unowned var playerMutedStateView: UIView
 
 internal unowned var playerAlertView: NTXPlayerAlertRepresentable
 
 //internal unowned let timeLine: NTXPlayerTimeLine
 
 internal unowned var connectionsManager: Manager
 
 internal unowned let playerActivityIndicator: NTXPlayerActivityIndicator
 
 internal init(playerOwnerView: UIView,
             playerContainerView: UIView,
             playerPreloadView: UIImageView,
             inputVSSSearchResult: Manager.SearchResult,
             playerContext: PlayerContext,
             playerVRContext: PlayerVRContext,
             playerMutedStateView: UIView,
             playerAlertView: NTXPlayerAlertRepresentable,
             connectionsManager: Manager,
             playerActivityIndicator: NTXPlayerActivityIndicator,
             //timeLine: NTXPlayerTimeLine,
             shutdownHandler: @escaping () -> ()) {
  
  self.playerOwnerView = playerOwnerView
  self.playerContainerView = playerContainerView
  self.playerPreloadView = playerPreloadView
  self.inputVSSSearchResult = inputVSSSearchResult
  self.playerContext = playerContext
  self.playerVRContext = playerVRContext
  self.playerMutedStateView = playerMutedStateView
  self.playerAlertView = playerAlertView
  self.connectionsManager = connectionsManager
  self.playerActivityIndicator = playerActivityIndicator
  //self.timeLine = timeLine
  self.shutdownHandler = shutdownHandler
  
  super.init()
 
  
 }
 
 private let alertDispatcher = DispatchQueue(label: "Player.alertDispatcher")
 private let alertSemaphore = DispatchSemaphore(value: 1)
 private let duration: TimeInterval = 1.0
 private let removeDelay: TimeInterval = 2.0
 
 
 lazy private var topConst: NSLayoutConstraint? = {
  let topConst = playerContainerView
   .constraints
   .first{
     $0.secondItem as? NSObject == self.playerAlertView &&
     $0.firstAttribute == .top && $0.secondAttribute == .top
   }
  
   topConst?.constant = 150
   playerContainerView.layoutIfNeeded()
   return topConst
 }()
 
 internal func showAlert(alert: NTXPlayerAlert){
  
  debugPrint (#function)
  

  alertDispatcher.async { [ weak self ] in
   guard let self = self else { return }
   self.alertSemaphore.wait()
   DispatchQueue.main.async { [ weak self ] in
    guard let self = self else { return }
    guard let topConst = self.topConst else { return }
    self.playerAlertView.alert = alert
    topConst.constant = 0.0

    UIView.animate(withDuration: self.duration,
                   delay: 0.0,
                   options: [.curveEaseInOut, .allowUserInteraction]) { [ weak self ] in
     self?.playerContainerView.layoutIfNeeded()
    } completion: { [ weak self ] _ in
     guard let self = self else { return }
     topConst.constant = 150
     UIView.animate(withDuration: self.transitionDurationOfContexts,
                    delay: self.removeDelay,
                    options: [.curveEaseInOut, .allowUserInteraction]) { [ weak self ] in
      self?.playerContainerView.layoutIfNeeded()
      
     } completion: { [ weak self ] _ in
      guard let self = self else { return }
      self.alertSemaphore.signal()
     }
    }
   }
  }
 }
}

