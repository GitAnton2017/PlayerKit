//
//  EchdSearchCameraListResponse.swift
//  AreaSight
//
//  Created by Александр Асиненко on 08.08.16.
//  Copyright © 2016 Netris. All rights reserved.
//

import UIKit

class EchdSearchCameraListResponse: NSObject {

    var cameras: [EchdSearchCamera] = [EchdSearchCamera]()
    var count: Int?
    var success: Bool?
    
    var data: JSONObject

    init(data: JSONObject){
        self.data = data
        count = data["count"] as? Int
        success = data["success"] as? Bool
        if let array = data["cameras"] as? [JSONObject] {
            for item in array {
                cameras.append(EchdSearchCamera(data: item as JSONObject))
            }
        }
    }
}
