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
import Combine


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
/// - Player Delegate generic public class.
///


internal typealias NTXECHDPlayer<Delegate: NTXVideoPlayerDelegate>
 = NTXMobileNativePlayer<AVPlayerLayerView, MDVRPlayerView, NTXECHDManager, Delegate>
where Delegate.Device == Int 
  


internal final class NTXMobileNativePlayer<PlayerContext:   NTXPlayerContext,
                                           PlayerVRContext: NTXPlayerContext,
                                           Manager:         NTXPlayerConnectionsManager,
                                           Delegate:        NTXVideoPlayerDelegate>: NSObject,
                                                                                     NTXMobileNativePlayerProtocol
where Delegate.Device == Manager.InputDevice {


 internal var viewModeTimer: Timer? {
  didSet { oldValue?.invalidate() }
 }

 internal var archivePhotoShotsPrefetchRequests = [ AbstractRequest ]()
 internal var viewModeLivePhotoShotsRequests    = [ AbstractRequest ]()
 internal var viewModeArchivePhotoShotsRequests = [ AbstractRequest ]()
 
 internal var deviceConnectionRequest           :   AbstractRequest?
 internal var archiveControlsRequest            :   AbstractRequest?
 internal var livePhotoShotRequest              :   AbstractRequest?
 internal var securityMarkerRequest             :   AbstractRequest?
 internal var descriptionInfoRequest            :   AbstractRequest?

 internal lazy var  playerArchiveImagesCache = { () -> ArchiveImagesCache in
  let cache = ArchiveImagesCache()
  cache.delegate = self
  cache.interval = archiveTimeStepSeconds
  cache.prefetchSize = 200
  cache.defaultImageQuality = .low
  return cache
 }()
 
 internal weak var playerStateDelegate: Delegate?
 
 internal let  shutdownHandler: (Delegate.Device) -> ()

 
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
 
 internal var currentVSSDescription:  VSSShortDescription? {
  didSet {
   let hasAudio = currentVSSDescription?.hasAudio ?? false
   self[ .toggleMuting ]?.isUserInteractionEnabled = hasAudio
   self[ .toggleMuting ]?.alpha = hasAudio ? 1.0 : 0.5
   playerMutedStateView.isHidden = !hasAudio
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
 
 internal var notificationsTokens = [ Any ]() {
  didSet { debugPrint ("PLAYER - notificationsTokens", notificationsTokens) }
 }
 
 internal var playerState: any NTXPlayerState {
  get { stateIQ.sync  { __state__ } }
  set { stateIQ.sync  { __state__ = newValue  }}
 }
 
 private var __currentState__: VideoPlayerState = .loading
 
 internal var currentState: VideoPlayerState {
  get { stateIQ.sync  { __currentState__ } }
  set { stateIQ.sync  { __currentState__ = newValue  }}
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
 
 internal var isviewMode = false {
  didSet {
   if isviewMode {
    playerPreloadView.isHidden = true
   } else {
    playerPreloadView.isHidden = false
    admixtureView?.removeFromSuperview()
    admixtureView = nil
   }
  }
 }
 
 internal var viewModeInterval: TimeInterval = 1.0 {
  didSet {
   guard viewModeInterval != oldValue else { return }
   updateViewMode(viewModeInterval: viewModeInterval)
  }
 }
 
 internal var viewModePolling: Bool = true
 
 internal let transitionDurationOfContexts: CGFloat = 1.0
 
 internal let alertViewShowDelay: CGFloat = 2.0
 
 internal var currentTime: CMTime? { playerContext.player.currentItem?.currentTime() }
 
 internal unowned let playerContainerView: UIView
 
 internal unowned var playerOwnerView: UIView
 
 internal var inputVSSSearchResult: Manager.InputDevice
 
 internal unowned var playerContext: PlayerContext
 
 internal unowned var playerVRContext: PlayerVRContext
 
 internal unowned var playerPreloadView: UIImageView
 
 internal unowned var playerMutedStateView: UIView
 
 internal unowned var playerAlertView: NTXPlayerAlertRepresentable
 
 internal unowned let timeLine: NTXPlayerTimeLine
 
 internal unowned var connectionsManager: Manager
 
 internal unowned let playerActivityIndicator: NTXPlayerActivityIndicator
 
 var controlDebouceTimers = [NTXPlayerActions : Timer]()
 
 var controlsActivityTimer: Timer?
 
 var viewModeArchiveCurrentTimePoint: Int?
 
 var admixtureResizeToken: NSKeyValueObservation?
 
 internal init(playerOwnerView: UIView,
             playerContainerView: UIView,
             playerPreloadView: UIImageView,
             inputVSSSearchResult: Manager.InputDevice,
             playerContext: PlayerContext,
             playerVRContext: PlayerVRContext,
             playerMutedStateView: UIView,
             playerAlertView: NTXPlayerAlertRepresentable,
             connectionsManager: Manager,
             playerActivityIndicator: NTXPlayerActivityIndicator,
             timeLine: NTXPlayerTimeLine,
             shutdownHandler: @escaping (Delegate.Device) -> ()) {
  
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
  self.timeLine = timeLine
  self.shutdownHandler = shutdownHandler
  
  super.init()
  debugPrint ("@@@@@@@@@@@@@@@@@@@@@+++@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
  debugPrint ("<<<< ***** Player Initialized ***** >>>>", #function)
  debugPrint ("@@@@@@@@@@@@@@@@@@@@@+++@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
 }
 
 private let alertDispatcher = DispatchQueue(label: "Player.alertDispatcher")
 private let alertSemaphore = DispatchSemaphore(value: 1)
 
 private let duration: TimeInterval = 1.0
 private let removeDelay: TimeInterval = 2.0
 
 var playArchiveRecordEndToken: Any?
 
 
 lazy private var topConst: NSLayoutConstraint? = {
  let topConst = playerContainerView
   .constraints
   .first{
     $0.secondItem as? NSObject == self.playerAlertView &&
     $0.firstAttribute == .top && $0.secondAttribute == .top
   }
  
   topConst?.constant = 250
   playerContainerView.layoutIfNeeded()
   return topConst
 }()
 
 internal func showAlert(alert: NTXPlayerAlert){
  
  debugPrint (#function)
  

  alertDispatcher.async { [ weak alertView = playerAlertView,
                            weak containerView = playerContainerView,
                            sema = alertSemaphore,
                            weak topConst = topConst,
                            duration = transitionDurationOfContexts,
                            delay = removeDelay ] in
   sema.wait()
   DispatchQueue.main.async { [ weak alertView, weak topConst ] in

    alertView?.alert = alert
    topConst?.constant = 0.0
    
    UIView.animate(withDuration: duration, delay: 0.0, options: [.curveEaseInOut]) { [ weak containerView ] in
     containerView?.layoutIfNeeded()
    } completion: { [ weak topConst ] _ in
   
     topConst?.constant = 250
     
     UIView.animate(withDuration: duration, delay: delay, options: [.curveEaseInOut]) { [ weak containerView ] in
      containerView?.layoutIfNeeded()
      
     } completion: {  _ in sema.signal() }
    }
   }
  }
 }
 
 deinit {
  debugPrint( " <<<<<<< **** PLAYER CLASS IS DESTROYED **** >>>>>>")
  
  playerContainerView.removeFromSuperview()
  
  if #available(iOS 13.0, *) {
   notificationsTokens.compactMap{ $0 as? AnyCancellable }.forEach{ $0.cancel() }
   notificationsTokens.removeAll()
   (playArchiveRecordEndToken as? AnyCancellable)?.cancel()
   
  } else {
   notificationsTokens.forEach { NotificationCenter.default.removeObserver($0) }
   
   if let token = playArchiveRecordEndToken {
    NotificationCenter.default.removeObserver(token)
   }
  }
 }
  

}

