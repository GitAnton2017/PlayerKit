//
//  Player VSS Archive Context.swift
//  AreaSight
//
//  Created by Anton V. Kalinin on 05.12.2022.
//  Copyright © 2022 Netris. All rights reserved.
//

import Foundation

internal protocol NTXVSSArchiveControlContext where Self: NSObject{
  init(data : [String: AnyObject] )
  var depth : Int? { get set }
  var start : Int? { get set }
  var end   : Int? { get set }
}


