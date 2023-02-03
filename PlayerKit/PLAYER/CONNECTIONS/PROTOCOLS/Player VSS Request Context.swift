//
//  Player VSS Request Context.swift
//  AreaSight
//
//  Created by Anton V. Kalinin on 05.12.2022.
//  Copyright © 2022 Netris. All rights reserved.
//

import Foundation


internal protocol NTXVSSDeviceRequestContext where Self: NSObject {
 
 init(data: [ String : AnyObject ])
 
 var archiveEnabled: Bool { get }
 
 func isSuccess() -> Bool?
 func getVersion() -> Int?
 func getPermissions() -> [String]?
 func getArchiveControlUrls() -> [String]?
 func getArchiveShotControlUrls() -> [String]?
 func getArchiveAndroidUrls() -> [String]?
 func getArchiveIosUrls() -> [String]?
 func getArchiveUrls() -> [String]?
 func getArchiveShotUrls() -> [String]?
 func getLiveAndroidUrls() -> [String]?
 func getLiveIosUrls() -> [String]?
 func getLiveUrls() -> [String]?
 func getLiveShotUrls() -> [String]?
 func getArchiveShotControl() -> [String]?
}

