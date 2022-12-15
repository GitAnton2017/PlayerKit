//
//  EchdConnectionManager.swift
//  NetrisSVSM
//
//  Created by netris on 27.04.16.
//  Copyright © 2016 netris. All rights reserved.
//

import UIKit
import Alamofire
import LocalAuthentication

enum PtzCommand: String {
    case left = "H1"
    case right = "L1"
    case up = "K1"
    case down = "J1"
}

enum CameraFilters: String {
    case cameraStatuses
    case regions
    case districts
    case text
    case cameraTypes
    case cameras
}

internal struct AreaOfGetCameraList {
    var x: Int
    var y: Int
    var zoom: Int
    var left: Double
    var top: Double
    var right: Double
    var bottom: Double
    
    init(x: Int = 0,
         y: Int = 0,
         zoom: Int,
         left: Double = 0,
         top: Double = 0,
         right: Double = 0,
         bottom: Double = 0) {
        
        self.x = x
        self.y = y
        self.zoom = zoom
        self.left = left
        self.top = top
        self.right = right
        self.bottom = bottom
    }
    
    func getParameters() -> [String: Any] {
        var parameters: [String: Any] = [:]
        
        if 9...10 ~= zoom {
            parameters["x"] = nil
            parameters["y"] = nil
            parameters["left"] = nil
            parameters["right"] = nil
            parameters["top"] = nil
            parameters["bottom"] = nil
        } else {
            parameters["x"] = x
            parameters["y"] = y
            parameters["left"] = Float(Int(left * 1000)) * 0.001
            parameters["top"] = Float(Int(top * 1000)) * 0.001
            parameters["right"] = Float(Int(right * 1000)) * 0.001
            parameters["bottom"] = Float(Int(bottom * 1000)) * 0.001
        }
        
        parameters["zoom"] = zoom
        
        return parameters
    }
}

struct EchdConnectionManagerCredential {
    var host: String?
    var cookie: String?
}

internal enum EchdConnectionManagerStatus{
    case none
    case connecting
    case connected
    case interrupted
    case stopped
    case testing
    case error(error: NSError)
}

internal enum EchdConnectionManagerError: Error {
    case none
    case authorization
    case keepAlive
    case keepSettings
    case noVSS
    case noVSSControlURL
    case noPhotoShotURL
    case invalidPhotoShotData
    
}

internal enum EchdPortalAddress {
 
    case test
    case main
 
 
    
    var url:String {
        switch self {
        case .main:
            return AppContext.DefaultServerAddresses.main
        case .test:
            let changedServerAddress = UserDefaults.standard.value(forKey: AppDefaults.sharedInstance.APP_DEFAULTS_CHANGED_SERVER_ADDRESS) as? String
            if let serverAddress = changedServerAddress {
                return serverAddress
            } else {
                return AppContext.DefaultServerAddresses.test
            }
        }
    }
}

protocol EchdConnectionManagerDelegate: AnyObject {
    func echdConnectionManagerDidUpdateFilters()
    func echdConnectionManagerLogout()
    func echdTimeOutForBackgroundMode()
    func echdConnectionManagerDidUpdateRegion(region: Int, status: Bool)
    func echdConnectionManagerToggleRegions(to: Bool)
}

protocol EchdConnectionManagerAuthorizationDelegate: AnyObject {
    func saveAuthData(sessionId: String?, token: String?)
    func echdConnectionManagerStatus(status: EchdConnectionManagerStatus)
}

protocol EchdConnectionManagerUserPermissionsDelegate: AnyObject {
    func userPermissionsChanged(reason: String?)
}

@objc internal protocol EchdConnectionManagerCameraSearchDelegate: AnyObject {
    func echdConnectionCameraSearchManager(_ sender: EchdConnectionManager,
                                           searchCameraList: [EchdSearchCamera], error:Error?)
    
    @objc optional func echdConnectionCameraSearchManager(_ sender: EchdConnectionManager, searchCameraCount: Int, error: Error?)
}

protocol EchdConnectionManagerCameraDelegate: AnyObject {
    func echdConnectionCameraManager(_ sender: EchdConnectionManager, camera:AnyObject?, error:NSError?)
}

protocol EchdCameraManipulationDelegate: AnyObject {
    func success()
    func failed(with message: String)
}

protocol NoticesDemonstrator: AnyObject {
    func offerToUserNotices(_ notices: [EchdNotice])
}


internal final class EchdConnectionManager: NSObject, EchdServerTimeServiceDelegate {
 
    static let sharedInstance = EchdConnectionManager()
    
    static let defaultBeatInterval = TimeInterval(integerLiteral: 15)
    static let defaultNoticeInterval = TimeInterval(integerLiteral: 60)

    weak var delegate: EchdConnectionManagerDelegate?
    weak var cameraSearchDelegate: EchdConnectionManagerCameraSearchDelegate?
    weak var cameraDelegate:EchdConnectionManagerCameraDelegate?
    weak var cameraManipulationDelegate: EchdCameraManipulationDelegate?
    weak var noticesDemonstrator: NoticesDemonstrator?
    weak var authDelegate: EchdConnectionManagerAuthorizationDelegate?
    weak var permissionsDelegate: EchdConnectionManagerUserPermissionsDelegate?
    
    var alamofireManager: Session = {
        let urlSessionConfig = URLSessionConfiguration.default
        urlSessionConfig.timeoutIntervalForResource = Time.timeoutForRequests
        urlSessionConfig.timeoutIntervalForRequest = Time.timeoutForRequests
        urlSessionConfig.waitsForConnectivity = true
        urlSessionConfig.urlCache = nil
        urlSessionConfig.requestCachePolicy = .reloadIgnoringLocalCacheData
        let manager = Alamofire.Session(configuration: urlSessionConfig)
        
        return manager
    }()
    
    let routeCamerasLimit = 1000
    var lastServerTime: Int = 0
    
    fileprivate var status: EchdConnectionManagerStatus = .none

    // MARK: - Properties.Services:

    internal var keepAliveService: EchdKeepAliveService?
 
 
    private var keepAliveServicePayload: Payload?
    var noticeService: EchdNoticeService?
    var echdEgipSettings: EchdEgipSettings?
    var serverTimeService: EchdServerTimeService?
    var makeVideoArchiveService: EchdMakeVideoArchiveServiceProtocol?
    var makeShareLinkOfCameraService: EchdMakeShareLinkOfCameraSeviceProtocol?
    var filtersService: EchdFiltersServiceProtocol?
    var currentPresentingNotificationBar: SmallNotificationBar?
    var settingsService: SettingsServiceProtocol?
    
    // MARK: - Properties.Settings:

