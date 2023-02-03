//
//  AbstractRequest.swift
//  AreaSightDemo
//
//  Created by Artem Lytkin on 29/01/2019.
//  Copyright © 2019 Netris. All rights reserved.
//

import Alamofire
import UIKit
import Combine


internal protocol AbstractRequest: AnyObject {
    
 
    var dataRequest: DataRequest? { get set }
 
 
    
    func request(parameters:[String: Any],
                 fail: @escaping (Error) -> Void,
                 success: @escaping(Int?, [String: Any?]) -> Void)
    
    func cancel()
    
    func getHost() -> String
    
    func getHeaders() -> HTTPHeaders
 
    func getCookie() -> String
}

internal extension AbstractRequest {
 
    var requestURL: URL? { dataRequest?.request?.url }
 
    func getCookie() -> String { EchdConnectionManager.sharedInstance.getCookie() ?? "" }
    
    func cancel() { dataRequest?.cancel() }
    
    func getHost() -> String { AppContext.DefaultServerAddresses.main }
    
    func getHeaders() -> HTTPHeaders {
        var headers: HTTPHeaders = [
            "Content-Type"     : "application/json",
            "X-Requested-With" : "XMLHttpRequest" ]
        
        headers["Cookie"] = getCookie()
      
        headers["User-Agent"] = getUserAgent()

        return headers
    }
    
    func checkCookies(for url: URL,
                      success: (_ sessionId: String?,
                       _ grailsRememberMe: String?) -> Void,
                      fail: (Error) -> Void ) {
     
        if let cookies = HTTPCookieStorage.shared.cookies(for: url) {
            let tokens = self.getTokens(from: cookies)
            
            success(tokens.sessionId, tokens.grailsRememberMeToken)
        }
    }
    
    func getTokens(from cookies: [HTTPCookie]) -> (sessionId: String? , grailsRememberMeToken: String?) {
        var sessionId: String?
        var grailsRememberMeToken: String?
        
        for cookie in cookies {
            switch cookie.name {
            case "JSESSIONID":
                sessionId = cookie.value
            case "grails_remember_me":
                grailsRememberMeToken = cookie.value
            default:
                break
            }
            
            HTTPCookieStorage.shared.deleteCookie(cookie)
        }
        
        return (sessionId, grailsRememberMeToken)
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
}

extension AbstractRequest {
 
}

@available(iOS 13.0, *)
extension AbstractRequest {
 
}
