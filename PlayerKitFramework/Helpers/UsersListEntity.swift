//
//  UsersListEntity.swift
//  AreaSight
//
//  Created by Emin Alekperov on 18.12.2019.
//  Copyright © 2019 Netris. All rights reserved.
//

struct UsersListItemData {
    
    var username: String
    var loginHash: String
    
    init(_ authorizationType: AuthorizationTypeNames, name: String, hash: String) {
        switch authorizationType {
        case .ECHD:
            username = AuthorizationTypeNames.ECHD.rawValue + " | " + name
        case .SUDIR:
            username = AuthorizationTypeNames.SUDIR.rawValue + " | " + name
        case .none:
            username = name
        }
        loginHash = hash
    }
}
