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


internal typealias NTXECHDPlayer<Delegate: NTXVideoModuleDelegate>
 = NTXMobileNativePlayer<AVPlayerLayerView, MDVRPlayerView, NTXECHDManager, Delegate>
where Delegate.Device == Int 
  


internal final class NTXMobileNativePlayer<PlayerContext:   NTXPlayerContext,
                                           PlayerVRContext: NTXPlayerContext,
                                           Manager:         NTXPlayerConnectionsManager,
                                           Delegate:        NTXVideoModuleDelegate>: NSObject,
                                                                                     NTXMobileNativePlayerProtocol
 where Delegate.Device == Manager.InputDevice {
 
 
 internal weak var playerStateDelegate: Delegate?
 
 internal let  shutdownHandler: (Delegate.Device) -> ()
 
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

