//
//  Player Client Facade.swift
//  PlayerKitFramework
//
//  Created by Anton V. Kalinin on 16.12.2022.
//

import Foundation
import UIKit

public struct ECHDPlayerFacade {
 
 public let cameraID: Int
 
 let player: NTXMobileNativePlayer<AVPlayerLayerView, MDVRPlayerView, EchdConnectionManager>
 
 public init(cameraID: Int, ownerView: UIView, exitHandler: @escaping () -> () ) {
  
  self.cameraID = cameraID
  
  let inputVSS = EchdSearchCamera(data: [:])
  
  inputVSS.id = cameraID
  
  let manager = EchdConnectionManager.sharedInstance
  
  let configuration = NTXPlayerConfiguration(playerOwnerView: ownerView,
                                             inputVSS: inputVSS,
                                             connectionManager: manager)
  
  let playerKit = NTXDefaultPlayerKit(configuration: configuration, shutdownHandler: exitHandler)
  
  self.player = playerKit.makePlayer()
  
  try! player.start()
  
 
 }
 
 
}
