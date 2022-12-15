//
//  EchdClearFavorite.swift
//  AreaSightDemo
//
//  Created by Ruslan Utashev on 29/03/2019.
//  Copyright © 2019 Netris. All rights reserved.
//
import Alamofire

class EchdClearFavoriteRequest: AbstractRequest {
    
    var dataRequest: DataRequest?
    
    func request(parameters: [String : Any], fail: @escaping (Error) -> Void, success: @escaping (Int?, [String : Any?]) -> Void) {
        dataRequest = EchdConnectionManager.sharedInstance.alamofireManager.request(getHost() + EchdRequests.ajaxClearFavorite, method: .post, parameters: nil, encoding: URLEncoding.httpBody, headers: getHeaders())
            .responseJSON() { response in
                if let result = try? response.result.get() as? [String: Any] {
                    success(response.response?.statusCode, result)
                } else {
                 fail(AuthenticationError.missingCredential)
                }
        }
    }
}
