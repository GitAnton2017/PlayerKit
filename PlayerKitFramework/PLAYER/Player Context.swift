//
//  Player Context.swift
//  AreaSightDemo
//
//  Created by Anton V. Kalinin on 03.12.2022.
//  Copyright © 2022 Netris. All rights reserved.
//

import UIKit
import AVFoundation

internal protocol PlayerItemRepresentable {
 init(url URL: URL)
 ///Creates a player item with a specified URL.
 var canUseNetworkResourcesForLiveStreamingWhilePaused: Bool { get set }
 ///A Boolean value that indicates whether the player item can use network resources to keep the playback state up to date while paused.
 func currentTime() -> CMTime
 ///Returns the current time of the item.
}

internal protocol PlayerStatusRepresentable: Equatable {
 static var unknown: Self { get }
  ///A value that indicates a player hasn’t attempted to load media for playback.
 
 static var readyToPlay: Self { get }
 /// A value that indicates the player is ready to media.
  
 static var failed: Self { get }
 ///A value that indicates the player can no longer play media due to an error.
}

internal protocol ContextPlayer where Self: NSObject {
 ///*Controlling Playback
 @available(iOS 16.0, *) var defaultRate: Float { get set }
 ///A default rate at which to begin playback.
 func play()
 ///Begins playback of the current item.
 func pause()
 ///Pauses playback of the current item.
 var rate: Float { get set }
 ///The current playback rate.
 
 var volume: Float { get set }
 ///The audio playback volume for the player.
 var isMuted: Bool { get set }
  ///A Boolean value that indicates whether the audio output of the player is muted.
 
 ///*Managing the Player Item
  var currentItem: PlayerItem? { get }
 ///The item for which the player is currently controlling playback.
  func replaceCurrentItem(with item: PlayerItem?)
  ///Replaces the current item with a new item.
  ///
  ///
  
 ///*Creating a Player
 init(url: URL)
 ///Creates a new player to play a single audiovisual resource referenced by a given URL.
 init(playerItem: PlayerItem?)
 ///Creates a new player to play the specified player item.
 
 
 associatedtype PlayerItem: PlayerItemRepresentable
 associatedtype Status: PlayerStatusRepresentable
 
 var status: Status { get }
 //A value that indicates the readiness of a player object for playback.
  //enum AVPlayer.Status
  //Status values that indicate whether a player can successfully play media.
 var error: Error? { get }
  //An error that caused a failure.
 
 
}

internal protocol ContextPlayable where Self: AnyObject {
 
 associatedtype Player: ContextPlayer
 var player: Player? { get set }
 
}

extension AVPlayerItem: PlayerItemRepresentable {}

extension AVPlayer.Status: PlayerStatusRepresentable{}

extension AVPlayer: ContextPlayer {}

extension AVPlayerLayer: ContextPlayable {}



internal protocol NTXPlayerContext where Self: UIView {
 
 associatedtype PlayerLayer: ContextPlayable
 
 var player: PlayerLayer.Player { get set }
 
 //init(frame: CGRect)
 
 typealias StartHandlerType = (Result<Void, NTXPlayerContextError>) -> ()
 
 func startPlayback(from URL: URL,
                    useLiveStreamingWhilePaused: Bool,
                    retryCount: Int,
                    startHandler: @escaping StartHandlerType )
 
 
}

internal enum NTXPlayerContextError: Error  {
 case noPlayer
 case noMediaAsset
 case noMediaAssetItem
 case playerInternalError(error: Error)
 case unknown
 case undefinedState
}

internal extension NTXPlayerContext  {
 
 var playerLayer: PlayerLayer { layer as! PlayerLayer }
 
 var isReadyToPlay: Bool { player.status == .readyToPlay }
 
 var rate: Float {
  get { player.rate }
  set { player.rate = newValue }
 }
 
 var isMuted: Bool {
  get { player.isMuted  }
  set { player.isMuted = newValue }
 }
 
 func toggleMuted() { player.isMuted.toggle() }
 
 func togglePlay() { if isPlaying { pause() } else { play() } }
 
