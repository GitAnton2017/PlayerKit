//
//  NTXPlayerAbstractFactory.swift
//  AreaSightDemo
//
//  Created by Anton V. Kalinin on 02.12.2022.
//  Copyright © 2022 Netris. All rights reserved.
//

import UIKit

internal struct NTXPlayerConfiguration <Manager: NTXPlayerConnectionsManager> {
 
 internal let playerOwnerView:    UIView
 internal let inputVSS:           Manager.SearchResult
 internal let connectionManager:  Manager
 
 internal let insetsFromPlayerOwner:                        UIEdgeInsets
 internal let controlsRelativeSizeToContainer:              CGFloat
 internal let activityIndicatorRelativeSizeToContainer:     CGFloat
 internal let mutedIndicatorRelativeSizeToContainer:        CGFloat
 internal let alertViewRelativeHeightToContainer:           CGFloat
 internal let preloadViewInsetsFromContainer:               UIEdgeInsets
 internal let playerViewInsetsFromContainer:                UIEdgeInsets
 internal let playerVRViewInsetsFromContainer:              UIEdgeInsets
 
 internal init (playerOwnerView:                           UIView,
                inputVSS:                                  Manager.SearchResult,
                connectionManager:                         Manager,
                insetsFromPlayerOwner:                     UIEdgeInsets = .zero,
                controlsRelativeSizeToContainer:           CGFloat = 0.1,
                activityIndicatorRelativeSizeToContainer:  CGFloat = 0.1,
                mutedIndicatorRelativeSizeToContainer:     CGFloat = 0.1,
                alertViewRelativeHeightToContainer:        CGFloat = 0.15,
                preloadViewInsetsFromContainer:            UIEdgeInsets = .zero,
                playerViewInsetsFromContainer:             UIEdgeInsets = .zero,
                playerVRViewInsetsFromContainer:           UIEdgeInsets = .zero) {
  
  self.playerOwnerView                             = playerOwnerView
  self.inputVSS                                    = inputVSS
  self.connectionManager                           = connectionManager
  self.insetsFromPlayerOwner                       = insetsFromPlayerOwner
  self.controlsRelativeSizeToContainer             = controlsRelativeSizeToContainer
  self.activityIndicatorRelativeSizeToContainer    = activityIndicatorRelativeSizeToContainer
  self.mutedIndicatorRelativeSizeToContainer       = mutedIndicatorRelativeSizeToContainer
  self.alertViewRelativeHeightToContainer          = alertViewRelativeHeightToContainer
  self.preloadViewInsetsFromContainer              = preloadViewInsetsFromContainer
  self.playerViewInsetsFromContainer               = playerViewInsetsFromContainer
  self.playerVRViewInsetsFromContainer             = playerVRViewInsetsFromContainer
  
  
 }
 
 

}



///
///# PLAYER KIT (FACTORY) ABSTRACTION
/// Allows to create any conctere kit that builds players with generic inputs:
/// # - Player configuration - the generic struct that defines and delivers:
///  - The client owner view that will host the concrete built player UI - UIView
///  - The client input search result for a single camera (VSS) - the conformer of NTXVSSSearchResultContext.
///  - The client connections manager  to be provided for player - the conformer of NTXPlayerConnectionsManager.
/// # - Player working layers builders that allows to define working contexts of player and customize it as needed.
///  - makePlayerContainer: Creates and customizes the main player container view that owns all the other players contexts.
///  - makePlayerMutedStateView: Creates and customizes the indicator that shows muted state of video play.
///  - makeAlertView: Creates and customizes the player alert view that informs about errors, warnings, state info.
///  - makePlayerControls: Creates and customizes the player set of controls. The controls may be positioned in different player content view groups.
///  - makePlayerContext:  Creates the main facility for live video & archive video playback. By default used UIView backed by AVPlayerLayer.
///  - makePlayerPreload:  Creates and customizes the player preload view with image snapshot from VSS.
///  - makeActivityIndicator:  Creates and customizes the player activity indicator. By default we use UIPlayerActivityIndicatorView.
///  - make360VRPlayerContext:  Creates the main facility for VR playback from supported VSS.
///  - makeTimeLine:    Created view to visualize the time line of arched videos.
///

internal protocol NTXPlayerAbstractKit where Self: NSObject {

 associatedtype Player: NTXMobileNativePlayerProtocol
 
 var playerConfiguration: NTXPlayerConfiguration<Player.Manager>  { get }
 
