//
//  EchdGoToHomeRequest.swift
//  AreaSight
//
//  Created by Александр on 03.02.17.
//  Copyright © 2017 Netris. All rights reserved.
//

import Alamofire

class EchdMoveCameraToHomePositionRequest: AbstractRequest {
    
    //var url:String = "/cameraTurner/ajaxGoToHome?id="
    
    var dataRequest: DataRequest?
    private var id: String
    
    init(id: String) {
        self.id = id
    }
    
    func request(parameters: [String : Any] = [:], fail: @escaping (Error) -> Void, success: @escaping (Int?, [String : Any?]) -> Void) {
        let queue = DispatchQueue(label: "com.netris.echdMoveCameraToHomePositionRequest", qos: .userInitiated, attributes: [.concurrent])
        
        var parameters = parameters
        parameters["id"] = id
        
        dataRequest = EchdConnectionManager.sharedInstance.alamofireManager.request(
            getHost() + "/cameraTurner/ajaxGoToHome",
            method: .get,
            parameters: parameters,
            encoding: URLEncoding.queryString,
            headers: getHeaders()).responseJSON(queue: queue) { response in
                guard response.error == nil else {
                    fail(response.error!)
                    return
                }
                
                if let json = try? response.result.get() as? [String: Any] {
                    success(response.response?.statusCode, json)
                }
        }
    }
}

/*
 
 https://echd.mos.ru/cameraTurner/ajaxGoToHome?id=117852
 
 {
    "success": true
 }
 
 */
