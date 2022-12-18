//
//  Player Client Facade.swift
//  PlayerKitFramework
//
//  Created by Anton V. Kalinin on 16.12.2022.
//

import Foundation
import UIKit


public final class NTXSingleCameraPlayer<Delegate: NTXVideoModuleDelegate> where Delegate.Device == Int {
 
 public let credentials: NTXCredentials
 
 public let device: Delegate.Device
 
 public let delegate: Delegate
 
 public let ownerView: UIView
 
 public let shutdownHandler: (Delegate.Device) -> ()
 
 internal lazy var player = playerKit.makePlayer()
 
 internal lazy var playerKit = NTXECHDPlayerKit<Delegate>(configuration   :  configuration,
                                                          shutdownHandler : shutdownHandler)
 
 internal lazy var manager = NTXECHDManager(credentials: credentials)
 
 internal lazy var configuration = NTXPlayerConfiguration(playerOwnerView: ownerView,
                                                 inputVSS: device,
                                                 connectionManager: manager)
 
 public init(device: Delegate.Device,
             credentials: NTXCredentials,
             ownerView: UIView,
             delegate: Delegate,
             shutdownHandler: @escaping (Delegate.Device) -> () ) {
  
  self.device = device
  self.delegate = delegate
  self.credentials = credentials
  self.ownerView = ownerView
  self.shutdownHandler = shutdownHandler
 
  
 }
 
 public func start() throws {
  player.playerStateDelegate = delegate
  try player.start()
 }
 
 
}