    private(set) var allowedMultilogin: Bool = false
    private var isInited = false
    private var interruptionTimer: Timer?
    
    var host: String?

    var beatInterval: TimeInterval? {
        didSet {
            keepAliveService?.stop()
            
            if let interval = beatInterval {
                keepAliveService?.start(beatInterval: interval)
            }
        }
    }
    var noticeInterval: TimeInterval? {
        didSet {
            noticeService?.stop()
            noticeService?.start()
        }
    }
    
    // MARK: - Properties.Requests:

    var authRequest                         : EchdAuthorizationRequest?
    internal var cameraRequest                : EchdCameraRequest?
    var presetsRequest                      : EchdPresetsRequest?
    var cameraSearchRequest                 : EchdSearchCameraListRequest?
    var cameraSearchCountRequest            : EchdSearchCameraCountRequest?
    internal var archiveControlsRequest       : EchdArchiveControlsRequest?
    internal var photoRequest                 : EchdMakePhotoRequest?
 
    internal var archiveShotsPrefetchRequest  : [AbstractRequest] = []
 
    var logoutRequest: EchdLogoutRequest?

    internal var echdPortalAddress: EchdPortalAddress {
        var address = EchdPortalAddress.main
        
        #if PROFILE_TEST
        address = .test
        #endif
        
        return address
    } 

    // TODO: Move to the RouteCamerasService
    private var routeCameras: [EchdSearchCamera] = [] {
        didSet {
            routeCamerasDidChange = true
        }
    }
    var routeCamerasDidChange = false
    
    var echdNotices: [EchdNotice]? {
        didSet {
            // Show to user non-checked notices at begin of the app using:
            if oldValue == nil, let notices = echdNotices {
                determineNonCheckedNotices(notices)
            }
        }
    }
    
    var echdRegions: [EchdRegion]?
    
    // MARK: - Lifecycle
    
