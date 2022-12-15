//
//  AppVersionHelper.swift
//  Mobistreamer
//
//  Created by Alekperov Emin on 03.09.2018.
//  Copyright © 2018 Netris. All rights reserved.
//

struct AppVersionHelper {
    
    static let clientName = "videogorod-ios"
    
    static func getAppVersion() -> String {
        
        var result:String = ""
        
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            result += version
        }
        
        if let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            result += " (" + build
        }
        
        #if BUILD_CHANNEL_ALPHA
        result += " A"
        #elseif BUILD_CHANNEL_BETA
        result += " B"
        #endif
        
        // "T" - build for a test server
        #if PROFILE_TEST
        result += "T)"
        #else
        result += ")"
        #endif
        
        return result
    }
    
    static func getAppShortVersion() -> String {
        var appShortVersion = ""
        
        if let bundleShortVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            appShortVersion = bundleShortVersion
        }
        
        return appShortVersion
    }
}
