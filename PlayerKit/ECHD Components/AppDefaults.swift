//
//  AppDefaults.swift
//  AreaSight
//
//  Created by Александр Асиненко on 04.08.16.
//  Copyright © 2016 Netris. All rights reserved.
//

import UIKit

class AppDefaults {

    let APP_DEFAULTS_SERVER =                           "server"
    let APP_DEFAULTS_PORT =                             "port"
    let APP_DEFAULTS_FRAMERATE =                        "framerate"
    let APP_DEFAULTS_FRAMERATEINDEX =                   "framerateindex"
    let APP_DEFAULTS_BITRATEINDEX =                     "bitrateindex"
    let APP_DEFAULTS_BITRATEINT =                       "bitrateint"
    let APP_DEFAULTS_STREAMMODEINDEX =                  "streammodeindex"
    let APP_DEFAULTS_VIDEOSIZEINDEX =                   "videosizeindex"
    let APP_DEFAULTS_AUTORESTART =                      "autorestart"
    let APP_DEFAULTS_SERVERSDICTIONARY =                "serversdictionary"

    let APP_DEFAULTS_ISSHOWMESSAGEWHENBADCONNECTION =   "isshowmessage"

    let APP_DEFAULTS_SERVERNAME =                       "servername"
    let APP_DEFAULTS_GPSSERVER =                        "gpsserver"
    let APP_DEFAULTS_GPSPORT =                          "gpsport"
    let APP_DEFAULTS_STREAMNAME =                       "streamname"

    let APP_DEFAULTS_SERVERS =                          "servers"

    let APP_DEFAULTS_FILTER_ON =                        "isfilteron"

    let APP_DEFAULTS_VR_CONTROL =                       "vrcontrol"
    let APP_DEFAULTS_VR_VIEW =                          "vrview"
    let APP_DEFAULTS_VR_TYPE =                          "vrtype"
    let APP_DEFAULTS_VR_OFFSET =                        "vroffset"
    let APP_DEFAULTS_ADMIXTURE_CANVAS =                 "admixtureCanvas"
    
    let APP_DEFAULTS_HAS_RUN_BEFORE =                   "hasRunBefore"
    let APP_DEFAULTS_USER_AUTHORIZED =                  "isUserAuthorized"
    
    let APP_DEFAULTS_CHANGED_SERVER_ADDRESS =           "changedServerAddress"
    
    let APP_DEFAULTS_CHANGED_PASSWORD =                 "changedPassword"
    
    let APP_DEFAULTS_IS_ONE_CAMERA_FULLSCREEN =         "isOneCameraFullScreen"
    
    let APP_DEFAULTS_IS_BIOMETRY_AUTHORIZATION =        "isBiometryAuthorization"
    
    let APP_DEFAULTS_LATITUDE =                         "latitude"
    let APP_DEFAULTS_LONGITUDE =                        "longitude"
    let APP_DEFAULTS_ZOOM =                             "zoom"
    
    let APP_DEFAULTS_MAP_TYPE =                         "mapType"
    let APP_DEFAULTS_DEFAULT_MAP_TYPE =                 "Yandex"
    
    let APP_DEFAULTS_ARCHIVE_RECORDING_URL =            "archiveRecordingUrl"
    
    let APP_DEFAULTS_MANUAL_ETAG =                      "manualEtag"
    let APP_DEFAULTS_MANUAL_LAST_MODIFIED =             "manualLastModified"

    let APP_DEFAULTS_SUDIR_USERS =                      "sudirUsers"
    let APP_DEFAULTS_IS_SUDIR_AUTHORIZATION =           "isSudirAuthorization"

    let APP_DEFAULTS_IS_USER_NOTIFIED_ABOUT_EGIP =      "isUserNotifiedAboutEgip"
    
    let APP_DEFAILTS_FIRST_RUN =                        "firstRun"

    static let sharedInstance = AppDefaults()
    
    private init() {}
    
    func setValue(_ key: String, value: AnyObject?) {
        UserDefaults.standard.setValue(value, forKey: key)
    }
    
    func setBoolValue(_ key: String, bool: Bool) {
        UserDefaults.standard.set(bool, forKey: key)
    }

    func getValue(_ key: String) -> AnyObject? {
        return UserDefaults.standard.object(forKey: key) as AnyObject?
    }
    
    func getBoolValue(_ key: String) -> Bool {
        return UserDefaults.standard.bool(forKey: key)
    }

    func setSelectedValue(_ key: String, level: Int, selected: Bool) {
        UserDefaults.standard.setValue(selected, forKey: "\(key)\(level)")
    }

    func selectedValue(_ key: String, level: Int) -> Bool {
        if let dic = UserDefaults.standard.value(forKey: "\(key)\(level)") as? Bool {
            return dic
        }
        return true
    }
}
