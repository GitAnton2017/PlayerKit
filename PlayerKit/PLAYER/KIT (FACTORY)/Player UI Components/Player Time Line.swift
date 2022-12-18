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
 
}

final internal class NTXTimeLineMarkerLabel: UILabel, NTXPlayerTimeLine {
 
 private var depthSeconds: Int = 0
 
 func setStartPosition(_ seconds: Int) {
  depthSeconds = seconds
  self.text = seconds < 0 ? "\(seconds) сек." : nil
 }
 
 
 func setTime(_ seconds: Int) {
  self.text = "\(seconds < depthSeconds ? "◀︎" : "") [ \(seconds) сек. ] \(seconds > depthSeconds ? "▶︎" : "")"
  depthSeconds = seconds
 }
}
