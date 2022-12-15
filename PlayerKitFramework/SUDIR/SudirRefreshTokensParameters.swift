//
//  SudirRefreshTokensParameters.swift
//  AreaSight
//
//  Created by Shamil on 05.11.2020.
//  Copyright © 2020 Netris. All rights reserved.
//

import Foundation

struct SudirRefreshTokensParameters {
    
    var parameters: [String: Any]
    
    init(_ refreshToken: String) {
        parameters = ["refresh_token": refreshToken, "grant_type": "refresh_token"]
    }
}