    private override init() {
        super.init()
        
        host = echdPortalAddress.url
        makeVideoArchiveService = EchdMakeVideoArchiveService()
        makeShareLinkOfCameraService = EchdMakeShareLinkOfCameraSevice()
        settingsService = EchdSettingsService.instance
        
        filtersService = EchdFiltersService.instance
        
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    var timeWhenSendToBackgroud: Date?
    
    @objc
    private func appMovedToBackground() {
        timeWhenSendToBackgroud = Date()
    }
    
    @objc
    private func appMovedToForeground() {
        guard let timeWhenSendToBackgroud = timeWhenSendToBackgroud else { return }
        
        let interval = Date().timeIntervalSince(timeWhenSendToBackgroud)
        if interval > Time.timeAvailableToBackgroundState {
            delegate?.echdTimeOutForBackgroundMode()
            stop()
        }
    }
    
    // MARK: - Main methods
    
    @discardableResult
    internal func initManager() -> Bool {
        guard !isInited else { return false }

        self.setDefaultIntervals()
        self.startNoticesService()
        self.startKeepAliveService()
        self.startServerTimeService()
        self.isInited = true
        
        return true
    }
    
    internal func getFilteredRouteCameras() -> [EchdSearchCamera] {
        guard let filter = filtersService,
            filter.filterIsOn() else { return routeCameras }

        return getFilteredRouteCameras(cameras: routeCameras, filter: filter.makeParameters())
    }
    
    internal func getCookie() -> String? {
        let user = AuthService.instance.getCredentials(for: nil)
        
        //TODO: Move to the "AbstractRequest" class
        var summaryCookie = ""
        if let jsessionId = user?.sessionId {
            summaryCookie = "JSESSIONID=\(jsessionId);"
        }
        
        if let grailsRememberMe = user?.token {
            summaryCookie += "grails_remember_me=\(grailsRememberMe);"
        }
        
        return summaryCookie.isEmpty ? nil : summaryCookie
    }
    
    private func start(parameters: [String: Any]) {
        authDelegate?.echdConnectionManagerStatus(status: .connecting)
        
        authRequest = EchdAuthorizationRequest(parameters: parameters)
        authRequest?.request(
            fail: { [weak self] (error) in
                guard let self = self else { return }
                
                let nsError = error as NSError
                self.authDelegate?.echdConnectionManagerStatus(status: .error(error: nsError))
                self.authRequest = nil
            },
            success: { [weak self] (login, cookie, grailsRememberMeToken) in
                guard let self = self else { return }

                self.authDelegate?.saveAuthData(sessionId: cookie,
                                                token: grailsRememberMeToken)
        })
        
    }

    private func setRouteCameras(_ cameras: [EchdSearchCamera], routeCamerasIndices: [Int]?, isAppending: Bool = false) {
        if let array = routeCamerasIndices {
            var added: [Int] = []
            var newArray = isAppending ? routeCameras : []
            newArray = newArray + array.compactMap( { object in
                return cameras.first(where: { cam in
                    guard !added.contains(object), // Проверка, не добавлена ли в новый массив камера
                        let id = cam.id else { return false }
                        if isAppending { // Если это расширение массива камер, то проверяем, нет ли такой камеры уже
                        guard !routeCameras.contains(where: { $0.id! == id }) else { return false }
                    }
                    
                    if id == object {
                        added.append(id)
                        return true
                    }
                    return false
                })
            })
            routeCameras = newArray
        }
    }
    
    private func startInterruptionTimer() {
        if interruptionTimer == nil {
            DispatchQueue.main.async {
                self.interruptionTimer = Timer.scheduledTimer(withTimeInterval: Time.timeoutForRequests, repeats: false, block: { [weak self] (timer) in
                    guard let self = self else { return }
                    self.removeUserConnection()
                    self.interruptionTimer?.invalidate()
                    self.interruptionTimer = nil
                })
            }
        }
    }
    
    private func stopInterruptionTimer() {
        interruptionTimer?.invalidate()
        interruptionTimer = nil
    }
        
    internal func reconnect() {
        authDelegate?.echdConnectionManagerStatus(status: EchdConnectionManagerStatus.connecting)
        
        self.status = .testing
        
        sendFirstBeat()
    }
    
    internal func stop() {
        stopKeepAliveService()
        stopNoticesService()
        stopServerTimeService()
        
        isInited = false
        
        authRequest?.cancel()
        authRequest = nil
    
        settingsService?.stop()
        
        self.status = .stopped
        
        authDelegate?.echdConnectionManagerStatus(status: .stopped)
    }
    
    internal func removeUserConnection() {
        removeAllRequests()
        requestLogout()
        
        delegate?.echdConnectionManagerLogout()
    }
    
    internal func pause() {
        stopNoticesService()
        stopKeepAliveService()
        stopServerTimeService()
    }
    
    internal func resume() {
        if getCookie() == nil {
            stop()
        }
        
        startNoticesService()
        startKeepAliveService()
        startServerTimeService()
    }
    
    internal func clear() {
        pause()
    }
    
    internal func setSessionId(_ sessionId: String) {
        AuthService.instance.update(sessionId: sessionId, for: nil)
    }
    
    internal func clearUserSettings() {
        if let appDomain = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: appDomain)
            UserDefaults.standard.synchronize()
            UserDefaults.standard.set(true, forKey: AppDefaults.sharedInstance.APP_DEFAULTS_HAS_RUN_BEFORE)
        }
    }
    
    internal func logoutUser() {
        clearUserSettings()
        removeUserConnection()
        EchdKeychainService.sharedInstance.removeAll()
    }
    
    internal func changeUser() {
        removeAllRequests()
        requestLogout()
        stop()
    }
    
    internal func removePreviousUserPreferences() {
        clearUserSettings()
        EchdKeychainService.sharedInstance.removeAll()
    }
    
    // MARK: - Requests
    
    internal func requestEgipMapSettings(callback: @escaping (EchdEgipSettings) -> Void) {
        if let settings = echdEgipSettings {
            callback(settings)
        } else {
            let request = EchdGetMapSettingsRequest()
            
            request.request(parameters: [:], fail: { error in }, success: { (code, result) in
                if code == 200,
                    let settings = EchdEgipSettings(result){
                    self.echdEgipSettings = settings
                    callback(settings)
                }
            })
        }
    }

    internal func requestRegionsBorders(_ completeHandler: @escaping ( ([EchdRegion]) -> Void ) ) {
        let request = EchdAreasRequest()
        var ids: [Int] = []
        
        guard let regions = settingsService?.echdRegions else { return }
        
        regions.forEach({ (reg) in
            ids.append(contentsOf: reg.geoDataId)
        })

        request.request(parameters: ["ids": ids], fail: { e in }, success: { (_,value) in

            guard let regionsJSON = value["result"] as? [String: [[[ (Double, Double) ]]]] else { return }

            let reg = regions.compactMap({ (region) -> EchdRegion? in
                region.geoDataId.forEach { (id) in
                    if let responseRegion = regionsJSON[String(id)] {
                        responseRegion.forEach { (item) in
                            region.coordinates?.append(item)
                        }
                    }
                }
                return region
            })
            
            
            completeHandler(reg)
        })

    }
    
    internal func requestCameraAudible(camera: EchdCamera, callback: @escaping (_ hasSound: Bool) -> Void) {
        let shotUrls = camera.getArchiveShotControl()
        
        guard let shotUrlPath = shotUrls?.first, let shotUrl = URL(string: shotUrlPath) else { return }
        
        let request = StreamInfoRequest(url: shotUrl)
        
        request.request(parameters: [:], fail: { (error) in
            callback(false)
            
        }, success: { (code, result) in
            var audible = false
            
            if let streams = result["streams"] as? [[String: Any?]] {
                
                for stream in streams {
                    if let mediaType = stream["mediaType"] as? String,
                        mediaType == "audio" {
                        audible = true
                    }
                }
            }
            
            callback(audible)
        })
    }
    
    internal func removeAllRouteCamerasRequest(callback:@escaping (_ success:Bool, _ error:Error?) -> ()) {
        requestSetRouteMain([], callback: { [weak self] (success, error)  in
            if success {
                self?.routeCameras.removeAll()
            }
            callback(success, error)
        })
    }

    internal func removeRouteCameraRequest(_ camera:EchdSearchCamera, routeCamerasIndices: [Int]?, callback:@escaping (_ success:Bool, _ error:Error?) -> ()) {
        if let cameras = routeCamerasIndices, let id = camera.id {
            var newCameras = [Int]()
            for item in cameras {
                if item != id {
                    newCameras.append(item)
                }
            }
            
            requestSetRouteMain(newCameras, callback: { [weak self] (success, error)  in
                if success {
                    let index = self?.routeCameras.firstIndex(where: {
                        guard let id = $0.id,
                            let camId = camera.id else { return false }
                        if id == camId {
                            return true
                        }
                        return false
                    })
                    if let index = index {
                        self?.routeCameras.remove(at: index)
                    }
                }
                callback(success, error)
            })
        }
    }
    
    internal func addRouteCameraRequest(_ camera: EchdSearchCamera, routeCamerasIndices: [Int]?, callback:@escaping (_ success:Bool, _ error:Error?) -> ()) {
        guard let id = camera.id else { return }
        var newCameras = [Int]()
        if let cameras = routeCamerasIndices {
            newCameras.append(contentsOf: cameras)
        }
        newCameras.append(id)
        requestSetRouteMain(newCameras, callback: { [weak self] (success, error) in
            if success,
                let contains = self?.routeCameras.contains(camera),
                !contains {
                self?.routeCameras.append(camera)
            }
            callback(success, error)
        })

    }
    
    private func requestSetRouteMain(_ cameras: [Int],
                                    callback: @escaping (_ success: Bool,_ error: Error?) -> Void) {
        
        let request = EchdSetUserSettingsRequest(list: cameras)
            request.request(fail: { error in
                callback(false, error)
            }, success: { (code, response) in
                if let success = response["success"] as? Bool {
                    
                    callback(success, nil)
                }
            })
    }

    internal func requestCameraMapList(area: AreaOfGetCameraList,
                                     responseReceiver: GetCameraListResponseReceiver ) -> [GetCameraListRequest] {
        
        var requests: [GetCameraListRequest] = []
        
        if let _ = getCookie(), let filtersService = filtersService {
            
            if area.zoom == 9 || area.zoom == 10 {
                let filterParametersInitial = filtersService.makeParameters()
                if let districts = filterParametersInitial["districts"] as? [Int], !districts.isEmpty {
                    for district in districts {
                        var areaParameters = area.getParameters()
                        var filterParameters = filtersService.makeParameters()
                        
                        if district != 18 {
                            filterParameters.removeValue(forKey: "districts")
                            filterParameters["district"] = district
                        }
                        
                        if district == 18 {
                            areaParameters["zoom"] = 8
                            filterParameters["districts"] = [18]
                            filterParameters["district"] = nil
                        }
                        
                        areaParameters.merge(filterParameters) { (_, new) in new }
                        let allFilters: [String: Any] = ["filter": areaParameters]
                        
                        let request = makeGetCameraListRequest(allFilters: allFilters, responseReceiver: responseReceiver)
                        requests.append(request)
                    }
                } else {
                    // No districts in filter:
                    
                    var areaParameters = area.getParameters()
                    let filterParameters = filtersService.makeParameters()
                    
                   areaParameters.merge(filterParameters) { (_, new) in new }
                    let allFilters: [String: Any] = ["filter": areaParameters]
                    
                    let request = makeGetCameraListRequest(allFilters: allFilters, responseReceiver: responseReceiver)
                    requests.append(request)
                }
            } else {
                // Zoom is not in 9,10
                
                var areaParameters = area.getParameters()
                let filterParameters = filtersService.makeParameters()
                
                 areaParameters.merge(filterParameters) { (_, new) in new }
                let allFilters: [String: Any] = ["filter": areaParameters]
                
                let request = makeGetCameraListRequest(allFilters: allFilters, responseReceiver: responseReceiver)
                requests.append(request)
            }
        }
        return requests
    }
    
    internal func requestCameras(_ cameraIdList: [Int], completion: @escaping (_ cameras: [EchdSearchCamera]?,_ error: Error?) -> Void) {
        let parameters: [String: Any] = ["filter": ["cameras": cameraIdList]]
        
        cameraSearchRequest = EchdSearchCameraListRequest()
        cameraSearchRequest?.request(parameters: parameters, fail: { error in
            completion(nil, error)
        }) { code, json in
            let res = EchdSearchCameraListResponse(data: json as [String : AnyObject])
            let cameras = res.cameras
            
            completion(cameras, nil)
        }
    }
    
    internal func requestCameraSearch(_ text: String = "",
                                    limit: Int,
                                    offset: Int,
                                    isHistory:Bool = false,
                                    isFavorite: Bool = false,
                                    isRoute: Bool = false,
                                    order: String = "",
                                    routeCamerasIndices: [Int]?,
                                    delegate: EchdConnectionManagerCameraSearchDelegate) {
        
        guard let filtersService = filtersService else { return }
        
        cameraSearchDelegate = delegate
        cameraSearchRequest?.cancel()
        cameraSearchRequest = nil
        
        var parameters: [String: Any] = [:]
        var filter = filtersService.makeParameters()
        filter["text"] = text
        
        if isRoute {
            if let routeCameras = routeCamerasIndices,
                !routeCameras.isEmpty {
                
                filter["cameras"] = routeCameras
            } else {
                self.cameraSearchDelegate?.echdConnectionCameraSearchManager(self, searchCameraList: [], error: nil)
                return
            }
        }
        
        if isHistory { filter["isHistory"] = isHistory }
        if isFavorite { filter["isFavorite"] = isFavorite }
        
        parameters["filter"] = filter
        parameters["limit"] = limit
        parameters["offset"] = offset
        
        cameraSearchRequest = EchdSearchCameraListRequest()
        cameraSearchRequest?.request(parameters: parameters, fail: { [weak self] error in
                guard let self = self else { return }
                
                self.cameraSearchDelegate?.echdConnectionCameraSearchManager(self, searchCameraList: [], error: error)
        }) { [weak self] (code, json) in
            guard let self = self else { return }
             
            let res = EchdSearchCameraListResponse(data: json as [String : AnyObject])
            var cameras = res.cameras
            
            if isRoute {
                let cams = self.getFilteredRouteCameras(cameras: cameras, filter: filter)
                self.setRouteCameras(cams, routeCamerasIndices: routeCamerasIndices, isAppending: offset != 0)
                cameras = self.routeCameras
            }
            self.cameraSearchDelegate?.echdConnectionCameraSearchManager(self, searchCameraList: cameras, error: nil)
        }
    }
    
    internal func requestSearchCameraCount(_ text: String,
                                         limit: Int,
                                         offset: Int,
                                         isHistory: Bool,
                                         isFavorite: Bool,
                                         isRoute: Bool = false,
                                         routeCamerasIndices: [Int]?,
                                         delegate: EchdConnectionManagerCameraSearchDelegate) {
        guard let filtersService = filtersService else { return }
        
        cameraSearchDelegate = delegate
        cameraSearchCountRequest?.cancel()
        cameraSearchCountRequest = nil
        
        var parameters: [String: Any] = [:]
        var filter = filtersService.makeParameters()
        filter["text"] = text
        
        if isRoute {
            if let routeCameras = routeCamerasIndices, !routeCameras.isEmpty {
                self.cameraSearchDelegate?.echdConnectionCameraSearchManager?(self, searchCameraCount: routeCameras.count, error: nil)
            } else {
                self.cameraSearchDelegate?.echdConnectionCameraSearchManager(self, searchCameraList: [], error: nil)
                self.cameraSearchDelegate?.echdConnectionCameraSearchManager?(self, searchCameraCount: 0, error: nil)
                return
            }
        }
        
        if isHistory { filter["isHistory"] = isHistory }
        if isFavorite { filter["isFavorite"] = isFavorite }
        
        parameters["filter"] = filter
        parameters["limit"] = limit
        parameters["offset"] = offset
        
        cameraSearchCountRequest = EchdSearchCameraCountRequest()
        cameraSearchCountRequest?.request(parameters: parameters, fail:
            {
                [weak self] error in
                
                guard let self = self else { return }
                
                self.cameraSearchDelegate?.echdConnectionCameraSearchManager?(self, searchCameraCount: 0, error: error)
        }) {
            [weak self] (code, json) in
            
            guard let self = self else { return }
            
            var camerasCount = 0
            
            if let count = json["count"] as? Int {
                camerasCount = count
            }
            
            self.cameraSearchDelegate?.echdConnectionCameraSearchManager?(self, searchCameraCount: camerasCount, error: nil)
        }
    }
    
    internal func stopRequestCameraSearch() {
        cameraSearchRequest?.cancel()
    }
    
    internal func requestPtzLeft(cameraId: String) {
        ptzMoveRequest(cameraId: cameraId, command: .left)
    }
    
    internal func requestPtzUp(cameraId: String) {
        ptzMoveRequest(cameraId: cameraId, command: .up)
    }
    
    internal func requestPtzRight(cameraId: String) {
        ptzMoveRequest(cameraId: cameraId, command: .right)
    }
    
    internal func requestPtzDown(cameraId: String) {
        ptzMoveRequest(cameraId: cameraId, command: .down)
    }
    
    internal func requestPtzHome(cameraId: String) {
        let toHome = EchdMoveCameraToHomePositionRequest(id: cameraId)
        
        toHome.request(fail: { error in
            self.cameraManipulationDelegate?.failed(with: error.localizedDescription)
        }, success: { (code, response) in
            if let success = response["success"] as? Bool,
                success {
                self.cameraManipulationDelegate?.success()
            } else {
                self.cameraManipulationDelegate?.failed(with: response["message"] as? String ?? "")
            }
        })
    }
    
    internal func requestPtzZoom(cameraId: String, plus: Bool) {
        let reqZoom = EchdMoveZoomRequest(id: cameraId, isZoomIn: plus)
        
        reqZoom.request(fail: { error in
            self.cameraManipulationDelegate?.failed(with: error.localizedDescription)
        }, success: { (code, response) in
            if let success = response["success"] as? Bool,
                success {
                self.cameraManipulationDelegate?.success()
            } else {
                self.cameraManipulationDelegate?.failed(with: response["message"] as? String ?? "")
            }
        })
    }
    
    internal func requestOneCameraSearch(_ text:String, callback:@escaping (JSONObject?, _ error:Error?) -> ()) {
        guard let filtersService = filtersService else { return }
        
        var parameters: [String: Any] = [:]
        var filter = filtersService.makeParameters()
        filter["text"] = text
        
        parameters["filter"] = filter
        parameters["limit"] = 1
        parameters["offset"] = 0
        
        let request = EchdSearchCameraListRequest()
        request.request(parameters: parameters, fail: { (error) in
            callback(nil, error)
        }) { (code, json) in
            callback(json as JSONObject, nil)
        }
    }
    
    internal func requestPhotoShot(_ url:String,
                                 camera: Int,
                                 _ callback: @escaping (_ camera: Int, _ data: Data?, _ error: Error?) -> Void) -> EchdMakePhotoRequest? {
        photoRequest = EchdMakePhotoRequest(url: url, camera: camera)
        photoRequest?.request(fail: { error in
            callback(camera, nil, error)
        }, success: { (code, response) in
            if let image = response["image"] as? Data {
                callback(camera, image, nil)
            } else {
                let userInfo: [String: Any] = [
                    NSLocalizedDescriptionKey :  "Изображение не было получено",
                    NSLocalizedFailureReasonErrorKey : ""
                ]
                let error = NSError(domain: "EchdConnectionManager::requestPhotoShot", code: 2003, userInfo: userInfo)
                callback(camera, nil, error)
            }
        })
        return photoRequest
    }
    
    internal func cancelRequestPhotoShot(){
        photoRequest?.cancel()
    }
        
    internal func requestPresets(_ callback: @escaping ([[String : Any]]?,_ error: NSError?) -> Void) {
        guard getCookie() != nil else {
            let cookieError = NSError(domain: "EchdConnectionManager::requestPresets", code: 401, userInfo:[
                NSLocalizedDescriptionKey: "",
                NSLocalizedFailureReasonErrorKey: "no_auth_data"
                ])
            
            debugPrint("EchdConnectionManager::requestPresets: \(cookieError)")
            
            handleKeepAliveError(error:cookieError)
            return
        }
        
        presetsRequest = EchdPresetsRequest()
        presetsRequest?.request(fail: { error in
            callback(nil, error as NSError)
        }, success: { (code, response) in
            if let presets = response["presets"] as? [[String: Any]] {
                callback(presets, nil)
            }
        })
    }
    
    @discardableResult
    internal func requestCamera(_ id: Int, callback: @escaping (AnyObject?, _ error:Error?) -> Void ) -> EchdCameraRequest? {
        guard getCookie() != nil else {
            let cookieError = NSError(domain: "EchdConnectionManager::requestCamera", code: 401, userInfo:[
                NSLocalizedDescriptionKey: "",
                NSLocalizedFailureReasonErrorKey: "no_auth_data"
                ])
            
            debugPrint("EchdConnectionManager::requestCamera: \(cookieError)")
            
            callback(nil, cookieError)
            
            return nil
        }
    
        //TODO: Remove a non-nil check
        let cameraRequest = EchdCameraRequest(cameraId: id, sessionInstanceId: settingsService?.sessionInstanceId ?? 0)
        
        DispatchQueue.global().async {
            cameraRequest.request(fail: { error in
                callback(nil, error)
            }) { (code, response) in
                callback(response as AnyObject, nil)
            }
        }
        
        return cameraRequest
    }
    
    internal func requestAddFavorite(_ camera:Int, callback: @escaping (_ camera: Int,_ success: Bool,_ error: Error?) -> Void) {

        guard getCookie() != nil else {
            let cookieError = NSError(domain: "EchdConnectionManager::requestAddFavorite", code: 401, userInfo:[
                    NSLocalizedDescriptionKey: "",
                    NSLocalizedFailureReasonErrorKey: "no_auth_data"
                ])
            
            debugPrint("EchdConnectionManager::requestAddFavorite: \(cookieError)")
            
            callback(-1, false, cookieError)
            
            return
        }
        
        let addFavoriteRequest = EchdAddToFavoriteRequest(camera: camera)
        
        addFavoriteRequest.request(fail: { error in
            callback(camera, false, error)
        
        }) { (code, response) in
            if let success = response["success"] as? Bool {
                callback(camera, success, nil)
            }
        }
    }
    
    internal func requestRemoveFavorite(_ camera:Int, callback:@escaping (_ camera:Int, _ ok:Bool, _ error:Error?) -> ()) {
        guard getCookie() != nil else {
            let cookieError = NSError(domain: "EchdConnectionManager::requestRemoveFavorite", code: 401, userInfo:[
                    NSLocalizedDescriptionKey: "",
                    NSLocalizedFailureReasonErrorKey: "no_auth_data"
                ])
            
            debugPrint("EchdConnectionManager::requestRemoveFavorite: \(cookieError)")
            
            callback(-1, false, cookieError)
            
            return
        }
        
        let removeFavoriteRequest = EchdRemoveFromFavoriteRequest(camera: camera)
        removeFavoriteRequest.request(fail: { error in
            callback(camera, false, error)
        }) { (code, response) in
            guard let success = response["success"] as? Bool else {
                callback(camera, false, nil)
                return
            }
            
            callback(camera, success, nil)
        }
    }
    
    internal func requestLogout() {
        logoutRequest = EchdLogoutRequest()
        logoutRequest?.request(parameters: [:], fail: { error in
            debugPrint("EchdConnectionManager::requestLogout: Error: \(error.localizedDescription)")
        }, success: { (_, _)  in
            self.clear()
        })
    }

    internal func requestArchiveControls(_ url:String, callback: @escaping (AnyObject?, _ error: NSError?) -> Void) {
        guard getCookie() != nil else {
            let cookieError = NSError(domain: "EchdConnectionManager::requestArchiveControls", code: 401, userInfo:[
                NSLocalizedDescriptionKey: "",
                NSLocalizedFailureReasonErrorKey: "no_auth_data"
                ])
            
            debugPrint("EchdConnectionManager::requestArchiveControls: \(cookieError)")
            
            callback(nil, cookieError)
            
            return
        }

        archiveControlsRequest = EchdArchiveControlsRequest(url: url)
        archiveControlsRequest?.request(fail: { error in
            callback(nil, error as NSError)
        }, success: { (code, response) in
            callback(response as AnyObject, nil)
        })
    }
    
    internal func requestRouteCameras(routeCamerasIndices: [Int]?) {
        requestCameraSearch("", limit: routeCamerasLimit, offset: 0, isHistory: false, isFavorite: false, isRoute: true, order: "", routeCamerasIndices: routeCamerasIndices, delegate: self)
    }
    
    /// Make a request for route's cameras and write it to routeCameras variable
    /// - Author: Ruslan Utashev
    /// - Parameter id: Ids of required cameras
    internal func requestRouteCameras(_ id: [Int]) {
        self.cameraSearchRequest = EchdSearchCameraListRequest()
        self.cameraSearchRequest?.request(parameters: ["filter": ["cameras": id]], fail: {_ in}) {
            [weak self] (code, response) in
            guard let cams = response["cameras"] as? [[String: Any]] else { return }
            
            self?.setRouteCameras( cams.map { item in
                return EchdSearchCamera(data: item as JSONObject)
            }, routeCamerasIndices: self?.settingsService?.getCameraRouteMain())
        }
    }
    
    // MARK: - Making video archive order interface :
    
    internal func requestMakeOrderForVideoArchive(forCameraID Id: Int,
                                         beginDate: Int,
                                         endDate: Int,
                                         reason: String,
                                         callback: @escaping (_ archiveOrder: VideoArchiveOrderInfo?,_ videoArchiveOrderMessage: VideoArchiveOrderMessage? , _ error: Error?) -> Void) {
        
        let managerCredential = EchdConnectionManagerCredential(host: self.host,
                                                                cookie: getCookie())
    
        makeVideoArchiveService?.requestMakeOrderForVideoArchive(managerCredential: managerCredential,
                                                                 cameraId: Id,
                                                                 beginDate: beginDate,
                                                                 endDate: endDate,
                                                                 reason: reason,
                                                                 completion: { (videoArchiveInfo, videoArchiveOrderMessage, error)  in
                                                                    if let error = error {
                                                                        callback(nil, nil, error)
                                                                    }
                                                                    callback(videoArchiveInfo, videoArchiveOrderMessage, nil) })
        
    }
    
    internal func getCameraVideoArchiveOrderMinMaxDates ( cameraId: Int,
                                                 completion: @escaping((TimeLimit?, Error?) -> Void)) {
        
        let managerCredential = EchdConnectionManagerCredential(host: self.host,
                                                                cookie: getCookie())
        
        makeVideoArchiveService?.getCameraVideoArchiveOrderMinMaxDates(managerCredential: managerCredential,
                                                                       cameraId: cameraId,
                                                                       completion: { (timeLimit, error) in
                                                                        completion(timeLimit, error)
        })
    }
    
    internal func getShareLiveVideoLinkOfCamera(withId id: Int, completion: @escaping(( String?, Error? ) -> Void) ) {
        let managerCredential = EchdConnectionManagerCredential(host: self.host,
                                                                cookie: getCookie())
        
        makeShareLinkOfCameraService?.makeShareLiveVideoLinkOfCamera(managerCredential: managerCredential, cameraId: id, completion: { (shareLink, error) in
            guard error == nil else {
                completion(nil, error)
                return
            }
            
            completion(shareLink, nil)
        })
    }
    
    internal func getShareAchiveVideoLinkOfCamera(withId id: Int, dateInSeconds: Int, completion: @escaping(( String?, Error? ) -> Void) ) {
        let managerCredential = EchdConnectionManagerCredential(host: self.host,
                                                                cookie: getCookie())
        
        makeShareLinkOfCameraService?.makeShareArchiveVideoLinkOfCamera(managerCredential: managerCredential, cameraId: id, dateInSeconds: dateInSeconds, completion: { (shareLink, error) in
            guard error == nil else {
                completion(nil, error)
                return
            }
            
            completion(shareLink, nil)
        })
    }
    
    internal func startKeepAliveService() {
        if let _ = host, let _ = getCookie() {
            if keepAliveService == nil {
                //TODO: Remove a non-nil check
                keepAliveService = EchdKeepAliveService(delegate: self, sessionInstanceId: settingsService?.sessionInstanceId ?? 0)
            }
            
            // Set old payload when app goes from background:
            if let oldPayload = keepAliveServicePayload {
                keepAliveService?.payload = oldPayload
                keepAliveServicePayload = nil
            }
        } else {
            debugPrint("EchdConnectionManager::startKeepAliveService: Can't start (host: \(String(describing: host)); cookie: \(String(describing: getCookie())))")
        }
        
        keepAliveService?.start(beatInterval: beatInterval ?? EchdConnectionManager.defaultBeatInterval)
    }
    
    internal func sendFirstBeat() {
        guard let _ = host else {
            handleKeepAliveError(error: NSError(domain: "EchdConnectionManager::sendFirstBeat", code: 412, userInfo: nil))
            return
        }
        
        if keepAliveService == nil {
            //TODO: Remove a non-nil check
            keepAliveService = EchdKeepAliveService(delegate: self, sessionInstanceId: settingsService?.sessionInstanceId ?? 0)
        }
        
        // Set old payload when app goes from background:
        if let oldPayload = keepAliveServicePayload {
            keepAliveService?.payload = oldPayload
            keepAliveServicePayload = nil
        }
        
        keepAliveService?.sendSingleBeat()
    }
    
    internal func getConnectionStatus() -> EchdConnectionManagerStatus {
        return status
    }

    func echdCameraRequest(_ sender: EchdCameraRequest, id: String, camera: AnyObject?, error: NSError?) {
        cameraDelegate?.echdConnectionCameraManager(self, camera: camera, error: error)
    }

    func echdServerTimeService(_ sender: EchdServerTimeService, time: Int) {
        self.lastServerTime = time
    }

    func echdServerTimeService(_ sender: EchdServerTimeService, status: EchdServerTimeServiceStatus) {
        
    }
    
    internal func determineNonCheckedNotices(_ notices: [EchdNotice]) {
        let nonCheckedNotices = notices.filter {
            $0.checked! == false
        }
        
        if !nonCheckedNotices.isEmpty {
            noticesDemonstrator?.offerToUserNotices(nonCheckedNotices)
        }
    }
    
    internal func makeErrorText(for error: NSError) -> (title: String, message: String) {
        var textOfError = AlertMessages.failedToConnect.localized + ".\n"
        var titleOfError = AlertTitles.error.localized

        if let message = error.localizedFailureReason {
            textOfError = message
        } else if let descriptionKey = error.userInfo[NSLocalizedDescriptionKey] as? String {
             textOfError += NSLocalizedString(descriptionKey, comment: "Get a message by a description key")
        } else if !error.localizedDescription.isEmpty {
            textOfError += error.localizedDescription
        } else {
            if error.code == NSURLErrorCancelled {
                textOfError += AlertMessages.tryLoginAgain.localized
            } else if error.code == NSURLErrorTimedOut {
                textOfError += AlertMessages.timeoutTryLoginLater.localized
            } else {
                textOfError += AlertMessages.errorCode.localized + ": \(error.code)."
            }
        }
        
        if error.code == 3840 {
            // When we receive non-json response from a server-side, we send a new request:
            textOfError = AlertMessages.errorCode.localized + " - \(error.code).\n" + AlertMessages.tryLoginLater.localized
        }
        
        if error.code == 401 || error.code == 4 {
            titleOfError = AlertTitles.sessionInvalidTitle.localized
            if let serverMessage = error.userInfo[NSLocalizedDescriptionKey] as? String {
                if serverMessage.isEmpty {
                    let reason = error.userInfo[NSLocalizedFailureReasonErrorKey] as? String
                    let invslidJsonReason = "keep_alive_401_invalidjson"
                    let noAuthDataReason = "no_auth_data"
                    
                    if reason == invslidJsonReason {
                        textOfError = AlertMessages.sessionNotValid.localized
                    } else if reason == noAuthDataReason {
                        textOfError = AlertMessages.noCookies.localized
                    } else {
                        textOfError = AlertMessages.sessionInvalidMessage.localized
                    }
                } else {
                    textOfError = serverMessage
                }
            } else {
                textOfError = AlertMessages.sessionInvalidMessage.localized
            }
        }
        
        if error.code == -1003 {
            textOfError = AlertMessages.serverNotFound.localized
        }
        
        if error.code == 403 {
            if let errorReason = error.userInfo[NSLocalizedFailureReasonErrorKey] as? String {
                textOfError = errorReason
            }
        }

        return (titleOfError, textOfError)
    }
    
    // MARK: - Private
    
    func handleKeepAliveError(error: NSError?) {
        guard let error = error else { return }

        debugPrint("EchdConnectionManager::handleKeepAliveError: \(error)")
        
        authDelegate?.echdConnectionManagerStatus(status: .error(error: error))
        
        stop()
    }
    
    private func removeAllRequests() {
        EchdSettingsService.instance.stop()
        
        authRequest?.cancel()
        cameraRequest?.cancel()
        presetsRequest?.cancel()

        cameraSearchRequest?.cancel()
        archiveControlsRequest?.cancel()
        photoRequest?.cancel()
        
        authRequest = nil
        cameraRequest = nil
        presetsRequest = nil
        cameraSearchRequest = nil
        archiveControlsRequest = nil
        photoRequest = nil
    }
    
    private func setDefaultIntervals() {
        self.beatInterval = EchdConnectionManager.defaultBeatInterval
        self.noticeInterval = EchdConnectionManager.defaultNoticeInterval
    }
    
    private func stopKeepAliveService() {
        // save payload because we destroy keepAliveService:
        keepAliveServicePayload = keepAliveService?.payload
        
        keepAliveService?.stop()
        keepAliveService = nil
    }
    
    private func startNoticesService() {
        if let host = self.host, let _ = getCookie() {
            self.noticeService = EchdNoticeService(host: host, delegate: self)
            self.noticeService?.start()
        }
    }
    
    private func stopNoticesService() {
        self.noticeService?.stop()
        self.noticeService = nil
    }
    
    private func startServerTimeService(){
        if let host = self.host, let _ = getCookie() {
            self.serverTimeService = EchdServerTimeService(host: host, delegate: self)
            self.serverTimeService?.start()
        }
    }
    
    private func stopServerTimeService(){
        self.serverTimeService?.stop()
        self.serverTimeService = nil
    }
    
    private func ptzMoveRequest(cameraId: String, command: PtzCommand) { 
        let positionRequest = EchdGetPositionRequest(id: cameraId)
        positionRequest.request(fail: { [weak self] error in
            self?.cameraManipulationDelegate?.failed(with: error.localizedDescription)
            
        }, success: { (code, response) in
            guard let positionsDictionary = response["position"] as? [String:AnyObject] else { return }
            
            // positionsDictionary has same key/value pairs and we get a first key/value pair
            for positionKeyValue in positionsDictionary {
                if let cameraPositionValue = positionKeyValue.value as? [String: AnyObject],
                    let _ = cameraPositionValue["pan"] as? Int,
                    let _ = cameraPositionValue["tilt"] as? Int,
                    let _ = cameraPositionValue["zoom"] as? Int {
                    
                    let moveRequest = EchdMoveRequest(id: cameraId,
                                                      command: command.rawValue)
                    moveRequest.request(fail: { error in
                        self.cameraManipulationDelegate?.failed(with: error.localizedDescription)
                    
                    }, success: { (code, response) in
                        if let success = response["success"] as? Bool,
                            success {
                            self.cameraManipulationDelegate?.success()
                        } else {
                            self.cameraManipulationDelegate?.failed(with: response["message"] as? String ?? "")
                        }
                    })
                    
                    break
                }
            }
        })
    }
    
    private func makeGetCameraListRequest(allFilters: [String: Any], responseReceiver: GetCameraListResponseReceiver) -> GetCameraListRequest {
        //TODO: Remove a non-nil check
        let request = GetCameraListRequest(sessionInstanceId: settingsService?.sessionInstanceId ?? 0)
        request.request(parameters: allFilters, fail: { (error) in
            responseReceiver.getCameraListRequest(request,
                                                  x: nil,
                                                  y: nil,
                                                  with: nil,
                                                  error: error)
        }) { (code, result) in
            responseReceiver.getCameraListRequest(request,
                                                  x: nil,
                                                  y: nil,
                                                  with: result as [String : AnyObject],
                                                  error: nil)
        }
        
        return request
    }
    
    private func getFilteredRouteCameras(cameras: [EchdSearchCamera], filter: [String: Any]) -> [EchdSearchCamera] {
        var districts: [Int] = []
        if let unwrapperDistricts = filter[CameraFilters.districts.rawValue] as? [Int] {
            districts = unwrapperDistricts
        } else if let district = filter[CameraFilters.districts.rawValue] as? Int {
            districts.append(district)
        }
        
        var regions: [Int] = []
        if let unwrapperRegions = filter[CameraFilters.regions.rawValue] as? [Int] {
            regions = unwrapperRegions
        }
                
        var cameraTypes: [Int] = []
        if let tmpCameraTypes = filter[CameraFilters.cameraTypes.rawValue] as? [Int] {
            cameraTypes = tmpCameraTypes
        } else if let tmpCameraType = filter[CameraFilters.cameraTypes.rawValue] as? Int {
            cameraTypes.append(tmpCameraType)
        }
        
        var cameraStatuses: [Int] = []
        if let tmpCameraStatuses = filter[CameraFilters.cameraStatuses.rawValue] as? [Int] {
            cameraStatuses = tmpCameraStatuses
        } else if let tmpCameraStatus = filter[CameraFilters.cameraStatuses.rawValue] as? Int {
            cameraStatuses.append(tmpCameraStatus)
        }
        
        let cameras = cameras.filter {
            guard let cameraType = $0.cameraType else  { return false }
            
            guard cameraTypes.contains(cameraType) else { return false }
            
            guard let cameraStatus = $0.status else { return false }
            
            guard cameraStatuses.contains(cameraStatus) else {return false}
            
            if let district = $0.district, let region = $0.region {
                if districts.contains(district) || regions.contains(region) {
                    return true
                }
            }
            
            return false
        }
        
        return cameras
    }
}

