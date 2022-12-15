//
//  SudirAuthenticateParameters.swift
//  AreaSight
//
//  Created by Shamil on 25.10.2020.
//  Copyright © 2020 Netris. All rights reserved.
//

import Foundation

struct SudirAuthenticateParameters {
    
    var parameters: [String: Any]
    
    init() {
        let clientName = AppVersionHelper.clientName
        let clientVersion = AppVersionHelper.getAppShortVersion()
        
        parameters = ["clientName": clientName, "clientVersion": clientVersion]
    }
}
