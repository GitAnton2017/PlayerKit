//
//  SudirTokens.swift
//  AreaSight
//
//  Created by Shamil on 01.04.2020.
//  Copyright © 2020 Netris. All rights reserved.
//

import Foundation

struct SudirTokens: Decodable {
        
    let idToken: String?
    let accessToken: String
    let expiresIn: Int
    let scope: String
    let refreshToken: String
    let tokenType: String
}
