//
//  EchdKeychainService.swift
//  Keychain
//
//  Created by Artem Lytkin on 28/06/2019.
//  Copyright © 2019 Artem Lytkin. All rights reserved.
//

import KeychainAccess
import CommonCrypto

protocol EchdKeychainServiceProtocol {
    
    // MARK: - Active user
    
    func getActiveUser() -> String?
    @discardableResult
    func removeActiveUser() -> Bool
    func set(activeUser: String)
    
    // MARK: - Local auth data
    
    func getUsersLocalAuthData() -> [LocalAuthData]
    func getLocalAuthData(for loginHash: String) -> LocalAuthData?
    @discardableResult
    func set(localAuthData: LocalAuthData) -> Bool
    @discardableResult
    func update(isNew: Bool, for loginHash: String) -> Bool
    @discardableResult
    func update(username: String, for loginHash: String) -> Bool
    @discardableResult
    func update(pincode: String?, for loginHash: String) -> Bool
    @discardableResult
    func removePincode(for loginHash: String) -> Bool
    @discardableResult
    func update(biometryType: BiometryType, for loginHash: String) -> Bool
    
    // MARK: - Credentials
    
    func getCredentials(for loginHash: String) -> Credentials?
    @discardableResult
    func set(credentials: Credentials, for loginHash: String) -> Bool
    @discardableResult
    func update(sessionId: String, for loginHash: String) -> Bool
    @discardableResult
    func update(token: String, for loginHash: String) -> Bool
    
    // MARK: - Server auth data
    
    func getServerAuthData(for loginHash: String) -> ServerAuthData?
    @discardableResult
    func update(password: String, for login: String) -> Bool
    @discardableResult
    func set(serverAuthData: ServerAuthData, for loginHash: String) -> Bool
    
    // MARK: - Users
    
    @discardableResult
    func addUser(withLogin loginHash: String) -> Bool
    @discardableResult
    func removeUser(withLogin loginHash: String) -> Bool
    @discardableResult
    func save(usersList: [String]) -> Bool
    func removeAll()
    func contains(loginHash: String) -> Bool
    
    // MARK: - Common methods
    
    func getHash(for data: String) -> String?
    
    // MARK: - Set and get value for key
    
    func set(_ value: String, forKey: String)
    func getValue(forKey: String) -> String?
}

class EchdKeychainService: NSObject {
    
    // MARK: - Enum keys
    
    enum Keys: String {
        
        case active
        case users
        
        case sudirRedirectUri
        case sudirCodeVerifier
        case sudirClientId
        case sudirClientSecret
        case sudirAccessToken
        case sudirRefreshToken
        case sudirRegistrationClientUri
        case sudirRegistrationAccessToken
    }
    
    // MARK: - Properties
    
    static let sharedInstance = EchdKeychainService()
    
    static private let privateService = "m9eGR43fGH354gfdsgtwa145812"
 
    private let keychain = Keychain(service: privateService)
    
    // MARK: - Lifecycle
    
