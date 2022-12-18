//
//  Player VR Context.swift
//  AreaSightDemo
//
//  Created by Anton V. Kalinin on 03.12.2022.
//  Copyright © 2022 Netris. All rights reserved.
//

import UIKit
import AVFoundation

internal class MDVRPlayerView: UIView, NTXPlayerContext {
 
 internal lazy var player = { () -> AVPlayer in
  let player = AVPlayer()
  playerLayer.player = player
  return player
 }()
 
 internal func startPlayback(from URL: URL, useLiveStreamingWhilePaused: Bool, retryCount: Int, startHandler: @escaping StartHandlerType) {
  
 }
 
 
 internal static override var layerClass: AnyClass { PlayerLayer.self }
 internal typealias PlayerLayer = AVPlayerLayer
 
 
 
}
