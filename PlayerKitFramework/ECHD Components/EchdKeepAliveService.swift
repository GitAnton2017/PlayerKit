//
//  EchdKeepAliveService.swift
//  NetrisSVSM
//
//  Created by netris on 18.05.16.
//  Copyright © 2016 netris. All rights reserved.
//

import UIKit
import Alamofire

struct Payload: Codable {
    var id: Set<Int>
    var active: Bool
    var players: [Int: [ActivePlayer]]
    
    func getPlayersParams() -> [String: Any] {
        var params: [String: Any] = [:]
        
        for (id, playersForId) in players {
            var playersData: [[String: Any]] = []
            
            for player in playersForId {
                playersData.append(player.getParams())
            }
            params[String(id)] = playersData
        }
        
        return params
    }
}

internal struct ActivePlayer: Codable {
    
    internal enum Mode: String, Codable {
        case liveVideo = "live-video"
        case liveSnapshot = "live-snapshot"
        case archiveVideo = "archive-video"
        case archiveSnapshot = "archive-snapshot"
        case unchanged
    }
    
    internal enum State: String, Codable {
        case playing = "playing"
        case paused = "paused"
        case loading = "loading"
        case error = "error"
        case suspended = "suspended"
    }
    
    internal struct Archive: Codable {
     internal var position: Int
     internal var scale: Int = 1
    }
    
    internal var mode: Mode = .liveVideo
    internal var state: State = .suspended
    internal var archive: Archive? = nil
    
    internal init(mode: Mode, state: State, archive: Archive? = nil) {
        self.mode = mode
        self.state = state
        self.archive = archive
    }
    
    func getParams() -> [String: Any] {
        
        var params: [String: Any] = [:]
        params["mode"] = mode.rawValue
        params["state"] = state.rawValue
        
        if let archive = archive {
            var archiveParams: [AnyHashable: Any] = [:]
            archiveParams["scale"] = archive.scale
            archiveParams["position"] = archive.position
            params["archive"] = archiveParams
        }
        
        return params
    }
}

enum EchdKeepAliveServiceStatus {
    case none
    case running
    case interrupted
    case stopped(error: NSError?) //если error = nil то остановлено пользователем
}

protocol EchdKeepAliveServiceDelegate : AnyObject {
    func echdKeepAliveService(_ sender: EchdKeepAliveService, status: EchdKeepAliveServiceStatus)
    func userPermissionsChanged(reason: String?)
    func updateSettings()
}

final internal class EchdKeepAliveService: NSObject {
    
    private var sessionInstanceId: Int = 0
    private var keepAliveRequest: EchdKeepAliveRequest?
    
    weak var delegate : EchdKeepAliveServiceDelegate?

    var status: EchdKeepAliveServiceStatus = .none
    var isRun: Bool = false
    
    private lazy var serialQueue: DispatchQueue = {
        let queue = DispatchQueue(label: "com.netris.EchdKeepAliveService", qos: .default)
        return queue
    }()
    
    private lazy var accessQueue: DispatchQueue = {
        let queue = DispatchQueue(label: "com.netris.EchdKeepAliveService.accessQueue")
        return queue
    }()
    
    private var _payload = Payload(id: [], active: true, players: [:])

    var payload: Payload {
        get {
            var payloadMoc: Payload!
            accessQueue.sync {
                payloadMoc = _payload
            }
            
            return payloadMoc
        }
        set {
            accessQueue.async(flags: .barrier) {
                self._payload = newValue
            }
        }
    }
    
    
    private var repeatingTimer: RepeatingTimer?
    
    init(delegate: EchdKeepAliveServiceDelegate, sessionInstanceId: Int) {
        super.init()
        
        self.delegate = delegate
        self.sessionInstanceId = sessionInstanceId
    }

    func start(beatInterval: TimeInterval) {
        guard !isRun else {
            return
        }

        serialQueue.async {
            // Stop and deinit RepeatingTimer
            self.repeatingTimer?.cancel()
            self.repeatingTimer = nil
            
            self.isRun = true
            self.run(beatInterval: beatInterval)
        }
    }

    func sendSingleBeat() {
        serialQueue.async {
            self.isRun = true
            
            self.keepAlive()
        }
    }
    
    func stop() {
        serialQueue.async {
            // Stop and deinit RepeatingTimer
            self.repeatingTimer?.cancel()
            self.repeatingTimer = nil
            self.isRun = false
            self.status = .stopped(error: nil)

            self.keepAliveRequest?.cancel()
            self.keepAliveRequest = nil
            self.delegate?.echdKeepAliveService(self, status: self.status)
        }
    }
    
