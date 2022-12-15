//
//  EchdSettingsService.swift
//  AreaSight
//
//  Created by Emin A. Alekperov on 20.09.2021.
//  Copyright © 2021 Netris. All rights reserved.
//

protocol SettingsServiceProtocol: AnyObject {
    var authDelegate: SettingsServiceAuthDelegateProtocol? { get set }
    var settingsDelegate: SettingsServiceDelegateProtocol? { get set }
    var settings: SettingsEntity? { get set }
    var echdRegions: [EchdRegion]? { get set }
    var sessionInstanceId: Int { get }
    
    func requestSettings(_ callback: @escaping ([String: Any?]?,_ error: Error?) -> Void)
    func updateSettings()
    func stop()
    func getCameraRouteMain() -> [Int]?
}

protocol SettingsServiceDelegateProtocol: class {
    func handle(settings: SettingsEntity)
    func handle(error: NSError)
}

protocol SettingsServiceAuthDelegateProtocol: class {
    func auth(error: NSError)
    func connected()
}

enum UserPermissions: String {
    case makeScreenshot = "PrintScr-Cameras"
    case seeArchiveVideo = "SeeArchiveVideo"
    case createCameraAppeals = "Create-Camera-Complaint"
    case shareVideoLinksGenerating = "The-ability-to-generate-links"
    // This permissions have different sources: ECHD and SUDIR.
    // But they have the same meaning
    case allowChangePassword = "passwordChangeAllowed"
    case changePassword = "ChangePassword"
    case allowDisableAdmixture = "View-VideoWithoutMixin"
    case allowedMultilogin = "Access-Multilogin"
}

class EchdSettingsService {
    internal static let instance = EchdSettingsService()
    
    private var settingsRequest: EchdSettingsRequest?
    
    var settings: SettingsEntity?
    var settingsJSON: [String: Any?]?
    var userPermissions: [String]?
    var echdRegions: [EchdRegion]?
    var sessionInstanceId: Int = 0
    var securityMarker: String?
    // TODO: Replace by instance of UserPermissions
    var allowDisableAdmixture: Bool = false
    // TODO: Replace by instance of UserPermissions
    var allowedMultilogin: Bool = false
    
    weak var authDelegate: SettingsServiceAuthDelegateProtocol?
    weak var settingsDelegate: SettingsServiceDelegateProtocol?
    
    private init() {}
        
    internal func requestSettings(_ callback: @escaping ([String: Any?]?,_ error: Error?) -> Void) {
        settingsRequest = EchdSettingsRequest()
        settingsRequest?.request(fail: { error in
            callback(nil, error)
            self.settingsDelegate?.handle(error: error as NSError)
        }, success: { (code, response) in
            let settings = self.processSettings(response)
            
            self.settingsDelegate?.handle(settings: settings)
            
            callback(response, nil)
        })
    }
    
    private func processSettings(_ settings: [String: Any?]) -> SettingsEntity {
        self.settingsJSON = settings
        
        var profile = UserProfileEntity()
        
        if let environment = settings["environment"] as? [String:AnyObject] {
            if let instanceId = environment["instanceId"] as? Int {
                self.sessionInstanceId   = instanceId
            }
            
            if let userProfile = environment["userProfile"] as? [String: AnyObject] {
                if let securityMarker = userProfile["securityMarker"] as? String {
                    self.securityMarker = securityMarker
                }
                
                if let roles = userProfile["roles"] as? [String] {
                    allowDisableAdmixture = roles.contains("View-VideoWithoutMixin")
                    if allowDisableAdmixture {
                        profile.permissions.append(.allowDisableAdmixture)
                    }
                    
                    allowedMultilogin = roles.contains("Access-Multilogin")
                    if allowedMultilogin {
                        profile.permissions.append(.allowedMultilogin)
                    }
                    
                    if roles.contains("ChangePassword") {
                        profile.permissions.append(.changePassword)
                    }
                }
                
                if let permissions = userProfile["permissions"] as? [String: AnyObject] {
                    let allow: Bool = (permissions["passwordChangeAllowed"] as? Bool) ?? false
                    
                    if allow {
                        profile.permissions.append(.allowChangePassword)
                    }
                }

                if let username = userProfile["username"] as? String {
                    profile.username = username
                }
            }

            EchdFiltersService.instance.initData(data: environment)
            
            if let aggr = environment["aggregateOptions"] as? [String: AnyObject] {
                EchdAgregationSettings.sharedInstance.initData(aggr)
            }
        }
        
        self.settings = SettingsEntity(profile: profile)
        
        return self.settings!
    }
    
    // MARK: - EchdConnectionManagerSettingsDelegate
    func echdConnectionManagerSettings(_ sender: EchdConnectionManager, settings: SettingsEntity?, error: Error?) {
        
    }
}

// MARK: - SettingsProtocol
extension EchdSettingsService: SettingsServiceProtocol {

    func stop() {
        settingsRequest?.cancel()
        settingsRequest = nil
    }
    
    internal func updateSettings() {
        // This is a workaround for returning 201 in beat requests when user permissions are changed:
        let echdGetRootRequest = EchdGetRootRequest()
        echdGetRootRequest.request(fail: { error in
            self.authDelegate?.auth(error: error as NSError)
        }, success: { (code, result) in
            self.requestSettings() {(_ data: Any?, _ error: Error?) in
                if let error = error as NSError?, error.code == 401 {
                    self.authDelegate?.auth(error: error)
                } else {
                    if let json = (data as? [String: Any])?["environment"] as? [String: Any] {
                        if let user = json["userProfile"] as? [String: Any],
                            let roles = user["roles"] as? [String] {
                            self.userPermissions = roles
                        }
                        if let filters = json["filters"] as? [String: Any],
                            let districts = filters["districts"] as? [String: Any] {
                            var regions: [EchdRegion] = []
                            districts.forEach { (arg) in
                                let (_, value) = arg
                                if let region = EchdRegion(value) {
                                    regions.append(region)
                                }
                            }
                            
                            self.echdRegions = regions
                        }
                    }
                    
                    self.authDelegate?.connected()
                }
            }
        })
    }

    internal func getCameraRouteMain() -> [Int]? {
        guard let settings = self.settingsJSON else { return nil }
        guard let user = settings["user"] as? [String: Any?] else { return nil }
        guard let cameras = user["camera-route-main"] as? String else { return nil }
        guard let camerasData = cameras.data(using: .utf8) else { return nil }
        
        do {
            let json = try JSONSerialization.jsonObject(with: camerasData, options: .allowFragments)
            if let arr = json as? [Int] {
                return arr
            } else if let arr = json as? [String] {
                return arr.compactMap { Int($0) }
            }
        } catch {
            debugPrint("EchdSettingsService::getCameraRouteMain: \(error)")
        }
        
        return nil
    }
}
