//
//  Player Kit Protocol.swift
//  PlayerKitFramework
//
//  Created by Anton V. Kalinin on 16.12.2022.
//

import UIKit

 ///# PLAYER KIT (FACTORY) ABSTRACTION
 ///
 /// Allows to create any conctere kit that builds players with generic inputs:
 /// # - Player configuration - the generic struct that defines and delivers:
 ///  - The client owner view that will host the concrete built player UI - UIView
 ///  - The client input search result for a single camera (VSS) - the conformer of NTXVSSSearchResultContext.
 ///  - The client connections manager  to be provided for player - the conformer of NTXPlayerConnectionsManager.
 /// # - Player working layers builders that allows to define working contexts of player and customize it as needed.
 ///
 ///   - makePlayerContainer: Creates and customizes the main player container view that owns all the other players contexts.
 ///  - makePlayerMutedStateView: Creates and customizes the indicator that shows muted state of video play.
 ///  - makeAlertView: Creates and customizes the player alert view that informs about errors, warnings, state info.
 ///  - makePlayerControls: Creates and customizes the player set of controls. The controls may be positioned in different player content view groups.
 ///  - makePlayerContext:  Creates the main facility for live video & archive video playback. By default used UIView backed by AVPlayerLayer.
 ///  - makePlayerPreload:  Creates and customizes the player preload view with image snapshot from VSS.
 ///  - makeActivityIndicator:  Creates and customizes the player activity indicator. By default we use UIPlayerActivityIndicatorView.
 ///  - make360VRPlayerContext:  Creates the main facility for VR playback from supported VSS.
 ///  - makeTimeLine:    Created view to visualize the time line of arched videos.
 ///

internal protocol NTXPlayerAbstractKit
 where Self: NSObject,
       Player.Delegate.Device == Player.Manager.InputDevice {
 
 associatedtype Player: NTXMobileNativePlayerProtocol
 
 var playerConfiguration: NTXPlayerConfiguration<Player.Manager, Player.Delegate.Device>  { get }
 
 typealias GenericViewBuilder       =  () -> UIView
 typealias ImageViewBuilder         =  () -> UIImageView
 typealias AlertViewBuilder         =  () -> NTXPlayerAlertRepresentable
 typealias PlayerControlsBuilder    =  (Player) -> [ any NTXPlayerControl ]
 typealias ActivityIndicatorBuilder =  () -> NTXPlayerActivityIndicator
 typealias PlayerContextBuilder     =  () -> Player.PlayerContext
 typealias PlayerVRContextBuilder   =  () -> Player.PlayerVRContext
 typealias TimeLineBuilder          =  () -> NTXPlayerTimeLine
 
 var makePlayerContainer:           GenericViewBuilder                 { get }
 var makePlayerMutedStateView:      GenericViewBuilder                 { get }
 var makeAlertView:                 AlertViewBuilder                   { get }
 var makePlayerControls:            PlayerControlsBuilder              { get }
 var makePlayerContext:             PlayerContextBuilder               { get }
 var makePlayerPreload:             ImageViewBuilder                   { get }
 var makeActivityIndicator:         ActivityIndicatorBuilder           { get }
 var make360VRPlayerContext:        PlayerVRContextBuilder             { get }
 var makeTimeLine:                  TimeLineBuilder                    { get }
 var shutdownHandler:               (Player.Delegate.Device) -> ()     { get }
 
 init (configuration:               NTXPlayerConfiguration<Player.Manager, Player.Delegate.Device>,
       containerBuilder:            @escaping GenericViewBuilder,
       mutedViewBuilder:            @escaping GenericViewBuilder,
       alertViewBuilder:            @escaping AlertViewBuilder,
       controlsBuilder:             @escaping PlayerControlsBuilder,
       contextBuilder:              @escaping PlayerContextBuilder,
       preloadViewBuilder:          @escaping ImageViewBuilder,
       activityIndicatorBuilder:    @escaping ActivityIndicatorBuilder,
       VRViewBuilder:               @escaping PlayerVRContextBuilder,
       timeLineBuilder:             @escaping TimeLineBuilder,
       shutdownHandler:             @escaping (Player.Delegate.Device) -> ()  )
 
}

