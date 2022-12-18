//
//  SettingsEntity.swift
//  AreaSight
//
//  Created by Emin Alekperov on 17.12.2019.
//  Copyright © 2019 Netris. All rights reserved.
//

struct UserProfileEntity {
    var username: String = ""
    var permissions: [UserPermissions] = []
}

struct SettingsEntity {
    var profile: UserProfileEntity
}