// MARK: - EchdNoticeServiceDelegate

extension EchdConnectionManager: EchdNoticeServiceDelegate {
    
    func echdNoticeServiceRequest(_ sender: EchdNoticeService, notice: AnyObject) {
        
        var receivedNotices: [EchdNotice] = []
        
        if let noticed = notice as? [String: AnyObject],
            let success = noticed["success"] as? Bool,
            success,
            let notices = noticed["result"] as? [ [String: Any] ] {

            for noticeDict in notices {
                var echdNotice = EchdNotice()
                echdNotice.name = noticeDict["name"] as? String
                echdNotice.id = noticeDict["id"] as? Int
                echdNotice.description = noticeDict["description"] as? String
                echdNotice.dateStart = noticeDict["dateStart"] as? String
                echdNotice.dateFinish = noticeDict["dateFinish"] as? String
                echdNotice.dateRemove = noticeDict["dateRemove"] as? String
                echdNotice.checked = noticeDict["checked"] as? Bool

                receivedNotices.append(echdNotice)
            }
        }
        
        echdNotices = receivedNotices
    }
    
    func echdNoticeServiceRequest(_ sender: EchdNoticeService, status: EchdKeepAliveServiceStatus) {
        switch status {
        case .none:
            debugPrint("EchdConnectionManager::echdNoticeServiceRequest: none")
        case .running:
            debugPrint("EchdConnectionManager::echdNoticeServiceRequest: running")
        case .stopped(let error):
            if let error = error {
                debugPrint("EchdConnectionManager::echdNoticeServiceRequest: stopped \(error)")
            }
        case .interrupted:
            debugPrint("EchdConnectionManager::echdNoticeServiceRequest: interrupted")
            break
        }
    }
}

