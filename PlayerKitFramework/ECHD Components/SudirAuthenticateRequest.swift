//
//  SudirAuthenticateRequest.swift
//  AreaSight
//
//  Created by Shamil on 23.10.2020.
//  Copyright © 2020 Netris. All rights reserved.
//

import Foundation
import Alamofire
import UIKit

class SudirAuthenticateRequest {
    
    /*
     Request for sudir session cookies.
     Запрос /login/sudir/authenticate - приходит 403 и passwordExpired: true при устаревании пароля (не реализовано для СУДИР)
     Запрос /login/sudir/authenticate - приходит 403 при устаревшей версии приложения
     Запрос /login/sudir/authenticate - приходит 403 при отсутвии доступа к порталу
     Запрос /login/sudir/authenticate - приходит 426 при устаревании пароля (отключено на сервере)
     */
    
    func postSudirAuthenticate(_ accessToken: String,
                               callback: @escaping (_ success: SudirSessionCookies?,
                                                    _ failure: Error?) -> Void) {
     
        let url = AppContext.DefaultServerAddresses.main + AppContext.Paths.sudirAuthenticatePath
        let headers = getHeaders(accessToken)
     
        AF.request(url, method: .post,
                   parameters: SudirAuthenticateParameters().parameters,
                   headers: .init(headers)).response{ responseData in
         guard let statusCode = responseData.response?.statusCode else {
            let error = responseData.error
            let errorLocalizedDescription = error?.localizedDescription ?? ""
                           debugPrint("SudirAuthenticateRequest::postSudirAuthenticate:(1): No status code. \(errorLocalizedDescription)")
                           callback(nil, error)
                           return
          }
         
         guard let data = responseData.data else {
                           debugPrint("SudirAuthenticateRequest::postSudirAuthenticate:(3): No data")
                           return
                       }
         
         guard (200...299).contains(statusCode) else {
                           let error = CustomError.getError(with: data, domain: "SudirAuthenticateRequest::postSudirAuthenticate", statusCode: statusCode)
                           debugPrint("SudirAuthenticateRequest::postSudirAuthenticate:(4): \(error.localizedDescription)")
                           callback(nil, error)
                           return
                       }
                       guard let responseUrl = responseData.response?.url else {
                           debugPrint("SudirAuthenticateRequest::postSudirAuthenticate:(5): No response url")
                           return
                       }
                       guard let httpResponse = responseData.response else {
                           debugPrint("SudirAuthenticateRequest::postSudirAuthenticate:(6): No http response")
                           return
                       }
                       guard let fields = httpResponse.allHeaderFields as? [String: String] else {
                           debugPrint("SudirAuthenticateRequest::postSudirAuthenticate:(7): No header fields")
                           return
                       }
           
                       let cookies = HTTPCookie.cookies(withResponseHeaderFields: fields, for: responseUrl)
                       var sessionId = ""
                       var grailsRememberMe = ""
           
                       for cookie in cookies {
                           if cookie.name == "JSESSIONID" {
                               sessionId = cookie.value
                           } else if cookie.name == "grails_remember_me" {
                               grailsRememberMe = cookie.value
                           }
                       }
           
                       let sessionCookies = SudirSessionCookies(sessionId: sessionId, grailsRememberMe: grailsRememberMe)
                       callback(sessionCookies, nil)
                   }
        
     
     

    }
    
    private func getHeaders(_ accessToken: String) -> [String: String] {
        let headers = [
            "Authorization": "Bearer \(accessToken)",
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
}