    func run(beatInterval: TimeInterval) {
        // First keep alive request we send manually
        keepAlive()
        
        // Instantiate the repeating timer:
        repeatingTimer = RepeatingTimer(timeInterval: beatInterval)
        
        // Set an action to the repeating timer:
        repeatingTimer?.eventHandler = { [weak self] in
            self?.keepAlive()
        }
        
        // Activate the repeating timer:
        repeatingTimer?.resume()
        
    }

    func keepAlive() {
        serialQueue.async { [weak self] in
            guard let self = self else { return }
            
            if !self.isRun {
                return
            }

            if (!NetworkReachabilityManager()!.isReachable) {
                self.status = .interrupted

                self.delegate?.echdKeepAliveService(self, status: self.status)
            }

            self.keepAliveRequest = nil
            let request = EchdKeepAliveRequest(payload: self.payload, sessionInstanceId: self.sessionInstanceId)
            self.keepAliveRequest = request
            request.request(fail: {[weak self] error in
                guard let self = self else { return }
                debugPrint("EchdKeepAliveService::keepAlive: \(error)")
                
                let underlyingError = error as NSError
                let response = underlyingError.userInfo[NSLocalizedDescriptionKey] as? [String:Any] ?? [:]
                if underlyingError.code == -1003 {
                    self.status = .interrupted
                    
                    self.delegate?.echdKeepAliveService(self, status: self.status)
                } else if underlyingError.code == 400 || underlyingError.code == 401 || underlyingError.code == 403 {
                    if AppDefaults.sharedInstance.getBoolValue(AppDefaults.sharedInstance.APP_DEFAULTS_IS_SUDIR_AUTHORIZATION) {
                        self.postSudirTokens(underlyingError, message: response["message"] as? String ?? "")
                    } else {
                        self.keepAliveServiceStopped(underlyingError, message: response["message"] as? String ?? "")
                    }
                } else {
                    self.keepAliveServiceStopped(underlyingError, message: response["message"] as? String ?? "")
                }
            }, success: { [weak self] (code, result) in
                    guard let self = self else { return }
                    
                    let resultCode: Int = (result["code"] as? Int) ?? code ?? 200
                
                    if resultCode == 201 {
                        self.delegate?.userPermissionsChanged(reason: result["message"] as? String)
                    } else {
                        self.status = .running
                        
                        self.delegate?.echdKeepAliveService(self, status: self.status)
                    }
            })
        }
    }
    
    private func keepAliveServiceStopped(_ error: NSError, message: String) {
        status = .stopped(error: NSError(domain: "EchdKeepAliveService::keepAlive", code: error.code, userInfo: [NSLocalizedDescriptionKey: message, NSUnderlyingErrorKey: error]))
        delegate?.echdKeepAliveService(self, status: status)
    }
    
    // MARK: - Sudir
    
    private func postSudirTokens(_ error: NSError, message: String) {
        let keychainService = EchdKeychainService.sharedInstance
        guard let userUid = AuthService.instance.getActiveSudirUserUid() else {
            keepAliveServiceStopped(error, message: message)
            return
        }
        guard let refreshToken = keychainService.getValue(forKey: userUid + EchdKeychainService.Keys.sudirRefreshToken.rawValue) else {
            keepAliveServiceStopped(error, message: message)
            return
        }
        
        let sudirTokensRequest = SudirTokensRequest()
     
        sudirTokensRequest.postSudirTokens(SudirRefreshTokensParameters(refreshToken).parameters) { [weak self] tokens, tokensError in
            guard let tokens = tokens else {
                self?.keepAliveServiceStopped(error, message: message)
                return
            }
            
            keychainService.set(tokens.accessToken, forKey: userUid + EchdKeychainService.Keys.sudirAccessToken.rawValue)
            keychainService.set(tokens.refreshToken, forKey: userUid + EchdKeychainService.Keys.sudirRefreshToken.rawValue)
            
            self?.postSudirAuthenticate(tokens.accessToken, error: error, message: message)
        }
    }
    
    private func postSudirAuthenticate(_ accessToken: String, error: NSError, message: String) {
        let sudirAuthenticateRequest = SudirAuthenticateRequest()
        sudirAuthenticateRequest.postSudirAuthenticate(accessToken) { [weak self] sessionCookies, authenticateError in
            guard let self = self else { return }
            guard let sessionCookies = sessionCookies else {
                self.keepAliveServiceStopped(error, message: message)
                return
            }
            
            
            AuthService.instance.saveSession(with: sessionCookies.sessionId, and: sessionCookies.grailsRememberMe, for: nil)
            
            self.delegate?.updateSettings()
            
            self.status = .running
            self.delegate?.echdKeepAliveService(self, status: self.status)
        }
    }
}
