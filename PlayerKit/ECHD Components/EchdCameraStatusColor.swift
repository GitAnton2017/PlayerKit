//
//  EchdCameraStatusColor.swift
//  AreaSightDemo
//
//  Created by Ruslan Utashev on 03.02.2020.
//  Copyright © 2020 Netris. All rights reserved.
//

import Foundation

enum CameraStatusColor {
    
    case zero
    case first
    case second
    case thrid
    case fourth
    case fifth
    
    init(id: Int) {
        switch id {
        case 0:
            self = .zero
        case 1:
            self = .first
        case 2:
            self = .second
        case 3:
            self = .thrid
        case 4:
            self = .fourth
        case 5:
            self = .fifth
        default:
            self = .zero
        }
    }
    
    func getColor() -> String {
        switch self {
        case .zero:
            return "#CCCCCC"
        case .first:
            return "#FF9600"
        case .second:
            return  "#FF0000"
        case .thrid:
            return "#969696"
        case .fourth:
            return "#FF7700"
        case .fifth:
            return "#770000"
        }
    }
}
