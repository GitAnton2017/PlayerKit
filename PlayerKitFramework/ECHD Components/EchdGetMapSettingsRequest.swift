//
//  EchdGetMapSettingsRequest.swift
//  AreaSightDemo
//
//  Created by Ruslan Utashev on 10.06.2021.
//  Copyright © 2021 Netris. All rights reserved.
//

import Foundation
import Alamofire

class EchdGetMapSettingsRequest: AbstractRequest {
    var dataRequest: DataRequest?
    
    func request(parameters: [String : Any],
                 fail: @escaping (Error) -> Void,
                 success: @escaping (Int?, [String : Any?]) -> Void) {
        dataRequest = AF.request(getHost() + "/mobile/settings.json",
                          method: .get,
                          parameters: nil,
                          encoding: JSONEncoding.default,
                          headers: getHeaders())
        .responseJSON(completionHandler: { (response) in
                            switch response.result {
                            case .success(_):
                              guard let json = try? response.result.get() as? JSONObject else { return }
                                success(response.response?.statusCode, json)
                                break
                            case .failure(let error):
                                fail(error)
                                break
                            }
                          })
    }
}
