//
//  Headers.swift
//  AreaSight
//
//  Created by Shamil on 31.05.2021.
//  Copyright © 2021 Netris. All rights reserved.
//

import Foundation
import Alamofire
import UIKit

class Headers {
    
    static func getHeadersWithCookie(_ cookie: String) -> HTTPHeaders {
        var headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "X-Requested-With": "XMLHttpRequest"
        ]
        
        headers["Cookie"] = cookie
        headers["User-Agent"] = Headers.getUserAgent()

        return headers
    }
    
    static func getUserAgent() -> String {
        var version = "?"
        if let tmpVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            version = tmpVersion
        }
        
        var build = "?"
        if let tmpBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            build = tmpBuild
        }
       
        return "Videogorod/\(version) ios/\(UIDevice.current.model) iOS/\(UIDevice.current.systemVersion) CFNetwork/0 Darwin/\(build)"
    }
}