    override init() {
        super.init()

        NotificationCenter.default.addObserver(self, selector: #selector(removeAll), name: EchdNotificationNames.removePasswords, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Private
        
    private func decodeKeys(for loginHash: String) -> (serverAuthKey: String, credentialsKey: String, localAuthKey: String) {
        var keysList = Array<String>()
        if let keys = keychain[loginHash] {
            keysList = keys.components(separatedBy: ":")
        }
        
        var result = ("", "", "")
        
        if keysList.count < 1 || keysList[0].isEmpty {
            result.0 = getHash(for: "\(loginHash)_server") ?? ""
        } else {
            result.0 = keysList[0]
        }

        if keysList.count < 2 || keysList[1].isEmpty {
            result.1 = getHash(for: "\(loginHash)_credentials") ?? ""
        } else {
            result.1 = keysList[1]
        }
        
        if keysList.count < 3 || keysList[2].isEmpty {
            result.2 = getHash(for: "\(loginHash)_local") ?? ""
        } else {
            result.2 = keysList[2]
        }
        
        keychain[loginHash] = "\(result.0):\(result.1):\(result.2)"
        
        return result
    }
}

// MARK: - EchdKeychainServiceProtocol

extension EchdKeychainService: EchdKeychainServiceProtocol {
    
    // MARK: - Active user
    
    func getActiveUser() -> String? {
        return keychain[EchdKeychainService.Keys.active.rawValue]
    }
    
    @discardableResult
    func removeActiveUser() -> Bool {
        do {
            try keychain.remove(EchdKeychainService.Keys.active.rawValue)
        } catch {
            debugPrint("KeychainService::removeAcitveUser: \(error)")
            
            return false
        }
        
        return true
    }
    
    func set(activeUser: String) {
        keychain[EchdKeychainService.Keys.active.rawValue] = activeUser
    }
    
    // MARK: - Local auth data
    
    func getUsersLocalAuthData() -> [LocalAuthData] {
        return getUsers().compactMap { user in self.getLocalAuthData(for: user)}
    }
    
    func getLocalAuthData(for loginHash: String) -> LocalAuthData? {
        let keys = decodeKeys(for: loginHash)
        
        if keys.localAuthKey.isEmpty { return nil }
        
        guard let jsonData = keychain[keys.localAuthKey]?.data(using: .utf8) else { return nil }
        
        do {
            return try JSONDecoder().decode(LocalAuthData.self, from: jsonData)
        } catch {
            debugPrint("KeyChainService::getLocalAuthData(for:): \(error)")
            
            return nil
        }
    }
    
    @discardableResult
    func set(localAuthData: LocalAuthData) -> Bool {
        let keys = decodeKeys(for: localAuthData.loginHash)
        
        if keys.localAuthKey.isEmpty { return false }
        
        do {
            let jsonData = try JSONEncoder().encode(localAuthData)
            keychain[keys.localAuthKey] = String(data: jsonData, encoding: .utf8)!
        } catch {
            debugPrint("KeyChainService::set(localAuthData:for:): \(error)")
            
            return false
        }
        
        return true
    }
    
    @discardableResult
    func update(isNew: Bool, for loginHash: String) -> Bool {
        if var localAuthData = getLocalAuthData(for: loginHash) {
            localAuthData.isNew = isNew
            return set(localAuthData: localAuthData)
        } else {
            let newLocalAuthData = LocalAuthData(isNew: true, username: "", loginHash: loginHash, pincode: "", biometryType: .none)
            return set(localAuthData: newLocalAuthData)
        }
    }
    
    @discardableResult
    func update(username: String, for loginHash: String) -> Bool {
        if var localAuthData = getLocalAuthData(for: loginHash) {
            localAuthData.username = username
            return set(localAuthData: localAuthData)
        } else {
            let newLocalAuthData = LocalAuthData(isNew: true, username: username, loginHash: loginHash, pincode: "", biometryType: .none)
            return set(localAuthData: newLocalAuthData)
        }
    }
    
    @discardableResult
    func update(pincode: String?, for loginHash: String) -> Bool {
        let pin = pincode ?? ""
        
        if var localAuthData = getLocalAuthData(for: loginHash) {
            localAuthData.pincode = pin
            
            return set(localAuthData: localAuthData)
        } else {
            let newLocalAuthData = LocalAuthData(isNew: true, username: "", loginHash: loginHash, pincode: pin, biometryType: .none)
            return set(localAuthData: newLocalAuthData)
        }
    }
    
    @discardableResult
    internal func removePincode(for loginHash: String) -> Bool {
        guard var data = getLocalAuthData(for: loginHash) else { return false }
        
        data.pincode = ""
        
        return set(localAuthData: data)
    }
    
    @discardableResult
    internal func update(biometryType: BiometryType, for loginHash: String) -> Bool {
        if var localAuthData = getLocalAuthData(for: loginHash) {
            localAuthData.biometryType = biometryType
            
            return set(localAuthData: localAuthData)
        } else {
            let newLocalAuthData = LocalAuthData(isNew: false, username: "", loginHash: loginHash, pincode: "", biometryType: biometryType)
            return set(localAuthData: newLocalAuthData)
        }
    }
    
    // MARK: - Credentials
            
    internal func getCredentials(for loginHash: String) -> Credentials? {
        let keys = decodeKeys(for: loginHash)
        
        if keys.credentialsKey.isEmpty { return nil }
        
        guard let jsonData = keychain[keys.credentialsKey]?.data(using: .utf8) else { return nil }
        
        do {
            return try JSONDecoder().decode(Credentials.self, from: jsonData)
        } catch {
            debugPrint("KeyChainService::getCredentials(for:): \(error)")
            
            return nil
        }
    }
    
    func set(credentials: Credentials, for loginHash: String) -> Bool {
        let keys = decodeKeys(for: loginHash)
        
        if keys.credentialsKey.isEmpty { return false }
        
        do {
            let jsonData = try JSONEncoder().encode(credentials)
            keychain[keys.credentialsKey] = String(data: jsonData, encoding: .utf8)!
        } catch {
            debugPrint("KeyChainService::set(credentials:for:): \(error)")
            
            return false
        }
        
        return true
    }
    
    @discardableResult
    func update(sessionId: String, for loginHash: String) -> Bool {
        if var credentials = getCredentials(for: loginHash) {
            credentials.sessionId = sessionId
            return set(credentials: credentials, for: loginHash)
        } else {
            let newCredentials = Credentials(token: "", sessionId: sessionId)
            return set(credentials: newCredentials, for: loginHash)
        }
    }
    
    @discardableResult
    func update(token: String, for loginHash: String) -> Bool {
        if var credentials = getCredentials(for: loginHash) {
            credentials.token = token
            return set(credentials: credentials, for: loginHash)
        } else {
            let newCredentials = Credentials(token: token, sessionId: "")
            return set(credentials: newCredentials, for: loginHash)
        }
    }
    
    // MARK: - Server auth data
    
    func getServerAuthData(for loginHash: String) -> ServerAuthData? {
        let keys = decodeKeys(for: loginHash)
        
        if keys.serverAuthKey.isEmpty { return nil }
        
        guard let jsonData = keychain[keys.serverAuthKey]?.data(using: .utf8) else { return nil }
        
        do {
            return try JSONDecoder().decode(ServerAuthData.self, from: jsonData)
        } catch {
            debugPrint("KeyChainService::getServerAuthData(for:): \(error)")
            
            return nil
        }
    }
    
    @discardableResult
    func update(password: String, for loginHash: String) -> Bool {        
        guard var data = getServerAuthData(for: loginHash) else { return false }
        
        data.password = password
        
        return set(serverAuthData: data, for: loginHash)
    }
    
    func set(serverAuthData: ServerAuthData, for loginHash: String) -> Bool {
        let keys = decodeKeys(for: loginHash)
        
        if keys.serverAuthKey.isEmpty { return false }
        
        do {
            let jsonData = try JSONEncoder().encode(serverAuthData)
            keychain[keys.serverAuthKey] = String(data: jsonData, encoding: .utf8)!
        } catch {
            debugPrint("KeyChainService::set(serverAuthData:for:): \(error)")
            
            return false
        }
        
        return true
    }
    
    // MARK: - Users
    
    @discardableResult
    func addUser(withLogin loginHash: String) -> Bool {
        var list  = getUsers()
        list.append(loginHash)
        
        return save(usersList: list)
    }
    
    @discardableResult
    func removeUser(withLogin loginHash: String) -> Bool {
        var list  = getUsers()
        list.append(loginHash)
        
        return save(usersList: list)
    }
    
    @discardableResult
    func save(usersList: [String]) -> Bool {
        do {
            let jsonData = try JSONEncoder().encode(usersList)
            keychain[EchdKeychainService.Keys.users.rawValue] = String(data: jsonData, encoding: .utf8)!
        } catch {
            debugPrint("KeyChainService::save(usersList:) \(error)")
            
            return false
        }
        
        return true
    }
    
    private func getUsers() -> [String] {
        guard let jsonData = keychain[EchdKeychainService.Keys.users.rawValue]?.data(using: .utf8) else { return [] }
        
        do {
            return try JSONDecoder().decode([String].self, from: jsonData)
        } catch {
            debugPrint("KeyChainService::getUsers: \(error)")
            
            return []
        }
    }
    
    @objc internal func removeAll() { try? keychain.removeAll() }
    
    func contains(loginHash: String) -> Bool {
        return getUsers().contains(loginHash)
    }
    
    // MARK: - Common methods
    
    internal func getHash(for key: String) -> String? {
        if let data = key.data(using: .utf8) {
            var digest = Data(count: Int(CC_SHA256_DIGEST_LENGTH))
            
            _ = digest.withUnsafeMutableBytes {digestBytes in
                data.withUnsafeBytes { messageBytes in
                    CC_SHA256(messageBytes, CC_LONG(data.count), digestBytes)
                }
            }
            
            var result = ""
            
            for byte in digest {
                result += String(format:"%02x", UInt8(byte))
            }
            
            return result
        } else {
            return nil
        }
    }
    
    // MARK: - Set and get value for key
    
    func set(_ value: String, forKey: String) {
        keychain[forKey] = value
    }
    
    func getValue(forKey: String) -> String? {
        return keychain[forKey]
    }
}
