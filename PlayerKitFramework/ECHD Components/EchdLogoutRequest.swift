//
//  EchdLogoutRequest.swift
//  AreaSightDemo
//
//  Created by Artem Lytkin on 29/01/2019.
//  Copyright © 2019 Netris. All rights reserved.
//

import Alamofire

class EchdLogoutRequest: AbstractRequest {
    
    var dataRequest: DataRequest?
    
    func request(parameters: [String : Any], fail: @escaping (Error) -> Void, success: @escaping (Int?, [String : Any?]) -> Void) {
                
        dataRequest = EchdConnectionManager.sharedInstance.alamofireManager.request(getHost() + "/logout",
                                                                                    method: .get,
                                                                                    headers: getHeaders())
            .responseJSON() { [weak self] response in
                self?.removeCookies()
                
                success(response.response?.statusCode, [:])
        }
    }
    
    private func removeCookies() {
        guard let allCookies = HTTPCookieStorage.shared.cookies else {
            return
        }
        for cookie in allCookies {
            HTTPCookieStorage.shared.deleteCookie(cookie)
        }
    }
}
