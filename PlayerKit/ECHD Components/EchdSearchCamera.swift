//
//  EchdSearchCamera.swift
//  AreaSight
//
//  Created by Александр Асиненко on 26.07.16.
//  Copyright © 2016 Netris. All rights reserved.
//

import CoreFoundation


final class EchdSearchCamera: NSObject, Comparable {
 
 var id : Int? //VSS Id for request
    
 static func < (lhs: EchdSearchCamera, rhs: EchdSearchCamera) -> Bool {
        guard let leftName = lhs.name, let rightName = rhs.name else {
            return false
        }
        return leftName < rightName
    }
    
   static func > (lhs: EchdSearchCamera, rhs: EchdSearchCamera) -> Bool {
        guard let leftName = lhs.name, let rightName = rhs.name else {
            return false
        }
        return leftName > rightName
    }
    
    internal static func == (lhs: EchdSearchCamera, rhs: EchdSearchCamera) -> Bool {
        guard let lhsId = lhs.id, let rhsId = rhs.id else {
            return false
        }
        return lhsId == rhsId
    }
    
    private var _lat: Double?
    private var _lng: Double?

    var address:String?
    var apiType:String?
    var azimuth_delta:Int?
    var cameraType:Int?
    var cameraDescription:String?
    var district:Int?
    var eId:String?
    var fixed:Bool?
    var hasArchive:Bool?
    var height:Int?
    
    var ip:String?
    var isFavorite:Bool?
    var model:String?
    var name:String?
    var precise_latitude:Double?
    var precise_longitude:Double?
    var region:Int?
    var shortName:String?
    var status:Int?
    var type:Int?
    var vision_range:Int?

    var lat: Double? { get {
        return _lat ?? precise_latitude
    }}
    var lng: Double? {get {
        return _lng ?? precise_longitude
    }}
    
    var data:JSONObject?

    init(data:JSONObject){
        self.data = data
        id = data["id"] as? Int
        cameraDescription = data["description"] as? String
        ip = data["ip"] as? String
        fixed = data["fixed"] as? Bool
        cameraType = data["cameraType"] as? Int
        district = data["district"] as? Int
        region = data["region"] as? Int
        apiType = data["apiType"] as? String
        hasArchive = data["hasArchive"] as? Bool
        
        if let cameraNameDescription = data["name"] as? String,
           let indexOfSemicolon = cameraNameDescription.firstIndex(of: " ") {
            
            let cameraDescription = cameraNameDescription[cameraNameDescription.index(after: indexOfSemicolon)...]
            
            name = String(cameraDescription)
        }
        
        shortName = data["shortName"] as? String
        address = data["address"] as? String
        
        type = data["type"] as? Int
        eId = data["eId"] as? String
        status = data["status"] as? Int
        isFavorite = data["isFavorite"] as? Bool
        azimuth_delta = data["azimuth_delta"] as? Int
        height = data["height"] as? Int
        vision_range = data["vision_range"] as? Int
        model = data["model"] as? String
        

        precise_latitude = data["precise_latitude"] as? Double
        precise_longitude = data["precise_longitude"] as? Double
        _lat = data["lat"] as? Double
        _lng = data["lng"] as? Double
    }
}
