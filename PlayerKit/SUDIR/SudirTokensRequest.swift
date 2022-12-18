//
//  SudirTokensRequest.swift
//  AreaSight
//
//  Created by Shamil on 02.04.2020.
//  Copyright © 2020 Netris. All rights reserved.
//

import Foundation
import Alamofire

class SudirTokensRequest {
    
    /*
     Getting an access token and an identification token.
     */
    
    func postSudirTokens(_ parameters: Parameters,
                         callback: @escaping (_ success: SudirTokens?, _ failure: Error?) -> Void) {
        let url = AppContext.Sudir.authorizationUrl + AppContext.Paths.sudirTokensPath
        
        AF.request(url, method: .post,
                   parameters: parameters,
                   headers: .init(getHeaders()))
        .response { responseData in
            guard let statusCode = responseData.response?.statusCode else {
                let error = responseData.error
                let errorLocalizedDescription = error?.localizedDescription ?? ""
                debugPrint("SudirTokensRequest::postSudirTokens:(1): No status code. \(errorLocalizedDescription)")
                callback(nil, error)
                return
            }
            guard let data = responseData.data else {
                debugPrint("SudirTokensRequest::postSudirTokens:(2): No data")
                return
            }
            guard (200...299).contains(statusCode) else {
                let error = CustomError.getError(with: data, domain: "SudirTokensRequest::postSudirTokens", statusCode: statusCode)
                debugPrint("SudirTokensRequest::postSudirTokens:(3): \(error.localizedDescription)")
                callback(nil, error)
                return
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let decodedData = try decoder.decode(SudirTokens.self, from: data)
                callback(decodedData, nil)
            } catch let errorDecode {
                debugPrint("SudirTokensRequest::postSudirTokens:(4): \(errorDecode.localizedDescription)")
                callback(nil, errorDecode)
            }
        }
    }

    private func getHeaders() -> [String: String] {
        let clientIdAndClientSecret = getClientIdAndClientSecret()
        let base64ClientIdAndClientSecret = Data(clientIdAndClientSecret.utf8).base64EncodedString()
        let headers = [
            "Content-Type": "application/x-www-form-urlencoded",
            "Authorization": "Basic \(base64ClientIdAndClientSecret)"
        ]
        return headers
    }

    private func getClientIdAndClientSecret() -> String {
        let keychainService = EchdKeychainService.sharedInstance
        var clientId = ""
        var clientSecret = ""

        if let userUid = AuthService.instance.getActiveSudirUserUid() {
            clientId = keychainService.getValue(forKey: userUid + EchdKeychainService.Keys.sudirClientId.rawValue) ?? ""
            clientSecret = keychainService.getValue(forKey: userUid + EchdKeychainService.Keys.sudirClientSecret.rawValue) ?? ""
        } else {
            clientId = keychainService.getValue(forKey: EchdKeychainService.Keys.sudirClientId.rawValue) ?? ""
            clientSecret = keychainService.getValue(forKey: EchdKeychainService.Keys.sudirClientSecret.rawValue) ?? ""
        }
        return "\(clientId):\(clientSecret)"
    }
}
