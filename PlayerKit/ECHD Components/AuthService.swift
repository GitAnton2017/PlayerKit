//
//  AuthService.swift
//  AreaSight
//
//  Created by Emin Alekperov on 29.11.2019.
//  Copyright © 2019 Netris. All rights reserved.
//

import LocalAuthentication

protocol AuthServiceProtocol: AnyObject {
    func changeUser()
    func getUsersNum(withPincode: Bool) -> UInt
    func getUsersLocalAuthData() -> [LocalAuthData]
    func getCredentials(for loginHash: String?) -> Credentials?
    func removeAll()
    @discardableResult
    func removePicode(for loginHash: String?) -> Bool
    @discardableResult
    func save(pincode: String?, for loginHash: String?) -> Bool
    func getActiveUserLocalAuthData() -> LocalAuthData?
    func getAcitveUserServerAuthData() -> ServerAuthData?
    @discardableResult
    func set(activeUser loginHash: String?) -> Bool
    @discardableResult
    func save(biometryType: BiometryType, for loginHash: String?) -> Bool
    func invalidate()
    func checkBiometryType() -> (success: Bool, error: Error?, type: BiometryType)
    func getBiometryType(localizedReason: String, complete: @escaping (Bool, BiometryType, Error?) -> Void) -> Void
    @discardableResult
    func saveSession(with sessionId: String, and token: String, for loginHash: String?) -> Bool
    @discardableResult
    func update(sessionId: String, for loginHash: String?) -> Bool
    @discardableResult
    func update(token: String, for loginHash: String?) -> Bool
    func createNewUser(login: String?, password: String?) -> String?
    @discardableResult
    func update(password: String?, for login: String?) -> Bool
    @discardableResult
    func update(username: String?, for loginHash: String?) -> Bool
    @discardableResult
    func update(isNew: Bool, for loginHash: String?) -> Bool
    func check(login: String) -> String?
    
    //MARK: - Sudir
    
    func getActiveSudirUserUid() -> String?
    func getActiveSudirUserAuthorizationType() -> String?
}

class AuthService {
    internal static let instance = AuthService()
    
    private let keychainService: EchdKeychainServiceProtocol =  EchdKeychainService.sharedInstance
    
    private init() {}
    
    private func check(loginHash: String?) -> String? {
        if let login = loginHash {
            return login
        } else if let activeUserLogin = keychainService.getActiveUser() {
            return activeUserLogin
        } else {
            return nil
        }
    }
    
    private func getActiveSudirUserLoginComponents() -> [String]? {
        let user = getAcitveUserServerAuthData()
        let userLoginComponents = user?.login.components(separatedBy: " ")
        return userLoginComponents
    }
}

extension AuthService: AuthServiceProtocol {
    
    @discardableResult
    func update(sessionId: String, for loginHash: String?) -> Bool {
        if let login = check(loginHash: loginHash) {
            return keychainService.update(sessionId: sessionId, for: login)
        } else {
            return false
        }
    }
    
    @discardableResult
    func update(token: String, for loginHash: String?) -> Bool {
        if let login = check(loginHash: loginHash) {
            return keychainService.update(token: token, for: login)
        } else {
            return false
        }
    }
    
    @discardableResult
    func saveSession(with sessionId: String, and token: String, for loginHash: String?) -> Bool {
        if let login = check(loginHash: loginHash) {
            return keychainService.set(credentials: Credentials(token: token, sessionId: sessionId), for: login)
        } else {
            return false
        }
    }
    
    func getUsersLocalAuthData() -> [LocalAuthData] {
        return keychainService.getUsersLocalAuthData()
    }

    func getCredentials(for loginHash: String?) -> Credentials? {
        if let login = check(loginHash: loginHash) {
            return keychainService.getCredentials(for: login)
        } else {
            return nil
        }
    }
    
    @discardableResult
    func update(password: String?, for login: String?) -> Bool {
        guard let login = login else { return false }
        
        guard let loginHash = keychainService.getHash(for: login)  else { return false }

        return keychainService.update(password: password ?? "", for: loginHash)
    }
    
    @discardableResult
    func update(username: String?, for loginHash: String?) -> Bool {
        if let login = check(loginHash: loginHash) {
            return keychainService.update(username: username ?? "", for: login)
        } else {
            return false
        }
    }
    
    @discardableResult
    func update(isNew: Bool, for loginHash: String?) -> Bool {
        if let login = check(loginHash: loginHash) {
            return keychainService.update(isNew: isNew, for: login)
        } else {
            return false
        }
    }

