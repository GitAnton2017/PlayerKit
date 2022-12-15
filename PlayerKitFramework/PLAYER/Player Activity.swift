//
//  Player Activity.swift
//  AreaSightDemo
//
//  Created by Anton V. Kalinin on 03.12.2022.
//  Copyright © 2022 Netris. All rights reserved.
//


import UIKit

internal protocol NTXPlayerActivityIndicator where Self: UIView {
 func startAnimating()
  // Starts the animation of the progress indicator.
 func stopAnimating()
  // Stops the animation of the progress indicator.
 var isAnimating: Bool { get }
  // A Boolean value indicating whether the activity indicator is currently running its animation.
 var hidesWhenStopped: Bool { get set }
  //A Boolean value that controls whether the activity indicator is hidden when the animation is stopped.
 var color: UIColor! { get set }
}

extension UIActivityIndicatorView: NTXPlayerActivityIndicator{}
