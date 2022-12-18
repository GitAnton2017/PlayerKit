//
//  Filter.swift
//  JsonParser
//
//  Created by Artem Lytkin on 25/02/2019.
//  Copyright © 2019 Artem Lytkin. All rights reserved.
//

import Foundation

class Filter: NSObject, Codable {
    var types: [CameraType]
    var statuses: [CameraStatus]
    var districts: [DistrictNode]
    
    private enum CodingKeys: String, CodingKey {
        case types
        case statuses
        case districts
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        do {
            let types = try values.decode(Dictionary<Int, CameraType>.self, forKey: .types)
            self.types = [CameraType](types.values)
            
            let statuses = try values.decode(Dictionary<Int, CameraStatus>.self, forKey: .statuses)
            self.statuses = []
            for (id, cameraStatus) in statuses {
                cameraStatus.id = id
                self.statuses.append(cameraStatus)
            }
            
            let districts = try values.decode(Dictionary<Int, DistrictNode>.self, forKey: .districts)
            self.districts = [DistrictNode](districts.values)
        
        } catch DecodingError.typeMismatch {
            
            types = try values.decode([CameraType].self, forKey: .types)
            statuses = try values.decode([CameraStatus].self, forKey: .statuses)
            districts = try values.decode([DistrictNode].self, forKey: .districts)
        }
    }
}
