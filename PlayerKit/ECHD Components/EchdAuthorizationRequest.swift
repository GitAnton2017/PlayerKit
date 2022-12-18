//
//  AuthorizationRequest.swift
//  AreaSight
//
//  Created by Artem Lytkin on 15/04/2019.
//  Copyright © 2019 Netris. All rights reserved.
//

import Alamofire
import UIKit

class EchdAuthorizationRequest: AbstractRequest {
    
    var dataRequest: DataRequest?
    
    // MARK: - Properties
    
    private var url: String {
        get {
            return getHost() + "/auth/ajax"
        }
    }
    
    private let login: String
    private let password: String
    
    // MARK: - Lifecycle
    
    required init?(parameters: [String: Any]) {
        if let login = parameters["login"] as? String,
            let password = parameters["password"] as? String {
            self.login = login
            self.password = password
        } else {
            return nil
        }
    }
    
    // MARK: - Public
    
    func request(parameters: [String : Any], fail: @escaping (Error) -> Void, success: @escaping (Int?, [String : Any?]) -> Void) {
        
    }
    
     func request(fail: @escaping (Error) -> Void,
                        success: @escaping (_ login: String?,
                                            _ cookie: String?,
                                            _ grailsRememberMe: String?) -> Void) {
        
        clearCookies()

        let queue = DispatchQueue(label: "com.netris.response-authorize-queue", qos: .userInitiated, attributes: [.concurrent])
        let clientName = AppVersionHelper.clientName
        let clientVersion = AppVersionHelper.getAppShortVersion()
        
        // TODO: Remove the "_spring_security_remember_me" property. It is not removed for compatibility with an old server
        let parameters = [
            "j_username": login,
            "j_password": password,
            "clientName": clientName,
            "_spring_security_remember_me": "on",
            "clientVersion": clientVersion
        ]
        
        dataRequest = EchdConnectionManager.sharedInstance.alamofireManager.request(
            url,
            method: .post,
            parameters: parameters,
            encoding: URLEncoding(destination: .httpBody),
            headers: getAuthorizationHeaders()
            )
            .responseJSON(queue: queue) { [weak self] response in
                guard let self = self else {
                    return
                }
                
                switch response.result {
                case .success:
                  
                    let json = (try? response.result.get() as? [String: Any]) ?? [:]
                    
                    // This is misteric thing for me))) Error in successful response
                    if let error_string = json["error"] as? String {
                        let userInfo: [String: Any] = [
                            NSLocalizedDescriptionKey :  "error",
                            NSLocalizedFailureReasonErrorKey : error_string
                        ]
                        
                        debugPrint("EchdAuthorizationRequest::request:success: \(json)")
                        
                        fail(NSError(domain: "EchdHttpResponseError",
                                     code: response.response?.statusCode ?? -200,
                                     userInfo: userInfo))
                        
                        return
                    }
                    
                    if let requestURL = response.response?.url,
                        let cookies = HTTPCookieStorage.shared.cookies(for: requestURL) {
                        let tokens = self.getTokens(from: cookies)
                        
                        if (String(tokens.sessionId ?? "").isEmpty ) || (String(tokens.grailsRememberMeToken ?? "").isEmpty ) {
                            let userInfo: [String: Any] = [
                                NSLocalizedDescriptionKey:  "error",
                                NSLocalizedFailureReasonErrorKey: json["message"] ?? ""
                            ]
                            
                            /*
                             Для ЕЦХД авторизации:
                             Запрос /j_spring_security_check - приходит 403 при устаревании пароля, с флагом passwordExpired: true
                             Запрос /auth/ajax - приходит 403 и passwordExpired: true при устаревании пароля
                             Запрос /auth/ajax - приходит 403 при устаревшей версии приложения
                             Запрос /auth/ajax - приходит 403 при отсутвии доступа к порталу
                             Запрос /auth/ajax - приходит 426 при устаревании пароля (отключено на сервере)
                            */
                            if response.response?.statusCode == 403 {
                                if let isPasswordExpired = json["passwordExpired"] as? Bool {
                                    if isPasswordExpired {
                                        let userInfo: [String: Any] = [
                                            NSLocalizedDescriptionKey:  "errorPasswordExpired",
                                            NSLocalizedFailureReasonErrorKey: "Пароль устарел.\nПерейдите на https://echd.mos.ru для смены пароля"
                                        ]
                                        let error = NSError(domain: "EchdHttpResponseError", code: 403, userInfo: userInfo)
                                        
                                        fail(error)
                                    } else {
                                        let error = NSError(domain: "EchdHttpResponseError", code: 403, userInfo: userInfo)
                                        
                                        fail(error)
                                    }
                                } else {
                                    let error = NSError(domain: "EchdHttpResponseError", code: -2001, userInfo: userInfo)
                                    
                                    fail(error)
                                }
                            } else if response.response?.statusCode == 426 {
                                let userInfo: [String: Any] = [
                                    NSLocalizedDescriptionKey:  "errorPasswordExpired",
                                    NSLocalizedFailureReasonErrorKey: "Пароль устарел.\nПерейдите на https://echd.mos.ru для смены пароля"
                                ]
                                let error = NSError(domain: "EchdHttpResponseError", code: 426, userInfo: userInfo)
                                
                                fail(error)
                            } else {
                                let error = NSError(domain: "EchdHttpResponseError", code: -2001, userInfo: userInfo)

                                fail(error)
                            }
                        } else {
                            success(self.login, String(tokens.sessionId!), String(tokens.grailsRememberMeToken!))
                        }

                    } else {
                        let userInfo: [String: Any] = [
                            NSLocalizedDescriptionKey:  "error",
                            NSLocalizedFailureReasonErrorKey: json["message"] ?? ""
                        ]
                        let error = NSError(domain: "EchdHttpResponseError", code: -2002, userInfo: userInfo)
                        
                        fail(error)
                    }

                case .failure(let error):
                    debugPrint("EchdAuthorizationRequest::request:failure:(1): \(error)")
                    
                    if let data = response.data  {
                        if let utf8Text = String(data: data, encoding: .utf8) {
                            debugPrint("EchdAuthorizationRequest::request:failure:(2): \(utf8Text)")
                        } else {
                            debugPrint("EchdAuthorizationRequest::request:failure:(2): Empty string")
                        }
                    } else {
                        debugPrint("EchdAuthorizationRequest::request:failure:(2): No data")
                    }
                    
                    fail(error)
                }
        }
    }
    
