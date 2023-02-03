//
//  ECHD VSS Description.swift
//  PlayerKit
//
//  Created by Anton2016 on 27.12.2022.
//

import Foundation

struct VSSListResponse: Codable {
 var success : Bool
 var cameras : [ VSSShortDescription ]
}

struct VSSShortDescription : Codable {
 
 var cameraType    : Int
 var description   : String
 var hasArchive    : Bool
 var hasAudio      : Bool
 var id            : Int
 var sphericalType : String
 
 var isVR: Bool {
  if sphericalType.isEmpty { return false }
  return sphericalType != "STANDARD"
 }
 
 static let empty = Self()
 
 init(){
  self.cameraType     =  0
  self.description    =  ""
  self.hasArchive     =  false
  self.hasAudio       =  false
  self.id             =  0
  self.sphericalType  =  ""
 }
 
 init(json: [ String : Any ]) {
  self.cameraType     = json["cameraType"]    as? Int    ?? 0
  self.description    = json["description"]   as? String ?? ""
  self.hasArchive     = json["hasArchive"]    as? Bool   ?? false
  self.hasAudio       = json["hasAudio"]      as? Bool   ?? false
  self.id             = json["id"]            as? Int    ?? 0
  self.sphericalType  = json["sphericalType"] as? String ?? ""
 }
 
}