    func createNewUser(login: String?, password: String?) -> String? {
        guard let login = login else { return nil }
        
        let hash = keychainService.getHash(for: login)
        
        guard let loginHash = hash else { return nil }
        
        if keychainService.contains(loginHash: loginHash) {
            return loginHash
        }

        keychainService.addUser(withLogin: loginHash)
        keychainService.set(serverAuthData: ServerAuthData(login: login, password: password ?? ""),
                            for: loginHash)
        keychainService.set(localAuthData: LocalAuthData(isNew: true, username: "", loginHash: loginHash,
                                                         pincode: "", biometryType: .none))

        return loginHash
    }
    
    @discardableResult
    func save(pincode: String?, for loginHash: String?) -> Bool {
        if let login = check(loginHash: loginHash) {
            return keychainService.update(pincode: pincode, for: login)
        } else {
            return false
        }
    }

    func changeUser() {
        keychainService.removeActiveUser()
    }
    
    func getUsersNum(withPincode: Bool) -> UInt {
        return keychainService.getUsersLocalAuthData().reduce(into: 0) { (result: inout UInt , localAuthData: LocalAuthData) in
            if localAuthData.pincode.isEmpty { return }
            
            /*
            How everything on the sudir side will work and decide to return the "select an account" button for sudir, delete this sudir users check
            */
            let appDefaults = AppDefaults.sharedInstance
            if let sudirUsers = appDefaults.getValue(appDefaults.APP_DEFAULTS_SUDIR_USERS) as? [String] {
                if sudirUsers.contains(localAuthData.username) { return }
            }
            
            result += 1
        }
    }

    func removeAll() {
        keychainService.removeAll()
    }
    
    func removeActiveUser() {
        keychainService.removeActiveUser()
    }
    
    @discardableResult
    func removePicode(for loginHash: String?) -> Bool {
        if let login = check(loginHash: loginHash) {
            return keychainService.removePincode(for: login)
        } else {
            return false
        }
    }
    
    @discardableResult
    func set(activeUser loginHash: String?) -> Bool {
        guard let login = loginHash else { return false }
        
        keychainService.set(activeUser: login)
        
        return true
    }
    
    func check(login: String) -> String? {
        guard let loginHash = keychainService.getHash(for: login) else { return nil }
        
        return (keychainService.contains(loginHash: loginHash) ? loginHash : nil)
    }
    
    func getActiveUserLocalAuthData() -> LocalAuthData? {
        if let loginHash = keychainService.getActiveUser() {
            return keychainService.getLocalAuthData(for: loginHash)
        } else {
            return nil
        }
    }
    
    func getAcitveUserServerAuthData() -> ServerAuthData? {
           if let loginHash = keychainService.getActiveUser() {
               return keychainService.getServerAuthData(for: loginHash)
           } else {
               return nil
           }
       }
    
    func save(biometryType: BiometryType, for loginHash: String?) -> Bool {
        if let login = check(loginHash: loginHash) {
            return keychainService.update(biometryType: biometryType, for: login)
        } else {
            return false
        }
    }
    
    func invalidate() {
        LAContext().invalidate()
    }
    
    func checkBiometryType() -> (success: Bool, error: Error?, type: BiometryType) {
        let laContext = LAContext()
                
        var authError: NSError?
        guard laContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) else {
            if let error = authError {
                debugPrint("AuthService::checkBiometryPermissions: \(error)")
            }
            
            return (false, authError, BiometryType.no)
        }
        
        var  type: BiometryType!
        switch laContext.biometryType {
        case .faceID:
            type = BiometryType.face
        case .touchID:
            type = BiometryType.touch
        case .none:
            type = BiometryType.none
         @unknown default:
          break
        }
        
        return (true, nil, type)
    }
    
    func getBiometryType(localizedReason: String, complete: @escaping (Bool, BiometryType, Error?) -> Void) -> Void {
        let laContext = LAContext()
        
        var authError: NSError?
        guard laContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) else {
            if let error = authError {
                debugPrint("AuthService::checkBiometryPermissions: \(error)")
            }
            
            complete(false, .no, authError)
            
            return
        }
        
        laContext.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                 localizedReason: localizedReason) { (success: Bool, evaluateError: Error?) -> Void in
                                    
                                    guard success else {
                                        complete(false, .none, evaluateError)
                                        return
                                    }

                                    switch laContext.biometryType {
                                    case .faceID:
                                        complete(true, .face, evaluateError)
                                    case .touchID:
                                        complete(true,.touch, evaluateError)
                                    case .none:
                                        complete(true, .none, evaluateError)
                                     @unknown default:
                                      break
                                    }
        }
    }
    
    // MARK: - Sudir
    
    func getActiveSudirUserAuthorizationType() -> String? {
        let activeSudirUserLoginComponents = getActiveSudirUserLoginComponents()
        return activeSudirUserLoginComponents?.first
    }
    
    func getActiveSudirUserUid() -> String? {
        let activeSudirUserLoginComponents = getActiveSudirUserLoginComponents()
        return activeSudirUserLoginComponents?.last
    }
}
