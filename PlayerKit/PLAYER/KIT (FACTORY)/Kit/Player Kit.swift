//
//  NTXPlayerAbstractFactory.swift
//  AreaSightDemo
//
//  Created by Anton V. Kalinin on 02.12.2022.
//  Copyright © 2022 Netris. All rights reserved.
//

import UIKit

///# THIS IS DEFAULT PLAYER FACTORY (KIT) FOR ECHD CONNECTIONS WITH GENERIC DELEGATE:

typealias NTXECHDPlayerKit<Delegate: NTXVideoModuleDelegate>
  = NTXDefaultPlayerKit<AVPlayerLayerView,
                        MDVRPlayerView,
                        NTXECHDManager,
                        Delegate> where Delegate.Device == Int
  
/// - EchdConnectionManager - concrete impl of connections manager
/// - MDVRPlayerView - concrete impl of  VRPlayer view
/// - AVPlayerLayerView - concrete impl of  player live steraming facility.
/// - Default set builders of  player working contexts and views.
/// - Generic Delegate. NTXVideoModuleDelegate

///#THIS IS GENERIC PLAYER FACTORY (KIT) THAT MAKES WORKING PLAYERS INSTANCE USING  SET OF COMPONENTS BUILDERS.

final internal class NTXDefaultPlayerKit<Context:   NTXPlayerContext,
                                         VRContext: NTXPlayerContext,
                                         Manager:   NTXPlayerConnectionsManager,
                                         Delegate:  NTXVideoModuleDelegate>: NSObject, NTXPlayerAbstractKit
where Delegate.Device == Manager.InputDevice {
 

 internal typealias Player = NTXMobileNativePlayer<Context, VRContext, Manager, Delegate>

 internal typealias Kit = NTXDefaultPlayerKit
 
 /// Customize here player  container in this builder. The defaul kit uses default UIView.
 internal static var defaultContainer: GenericViewBuilder     {
  {
   let view = UIView(frame: .zero)
   view.backgroundColor = #colorLiteral(red: 0, green: 0.1639138963, blue: 0.7338046119, alpha: 1)
   return view
   
  }
  
 }
 
 /// Customize here player muted state view in this builder. The defaul kit uses default UIView.
 internal static var defaultMuted:     GenericViewBuilder     {
  { () -> UIImageView in
   let iv = UIImageView()
   if #available(iOS 15.0, *) {
    iv.image = .init(systemName: "muted")?
     .applyingSymbolConfiguration(.init(pointSize: 20))?
     .applyingSymbolConfiguration(.init(hierarchicalColor: .systemRed.withAlphaComponent(0.85)))?
     .withTintColor(.systemRed.withAlphaComponent(0.85))
    
   } else {
    iv.image = .init(named: "muted",
                     in: .init(for: Self.self),
                     compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
    
    iv.tintColor = .systemOrange
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
    NTXDefaultPlayerButton(action: .playArchiveBack,    player: $0) {
     $0.playArchiveBack()
    }.withDebounce(0.3),
    
    NTXDefaultPlayerButton(action: .play,               player: $0) {  $0.play()            },
    NTXDefaultPlayerButton(action: .pause,              player: $0) {  $0.pause()           },
    
    NTXDefaultPlayerButton(action: .playArchiveForward, player: $0) {
     $0.playArchiveForward()
    }.withDebounce(0.3),
    
    
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
   if #available(iOS 13.0, *) {
    ai.style = .large
   } else {
    ai.style = .whiteLarge
   }
   ai.color = .systemOrange
   return ai
  }
 
 }
 
 ///Customize and set the player VR context here.
 internal static var defaultVRContext: () -> Player.PlayerVRContext      { { .init()} }
 
 ///Customize main player archive time line here. 
 internal static var defaultTimeLine:  () -> NTXPlayerTimeLine           {
  {
   let label = NTXTimeLineMarkerLabel()
   label.numberOfLines = 1
   label.font = .systemFont(ofSize: 50)
   label.textAlignment = .center
   label.textColor = .systemOrange.withAlphaComponent(0.75)
   return label
   
  }
  
 }
 
 internal init(configuration:            NTXPlayerConfiguration<Player.Manager, Player.Delegate.Device>,
             containerBuilder:           @escaping GenericViewBuilder       = Kit.defaultContainer,
             mutedViewBuilder:           @escaping GenericViewBuilder       = Kit.defaultMuted,
             alertViewBuilder:           @escaping AlertViewBuilder         = Kit.defaultAlert,
             controlsBuilder:            @escaping PlayerControlsBuilder    = Kit.defaultControls,
             contextBuilder:             @escaping PlayerContextBuilder     = Kit.defaultContext,
             preloadViewBuilder:         @escaping ImageViewBuilder         = Kit.defaultPleload,
             activityIndicatorBuilder:   @escaping ActivityIndicatorBuilder = Kit.defaultActivity,
             VRViewBuilder:              @escaping PlayerVRContextBuilder   = Kit.defaultVRContext,
             timeLineBuilder:            @escaping TimeLineBuilder          = Kit.defaultTimeLine,
             shutdownHandler:            @escaping (Delegate.Device) -> () ) {

  self.playerConfiguration = configuration
  self.makePlayerContainer  = containerBuilder
  self.makePlayerMutedStateView  = mutedViewBuilder
  self.makeAlertView  = alertViewBuilder
  self.makePlayerControls  = controlsBuilder
  self.makePlayerContext  = contextBuilder
  self.makePlayerPreload  = preloadViewBuilder
  self.makeActivityIndicator  = activityIndicatorBuilder
  self.make360VRPlayerContext = VRViewBuilder
  self.makeTimeLine  = timeLineBuilder
  self.shutdownHandler = shutdownHandler
  
  super.init()
 }
 
 
 internal var playerConfiguration       :   NTXPlayerConfiguration<Player.Manager, Delegate.Device>
 
 internal var makePlayerContainer       :   GenericViewBuilder
 
 internal var makePlayerMutedStateView  :   GenericViewBuilder
 
 internal var makePlayerControls        :   (Player) -> [ any NTXPlayerControl ]
 
 internal var makeAlertView             :   AlertViewBuilder
 
 internal var makePlayerContext         :   PlayerContextBuilder
 
 internal var makePlayerPreload         :   ImageViewBuilder
 
 internal var makeActivityIndicator     :   ActivityIndicatorBuilder
 
 internal var make360VRPlayerContext    :   PlayerVRContextBuilder
 
 internal var makeTimeLine              :   TimeLineBuilder
 
 internal let shutdownHandler: (Delegate.Device) -> ()
 
 deinit {
  debugPrint(String(describing: Self.self), " IS DESTROYED SUCCESSFULLY!")
 }
 
}


