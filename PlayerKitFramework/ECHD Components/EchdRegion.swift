//
//  EchdRegion.swift
//  AreaSightDemo
//
//  Created by Ruslan Utashev on 21.07.2020.
//  Copyright © 2020 Netris. All rights reserved.
//

import Foundation

internal final class EchdRegion {
    let code: Int
    let color: String
    let name: String
    let geoDataId: [Int]
    var coordinates: [[[ (Double, Double) ]]]? = []
    
    init(code: Int, color: String, name: String, geoDataId: [Int]) {
        self.code = code
        self.color = color
        self.name = name
        self.geoDataId = geoDataId
    }
    
    convenience init?(_ map: Any) {
        guard let map = map as? [String: Any] else { return nil }
        guard let code = map["code"] as? Int,
            let color = map["color"] as? String,
            let name = map["name"] as? String,
            let geoDataId = map["geoDataIds"] as? [Int] else { return nil }
        
        self.init(code: code, color: color, name: name, geoDataId: geoDataId)
        
    }
}