 typealias GenericViewBuilder       =  () -> UIView
 typealias ImageViewBuilder         =  () -> UIImageView
 typealias AlertViewBuilder         =  () -> NTXPlayerAlertRepresentable
 typealias PlayerControlsBuilder    =  (Player) -> [ any NTXPlayerControl ]
 typealias ActivityIndicatorBuilder =  () -> NTXPlayerActivityIndicator
 typealias PlayerContextBuilder     =  () -> Player.PlayerContext
 typealias PlayerVRContextBuilder   =  () -> Player.PlayerVRContext
 //typealias TimeLineBuilder          =  () -> NTXPlayerTimeLine
 
 var makePlayerContainer:           GenericViewBuilder                 { get }
 var makePlayerMutedStateView:      GenericViewBuilder                 { get }
 var makeAlertView:                 AlertViewBuilder                   { get }
 var makePlayerControls:            PlayerControlsBuilder              { get }
 var makePlayerContext:             PlayerContextBuilder               { get }
 var makePlayerPreload:             ImageViewBuilder                   { get }
 var makeActivityIndicator:         ActivityIndicatorBuilder           { get }
 var make360VRPlayerContext:        PlayerVRContextBuilder             { get }
// var makeTimeLine:                  TimeLineBuilder                    { get }
 var shutdownHandler:               () -> ()                           { get }
 
 init (configuration:               NTXPlayerConfiguration<Player.Manager>,
       containerBuilder:            @escaping GenericViewBuilder,
       mutedViewBuilder:            @escaping GenericViewBuilder,
       alertViewBuilder:            @escaping AlertViewBuilder,
       controlsBuilder:             @escaping PlayerControlsBuilder,
       contextBuilder:              @escaping PlayerContextBuilder,
       preloadViewBuilder:          @escaping ImageViewBuilder,
       activityIndicatorBuilder:    @escaping ActivityIndicatorBuilder,
       VRViewBuilder:               @escaping PlayerVRContextBuilder,
      // timeLineBuilder:             @escaping TimeLineBuilder,
       shutdownHandler:             @escaping () -> ()  )
 
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
  
  playerContainerView.backgroundColor = .clear
  
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
   .confined(toTopRightOf: playerContainerView,
             with: playerConfiguration.mutedIndicatorRelativeSizeToContainer,
             shift: .init(x: 20, y: -80),
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
  
  //let playerTimeLine = makeTimeLine()
  
  
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
  //                    timeLine:                playerTimeLine,
                      shutdownHandler:         shutdownHandler)
  
  let _ = makePlayerControls(player)
   .map{$0.confined(groupType: $0.group,
                    of: playerContainerView,
                    realtiveSize: playerConfiguration.controlsRelativeSizeToContainer)}
  
  
  
  //Hosted by player itself.
  player.notificationsTokens.append(contentsOf: adaptiveSizeTokens.map {$0 as Any})
  
  return player
 }
 
 
 
 
}

///#THIS IS DEFAULT PLAYER FACTORY THAT MAKES WORKING PLAYERS INSTANCE USING DEFAULT SET OF COMPONENTS BUILDERS.
///  - EchdConnectionManager - concrete impl of connections manager
/// - MDVRPlayerView - concrete impl of  VRPlayer view
/// - AVPlayerLayerView - concrete impl of  player live steraming facility.
/// - Default set builders of  player working contexts and views.

final internal class NTXDefaultPlayerKit : NSObject, NTXPlayerAbstractKit {

 internal typealias Player = NTXMobileNativePlayer<AVPlayerLayerView, MDVRPlayerView, EchdConnectionManager>

 internal typealias Kit = NTXDefaultPlayerKit
 
 /// Customize here player  container in this builder. The defaul kit uses default UIView.
 internal static var defaultContainer: GenericViewBuilder     { { UIView(frame: .zero) }        }
 