    // MARK: - Private
    
    private func getAuthorizationHeaders() -> HTTPHeaders {
        
        let headers: HTTPHeaders = [
            "Content-Type": "application/x-www-form-urlencoded",
            "X-Requested-With": "XMLHttpRequest",
            "User-Agent": getUserAgent()
        ]
        
        return headers
    }
    
    private func getUserAgent() -> String {
        var version = "?"
        if let tmpVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            version = tmpVersion
        }
        
        var build = "?"
        if let tmpBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            build = tmpBuild
        }
       
        return "Videogorod/\(version) ios/\(UIDevice.current.model) iOS/\(UIDevice.current.systemVersion) CFNetwork/0 Darwin/\(build)"
    }
    
    private func getTokens(from cookies: [HTTPCookie]) -> (sessionId: NSString? , grailsRememberMeToken: NSString?) {
        var sessionId: NSString?
        var grailsRememberMeToken: NSString?
        
        for cookie in cookies {
            switch cookie.name {
            case "JSESSIONID":
                sessionId = NSString(string: cookie.value)
            case "grails_remember_me":
                grailsRememberMeToken = NSString(string: cookie.value)
            default:
                break
            }
            
            HTTPCookieStorage.shared.deleteCookie(cookie)
        }
        
        return (sessionId, grailsRememberMeToken)
    }
    
    private func clearCookies() {
        let cstorage = HTTPCookieStorage.shared
        if let requestURL = URL(string: url), let cookies = cstorage.cookies(for: requestURL) {
            for cookie in cookies {
                cstorage.deleteCookie(cookie)
            }
        }
    }
}
