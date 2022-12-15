//
//  CameraColorSource.swift
//  AreaSight
//
//  Created by Shamil on 11.03.2021.
//  Copyright © 2021 Netris. All rights reserved.
//

import Foundation

protocol CameraColorSource: AnyObject {
    
    func getColor(for type: Int) -> String?
    func getStatusColor(for: Int) -> String?
}