// MARK: - CameraColorSource

extension EchdConnectionManager: CameraColorSource {
    
    func getColor(for type: Int) -> String? {
        guard let filtersService = filtersService else { return nil }
        
        return filtersService.getColor(for: type)
    }
    
    func getStatusColor(for status: Int) -> String? {
        guard let filtersService = filtersService else { return nil }
           
           return filtersService.getColor(status: status)
    }
}

// MARK: - CameraColorSource

extension EchdConnectionManager: FilterNodesSource {

    func generateFilters() -> (nodes:[FilterNodeProtocol], filterIsOn: Bool) {
        guard let filtersService = filtersService else { return ([], false) }
        
        return filtersService.generateFilters()
    }
    
    func saveFilter() {
        guard let filtersService = filtersService else { return }
        
        return filtersService.saveFilters()
    }
    
    func filtersChanged() {
        guard let filtersService = filtersService else { return }
        
        if filtersService.filtersChanged() {
            if filtersService.filterIsOn() {
                delegate?.echdConnectionManagerDidUpdateFilters()
            }
        }
    }
    
    func filterRegionChanged(region: Int, status: Bool) {
        delegate?.echdConnectionManagerDidUpdateRegion(region: region, status: status)
    }
    
    func toggleRegions(to status: Bool) {
        delegate?.echdConnectionManagerToggleRegions(to: status)
    }

