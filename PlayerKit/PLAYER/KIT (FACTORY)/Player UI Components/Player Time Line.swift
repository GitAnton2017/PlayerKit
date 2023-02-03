//
//  Player Time Line.swift
//  AreaSight
//
//  Created by Anton V. Kalinin on 07.12.2022.
//  Copyright © 2022 Netris. All rights reserved.
//

import UIKit

internal protocol NTXPlayerTimeLine where Self: UIView {
 func setStartPosition(_ seconds: Int)
 func setTime(_ seconds: Int)
 func stopAnimating(_ stopAnimationHandler: ( () -> () )? )
 
}

final internal class NTXTimeLineMarkerLabel: UILabel, NTXPlayerTimeLine {
 func stopAnimating(_ stopAnimationHandler: ( () -> () )? = nil ) {}
 
 
 private var depthSeconds: Int = 0
 
 init() {
  super.init(frame: .zero)
  numberOfLines = 1
  minimumScaleFactor = 0.05
  font = .systemFont(ofSize: 30)
  adjustsFontForContentSizeCategory = true
  adjustsFontSizeToFitWidth = true
  textAlignment = .center
 }
 
 required init?(coder: NSCoder) {
  fatalError("init(coder:) has not been implemented")
 }
 
 func setStartPosition(_ seconds: Int) {
  depthSeconds = seconds
  self.text = seconds < 0 ? "\(seconds) сек." : nil
 }
 
 func setTime(_ seconds: Int) {
  self.text = "\(seconds < depthSeconds ? "◀︎" : "") [ \(seconds) сек. ] \(seconds > depthSeconds ? "▶︎" : "")"
  depthSeconds = seconds
 }
}
