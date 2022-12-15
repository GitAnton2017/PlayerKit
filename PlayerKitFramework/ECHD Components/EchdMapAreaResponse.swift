//
//  EchdMapAreaResponse.swift
//  AreaSightDemo
//
//  Created by Ruslan Utashev on 30.07.2020.
//  Copyright © 2020 Netris. All rights reserved.
//

import Foundation

class EchdMapAreaResponse: NSObject {

    var regionsCoordinates: [ String: [ [ [ (Double, Double) ] ] ] ] = [:]

    init(data: JSONObject){
        super.init()
        if let p2 = data["response"] as? [String: Any] {
            p2.forEach { (regionData) in
                if let region = regionData.value as? [String: Any],
                    let p4 = region["getData"] as? String {
                    let data = p4.data(using: String.Encoding.utf8)!

                    let object = try! JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)

                    if let p5 = object as? [String: Any],
                        let p6 = p5["features"] as? [Any],
                        let p7 = p6[0] as? [String: Any],
                        let p8 = p7["geometry"] as? [String: Any],
                        let p9 = p8["coordinates"] as? [[Any]],
                        let p10 = p9 as? [[[[Any]]]] {
                        
                        let result = p10.compactMap { (item) -> [[(Double, Double)]] in
                            let p11 = item.compactMap { (zone) -> [(Double, Double)] in
                                let sectors = zone.compactMap { (sector) -> (Double, Double)? in
                                    guard let lat = sector[1] as? Double,
                                        let long = sector[0] as? Double else { return nil }
                                    
                                    return (lat, long)
                                }
                                return sectors
                            }
                            return p11
                        }
                        regionsCoordinates[regionData.key] = result
                    }
                }
            }
        }
    }
}