    func setFilterMode(_ isOn: Bool) {
        filtersService?.setFilterMode(isOn)
        delegate?.echdConnectionManagerDidUpdateFilters()
    }
}

// MARK: - LoginViewControllerDelegate

extension EchdConnectionManager: LoginViewControllerDelegate {
    
    func loginSentAction(_ action: LoginViewControllerActions, parameters: [String : Any]?) {
        switch action {
        case .connect:
            host = echdPortalAddress.url
            
            guard let params = parameters else { return }

            start(parameters: params)
            
            break
        case .reconnect:
            self.host = echdPortalAddress.url
            reconnect()
            
        case .disconnect:
            self.host = nil
            pause()
            
            break
        case .openPreset( _):
            
            break
        case .cancel:
            stop()
            break
        }
    }
}

// MARK: - EchdConnectionManagerCameraSearchDelegate

extension EchdConnectionManager: EchdConnectionManagerCameraSearchDelegate {
    
 internal func echdConnectionCameraSearchManager(_ sender: EchdConnectionManager, searchCameraList: [EchdSearchCamera], error: Error?) {
        setRouteCameras(searchCameraList, routeCamerasIndices: EchdSettingsService.instance.getCameraRouteMain())
    }
}

// MARK: - EchdKeepAliveServiceDelegate

extension EchdConnectionManager: EchdKeepAliveServiceDelegate {
    
    func userPermissionsChanged(reason: String?) {
        permissionsDelegate?.userPermissionsChanged(reason: reason)
    }
    
    func echdKeepAliveService(_ sender: EchdKeepAliveService, status: EchdKeepAliveServiceStatus) {
        switch status {
        case .none:
            break
        case .interrupted:
            self.status = .interrupted
            currentPresentingNotificationBar?.showWarning()
            startInterruptionTimer()
        case .running:
            stopInterruptionTimer()
            switch self.status {
            case .connecting, .none, .interrupted, .stopped:
                currentPresentingNotificationBar?.hideWarning()

                self.status = .connected

                authDelegate?.echdConnectionManagerStatus(status: .connected)
            default:
                break
            }
        case .stopped(let error):
            guard let error = error else { return }
            
            debugPrint("EchdConnectionManager::echdKeepAliveServiceRequest: \(error)")
            
            authDelegate?.echdConnectionManagerStatus(status: .error(error: error))
            startInterruptionTimer()
            stop()
        }
    }
    
    func updateSettings() {
        settingsService?.updateSettings()
    }
}
