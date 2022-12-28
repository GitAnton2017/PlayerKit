//
//  Player Kit Configuration.swift
//  PlayerKitFramework
//
//  Created by Anton V. Kalinin on 16.12.2022.
//

import UIKit

internal struct NTXPlayerConfiguration <Manager  : NTXPlayerConnectionsManager,
                                        InputVSS : NTXVSSSearchResultContext> {
 
 internal let playerOwnerView:    UIView
 internal let inputVSS:           InputVSS
 internal let connectionManager:  Manager
 
 internal let insetsFromPlayerOwner:                        UIEdgeInsets
 internal let controlsRelativeSizeToContainer:              CGFloat
 internal let activityIndicatorRelativeSizeToContainer:     CGFloat
 internal let mutedIndicatorRelativeSizeToContainer:        CGFloat
 internal let alertViewRelativeHeightToContainer:           CGFloat
 internal let preloadViewInsetsFromContainer:               UIEdgeInsets
 internal let playerViewInsetsFromContainer:                UIEdgeInsets
 internal let playerVRViewInsetsFromContainer:              UIEdgeInsets
 
 internal var securityMarker: String?
 
 internal init (playerOwnerView:                           UIView,
                inputVSS:                                  InputVSS,
                connectionManager:                         Manager,
                insetsFromPlayerOwner:                     UIEdgeInsets = .zero,
                controlsRelativeSizeToContainer:           CGFloat = 0.1,
                activityIndicatorRelativeSizeToContainer:  CGFloat = 0.1,
                mutedIndicatorRelativeSizeToContainer:     CGFloat = 0.08,
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


