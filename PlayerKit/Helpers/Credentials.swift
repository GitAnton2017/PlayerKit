//
//  Credential.swift
//  Keychain
//
//  Created by Artem Lytkin on 27/06/2019.
//  Copyright © 2019 Artem Lytkin. All rights reserved.
//

enum BiometryType: String, Codable {
    case touch
    case face
    // A user doesn't want to use a biometric authentication
    case none
    // A device doesn't suppot a biometric authentication
    case no
}

struct ServerAuthData: Codable {
    var login: String
    var password: String
}

struct LocalAuthData: Codable {
    var isNew: Bool
    // In common case a "username" is not the same as "login". But now these are the same entity.
    // Because of this we protect the "username" property
    var username: String
    var loginHash: String
    var pincode: String
    //var hasPincode: Bool
    var biometryType: BiometryType
}

struct Credentials: Codable {
    var token: String
    var sessionId: String
}
