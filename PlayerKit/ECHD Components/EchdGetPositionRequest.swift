//
//  EchdGetPositionRequest.swift
//  AreaSight
//
//  Created by Александр on 03.02.17.
//  Copyright © 2017 Netris. All rights reserved.
//

import Alamofire

class EchdGetPositionRequest: AbstractRequest {
    
    var dataRequest: DataRequest?
    private var id: String

    init(id: String){
        self.id = id
    }

    func request(parameters: [String : Any] = [:], fail: @escaping (Error) -> Void, success: @escaping (Int?, [String : Any?]) -> Void) {
        let queue = DispatchQueue(label: "com.netris.echdCameraRequest", qos: .userInitiated, attributes: [.concurrent])
        
        var parameters = parameters
        parameters["ids"] = id
        
        dataRequest = EchdConnectionManager.sharedInstance.alamofireManager.request(
            getHost() + "/cameraManager/ajaxGetPosition",
            method: .get,
            parameters: parameters,
            encoding: URLEncoding.queryString,
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
