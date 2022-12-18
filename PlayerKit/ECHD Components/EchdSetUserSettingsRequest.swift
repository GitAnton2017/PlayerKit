//
//  EchdSetUserSettings.swift
//  AreaSight
//
//  Created by Александр on 07.02.17.
//  Copyright © 2017 Netris. All rights reserved.
//

import Alamofire

//https://echd.mos.ru/settings/ajaxSetUserSettings

class EchdSetUserSettingsRequest: AbstractRequest {
    var dataRequest: DataRequest?
    
    private var list: [Int]
    
    init(list: [Int]) {
        self.list = list
    }
    
    func request(parameters: [String : Any] = [:], fail: @escaping (Error) -> Void, success: @escaping (Int?, [String : Any?]) -> Void) {
        let queue = DispatchQueue(label: "com.netris.echdSetUserSettingsRequest", qos: .userInitiated, attributes: [.concurrent])
        
        var parameters = parameters
        parameters["camera-route-main"] = list

        dataRequest = EchdConnectionManager.sharedInstance.alamofireManager.request(
            getHost() + "/settings/ajaxSetUserSettings",
            method: .post,
            parameters: parameters,
            encoding: JSONEncoding.init(options: .prettyPrinted),
            headers: getHeaders()).responseJSON(queue: queue) { response in
                if let error = response.error {
                    fail(error)
                    return
                }
                
                if let json = try? response.result.get() as? [String: Any] {
                    success(response.response?.statusCode, json)
                }
        }
    }
}