internal extension NTXPlayerAbstractKit {
 
 var playerOwnerView: UIView { playerConfiguration.playerOwnerView }
 
 func makePlayer() -> Player {
  
   //Player Container View frame observation for adaptive layout to be hosted by the Player itself.
  var adaptiveSizeTokens = Set<NSKeyValueObservation>()
  
   //Build Player Container UIView as a SuperView of all other player views & confined it to the onwned view.
  let playerContainerView = makePlayerContainer()
   .confined(to: playerOwnerView,
             applying: playerConfiguration.insetsFromPlayerOwner)
  
   //Build Player generic playing context view & make it confined to the player container view.
  let playerContextView = makePlayerContext()
   .confined(to: playerContainerView,
             applying: playerConfiguration.playerViewInsetsFromContainer)
  
  playerContextView.backgroundColor = .clear
  
   //Build Player generic playing VR context view & make it confined to the player container view.
  let playerVRContextView = make360VRPlayerContext()
   .confined(to: playerContainerView,
             applying: playerConfiguration.playerVRViewInsetsFromContainer)
  
  playerContextView.backgroundColor = .clear
   //Build Player UIImageView for static preload UIImage & make it confined to the player container view.
  let playerPreloadView = makePlayerPreload()
   .confined(to: playerContainerView,
             applying: playerConfiguration.preloadViewInsetsFromContainer)
  
  playerPreloadView.backgroundColor = .clear
  playerPreloadView.contentMode = .scaleAspectFit
  
  
   //Build Player Generic Activity Indicator View & make it confined to the player container view
   //with adaptive relative size depending upon the frame change of the player container view.
  let playerActivityView = makeActivityIndicator()
   .confined(centeredIn: playerContainerView,
             withAdaptiveRelativeSize: playerConfiguration.activityIndicatorRelativeSizeToContainer,
             changeFrameTokens: &adaptiveSizeTokens)
  
  playerPreloadView.backgroundColor = .clear
  
   //Build Player Muted State UIView & make it confined to the player container view
   //with adaptive relative size depending upon the frame change of the player container view.
  
  let playerMutedStateView = makePlayerMutedStateView()
   .confined(centeredIn: playerContainerView,
             withAdaptiveRelativeSize: playerConfiguration.mutedIndicatorRelativeSizeToContainer,
             changeFrameTokens: &adaptiveSizeTokens)
  
  
  playerMutedStateView.backgroundColor = .clear
  
   //Build Player Alert messages UIView & make it confined to the player container view
   //with adaptive relative size depending upon the frame change of the player container view.
  let playerAlertView = makeAlertView()
   .confined(hiddenOnTopCenterOf: playerContainerView,
             withAdaptiveRelativeHeight:  playerConfiguration.alertViewRelativeHeightToContainer,
             changeFrameTokens: &adaptiveSizeTokens)
  
   //Build Player set of generic control buttons & make it confined to the player container view
   //with adaptive relative size depending upon the frame change of the player container view.
  
  let playerTimeLine = makeTimeLine().confined(to: playerContainerView)
  
  playerTimeLine.backgroundColor = .clear
  
  PlayerTouchView(frame: .zero).confined(to: playerContainerView)
  
  let player = Player(playerOwnerView:         playerOwnerView,
                      playerContainerView:     playerContainerView,
                      playerPreloadView:       playerPreloadView,
                      inputVSSSearchResult:    playerConfiguration.inputVSS,
                      playerContext:           playerContextView,
                      playerVRContext:         playerVRContextView,
                      playerMutedStateView:    playerMutedStateView,
                      playerAlertView:         playerAlertView,
                      connectionsManager:      playerConfiguration.connectionManager,
                      playerActivityIndicator: playerActivityView,
                      timeLine:                playerTimeLine,
                      shutdownHandler:         shutdownHandler)
  
  _ = makePlayerControls(player)
   .map{$0.confined(groupType: $0.group,
                    of: playerContainerView,
                    realtiveSize: playerConfiguration.controlsRelativeSizeToContainer)}
  
  
  
   //Hosted by player itself.
  player.notificationsTokens.append(contentsOf: adaptiveSizeTokens.map {$0 as Any})
  
  
  return player
 }
 
}