 var isPlaying: Bool { player.rate > 0.0 }
 
 var mediaAssetItem: PlayerLayer.Player.PlayerItem? {
  get { player.currentItem }
  set { player.replaceCurrentItem(with: newValue)}
 }
 
 
 func play() {
  debugPrint(#function)
  if isPlaying { return }
  player.play()
 }
 
 ///PAUSE:  Set player context to paused state 
 func pause() {
  debugPrint(#function)
  guard isPlaying else { return }
  player.pause()
 }

}

internal final class AVPlayerLayerView: UIView, NTXPlayerContext {
 
 internal lazy var player = { () -> AVPlayer in
  let player = AVPlayer()
  playerLayer.videoGravity = .resizeAspect
  playerLayer.player = player
  return player
 }()
 
 func getVideoAspectRatio(asset: AVURLAsset, vtrack: AVAssetTrack) {
  print ("***** Video natural Size is: \(vtrack.naturalSize)")
 }
 
 func getAssetTracks(asset: AVURLAsset) {
  let vtrack = asset.tracks(withMediaType: .video).first!
  let ratio = #keyPath(AVAssetTrack.naturalSize)
  vtrack.loadValuesAsynchronously(forKeys: [ratio])
  {
   let status = asset.statusOfValue(forKey: ratio, error: nil)
   if (status == .loaded)
   {
    DispatchQueue.main.async
    {[unowned self] in
     self.getVideoAspectRatio(asset: asset, vtrack: vtrack)
    }
   }
  }
 }
 
 func loadAssetTracks(asset: AVURLAsset) {
  let track = #keyPath(AVURLAsset.tracks)
  asset.loadValuesAsynchronously(forKeys: [track])
  {
   let status = asset.statusOfValue(forKey: track, error: nil)
   if (status == .loaded)
   {
    DispatchQueue.main.async
    {[unowned self] in
     self.getAssetTracks(asset: asset)
    }
   }
  }
 }
 
 private var playerItemStatusKVOToken: NSKeyValueObservation?

 internal func startPlayback(from URL: URL,
                           useLiveStreamingWhilePaused: Bool = true,
                           retryCount: Int = .max,
                           startHandler: @escaping StartHandlerType) {
  
  debugPrint(#function, "Trials left: (\(retryCount))")
  
  pause()
  
  let newItem = PlayerLayer.Player.PlayerItem.init(url: URL)
  
  newItem.canUseNetworkResourcesForLiveStreamingWhilePaused = useLiveStreamingWhilePaused
  
  self.mediaAssetItem = newItem
  
  playerItemStatusKVOToken = newItem.observe(\.status, options: [.new]) { [ weak self ] playerItem , change  in
   
   //guard let state = change.newValue else { return }
   
   print ("PLAYER STATUS: ", change, playerItem.status)
   
   switch playerItem.status  {
    
    case .readyToPlay  :
     debugPrint("SUCCESS PLAYER READY TO PLAY:", #function)
     startHandler(.success(()))
     
    case .failed where retryCount > 0:
     debugPrint("FAILED TO PLAY TO RETRY:", #function)
     self?.startPlayback(from: URL, retryCount: retryCount - 1, startHandler: startHandler)
     
    case .failed where retryCount == 0:
     guard let error = playerItem.error else {
      debugPrint("FAILED TO PLAY FOR UNKNOWN REASON", #function)
      startHandler (.failure(.unknown))
      return
     }
     
     debugPrint("FAILED TO PLAY WITH PLAYER ITEM ERROR - \(error)", #function)
     startHandler(.failure(.playerInternalError(error: error)))
     
    default:
     break
     
   }
  }
  
  

  player.play()
 }
 

 
 internal static override var layerClass: AnyClass { PlayerLayer.self }
 internal typealias PlayerLayer = AVPlayerLayer
 
 
// internal init() {
//  super.init(frame: .zero)
// }
//
// required init?(coder: NSCoder) {
//  fatalError("init(coder:) has not been implemented")
// }
 
 
}