 /// Customize here player muted state view in this builder. The defaul kit uses default UIView.
 internal static var defaultMuted:     GenericViewBuilder     {
  { () -> UIImageView in
   let iv = UIImageView()
   if #available(iOS 15.0, *) {
    iv.image = .init(systemName: "speaker.slash")?
     .applyingSymbolConfiguration(.init(pointSize: 20))?
     .applyingSymbolConfiguration(.init(hierarchicalColor: .white))?
     .withTintColor(.white)
    
   } else {
    iv.image = .init(named: "speaker.slash")
   }
   return iv
  }
 }
 
 /// Customize alert view in this builder. The defaul kit uses default concrete NTXPlayerDefaultAlertView as an example.
 internal static var defaultAlert:     AlertViewBuilder       { { NTXPlayerDefaultAlertView() } }
 
 /// Customize and set player controls in this builder. The default kit uses the preset of buttons - NTXDefaultPlayerButton as an example.
 internal static var defaultControls:  PlayerControlsBuilder  {
  {
   [
    NTXDefaultPlayerButton(action: .playArchiveBack,    player: $0) {  $0.playArchiveBack() },
    NTXDefaultPlayerButton(action: .play,               player: $0) {  $0.play()            },
    NTXDefaultPlayerButton(action: .pause,              player: $0) {  $0.pause()           },
    NTXDefaultPlayerButton(action: .playArchiveForward, player: $0) {  $0.playArchiveForward() },
    NTXDefaultPlayerButton(action: .stop,               player: $0) {  $0.stop()            },
    NTXDefaultPlayerButton(action: .refresh,            player: $0) {  $0.refresh()         },
    NTXDefaultPlayerButton(action: .toggleMuting,       player: $0) {  $0.toggleMuting()    },
    
   ]
  }
 }

 /// Customize main player context here. Default kit uses generic type Player conforming NTXMobileNativePlayerProtocol.
 internal static var defaultContext:   () -> Player.PlayerContext        { { .init()} }
 
 ///Customize and set preload view  here. It might be any UIImageView.
 internal static var defaultPleload:   () -> UIImageView                 { { .init()} }
 
 ///Customize and set the activity indicator. It might be any view that conforms to NTXPlayerActivityIndicator. The default kit uses UIActivityIndicatorView.
 internal static var defaultActivity:  () -> NTXPlayerActivityIndicator  {
  {
   let ai = UIActivityIndicatorView()
   ai.style = .whiteLarge
   ai.color = .systemRed
   return ai
  }
 
 }
 
 ///Customize and set the player VR context here.
 internal static var defaultVRContext: () -> Player.PlayerVRContext      { { .init()} }
 
 ///Customize main player archive time line here. The default kit builds provided custom TimeLineView as an example.
 //internal static var defaultTimeLine:  () -> NTXPlayerTimeLine           { { UIView() } }
 
internal init(configuration:             NTXPlayerConfiguration<Player.Manager>,
             containerBuilder:           @escaping GenericViewBuilder       = Kit.defaultContainer,
             mutedViewBuilder:           @escaping GenericViewBuilder       = Kit.defaultMuted,
             alertViewBuilder:           @escaping AlertViewBuilder         = Kit.defaultAlert,
             controlsBuilder:            @escaping PlayerControlsBuilder    = Kit.defaultControls,
             contextBuilder:             @escaping PlayerContextBuilder     = Kit.defaultContext,
             preloadViewBuilder:         @escaping ImageViewBuilder         = Kit.defaultPleload,
             activityIndicatorBuilder:   @escaping ActivityIndicatorBuilder = Kit.defaultActivity,
             VRViewBuilder:              @escaping PlayerVRContextBuilder   = Kit.defaultVRContext,
            // timeLineBuilder:            @escaping TimeLineBuilder          = Kit.defaultTimeLine,
             shutdownHandler:            @escaping () -> () ) {

  self.playerConfiguration = configuration
  self.makePlayerContainer  = containerBuilder
  self.makePlayerMutedStateView  = mutedViewBuilder
  self.makeAlertView  = alertViewBuilder
  self.makePlayerControls  = controlsBuilder
  self.makePlayerContext  = contextBuilder
  self.makePlayerPreload  = preloadViewBuilder
  self.makeActivityIndicator  = activityIndicatorBuilder
  self.make360VRPlayerContext = VRViewBuilder
 // self.makeTimeLine  = timeLineBuilder
  self.shutdownHandler = shutdownHandler
  
  super.init()
 }
 
 
 internal var playerConfiguration       :   NTXPlayerConfiguration<Player.Manager>
 
 internal var makePlayerContainer       :   GenericViewBuilder
 
 internal var makePlayerMutedStateView  :   GenericViewBuilder
 
 internal var makePlayerControls        :   (Player) -> [ any NTXPlayerControl ]
 
 internal var makeAlertView             :   AlertViewBuilder
 
 internal var makePlayerContext         :   PlayerContextBuilder
 
 internal var makePlayerPreload         :   ImageViewBuilder
 
 internal var makeActivityIndicator     :   ActivityIndicatorBuilder
 
 internal var make360VRPlayerContext    :   PlayerVRContextBuilder
 
// internal var makeTimeLine              :   TimeLineBuilder
 
 internal let shutdownHandler: () -> ()
 

 
}


