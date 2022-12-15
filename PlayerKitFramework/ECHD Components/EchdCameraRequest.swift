//
//  EchdCameraRequest.swift
//  NetrisSVSM
//
//  Created by netris on 16.05.16.
//  Copyright © 2016 netris. All rights reserved.
//

import Alamofire

internal final class EchdCameraRequest: AbstractRequest {
 internal var dataRequest: DataRequest?
    
    private var cameraId: Int
    private var sessionInstanceId: Int
    
    init(cameraId: Int, sessionInstanceId: Int) {
        self.cameraId = cameraId
        self.sessionInstanceId = sessionInstanceId
    }

 
 internal func request(parameters: [String : Any] = [:],
                     fail: @escaping (Error) -> Void,
                     success: @escaping (Int?, [String : Any?]) -> Void) {
  
        let queue = DispatchQueue(label: "com.netris.echdCameraRequest",
                                  qos: .userInitiated,
                                  attributes: [.concurrent])
        
        var parameters = parameters
        parameters["id"] = cameraId
        parameters["instance"] = sessionInstanceId

        dataRequest = EchdConnectionManager.sharedInstance.alamofireManager.request(
            getHost() + "/camera/ajaxGetVideoUrls",
            method: .get,
            parameters: parameters,
            encoding: URLEncoding.queryString,
            headers: getHeaders())
            .responseJSON(queue: queue) { response in
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
