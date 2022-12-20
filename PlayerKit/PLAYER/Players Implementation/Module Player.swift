//
//  Player Client Facade.swift
//  PlayerKitFramework
//
//  Created by Anton V. Kalinin on 16.12.2022.
//

import Foundation
import UIKit

internal protocol PlayerAdapter: AnyObject {
 func start() throws
 var  playerState: VideoPlayerState { get }
 func play()         -> Bool
 func play(at: UInt) -> Bool
 func pause()        -> Bool
 func stop()         -> Bool
 func toggleMuted()  -> Bool
 var archiveDateInterval: [DateInterval] { get }
 var archiveDepthInterval: [(Int, Int)] { get }
 var ownerView: UIView  { get }
 var anyPlayer: any NTXMobileNativePlayerProtocol { get }
 
}

internal final class NTXPlayerAdapter<Delegate: NTXVideoModuleDelegate>: PlayerAdapter
where Delegate.Device == Int {
 
 
 var archiveDateInterval: [DateInterval] { [player.archiveDateInterval] }
 
 var archiveDepthInterval: [(Int, Int)] { [player.archiveDepthInterval] }
 
 var anyPlayer: any NTXMobileNativePlayerProtocol { player }
 
 internal func play(at timePoint: UInt) -> Bool  { player.playArchive(at: timePoint) }
 
 internal func pause() -> Bool { player.pause() }
 
 internal func stop() -> Bool  { player.stop(); return player.refresh() }
 
 internal func play() -> Bool { player.play() }
 
 internal func toggleMuted() -> Bool { player.toggleMuting() }
 
 internal var playerState: VideoPlayerState { player.currentState }
 
 internal let credentials: NTXCredentials
 
 internal let device: Delegate.Device
 
 internal let delegate: Delegate
 
 internal unowned let ownerView: UIView
 
 internal let shutdownHandler: (Delegate.Device) -> ()
 
 internal lazy var player = playerKit.makePlayer()
 
 internal lazy var playerKit = NTXECHDPlayerKit<Delegate>(configuration   :  configuration,
                                                          shutdownHandler : shutdownHandler)
 
 internal lazy var manager = NTXECHDManager(credentials: credentials)
 
 internal lazy var configuration = NTXPlayerConfiguration(playerOwnerView: ownerView,
                                                 inputVSS: device,
                                                 connectionManager: manager)
 
 internal init(device: Delegate.Device,
             credentials: NTXCredentials,
             ownerView: UIView,
             delegate: Delegate,
             shutdownHandler: @escaping (Delegate.Device) -> ()) {
  
  self.device = device
  self.delegate = delegate
  self.credentials = credentials
  self.ownerView = ownerView
  self.shutdownHandler = shutdownHandler
 
  
 }
 
 internal func start() throws {
  player.playerStateDelegate = delegate
  try player.start()
 }
 
 deinit {
  
  debugPrint(String(describing: Self.self), " IS DESTROYED SUCCESSFULLY!")
 }
 
}
