//
//  Request.swift
//  AreaSight
//
//  Created by Artem Lytkin on 28/02/2019.
//  Copyright © 2019 Netris. All rights reserved.
//

import Alamofire

internal final class GetCameraListRequest: AbstractRequest {
   
 internal var dataRequest: DataRequest?

    private var sessionInstanceId: Int = 0
    
    init(sessionInstanceId: Int) {
        self.sessionInstanceId = sessionInstanceId
    }
    
 internal func request(parameters: [String : Any],
                       fail: @escaping (Error) -> Void,
                       success: @escaping (Int?, [String : Any?]) -> Void) {
        
        let queue = DispatchQueue(label: "com.cnoon.response-queue",
                                  qos: .userInitiated,
                                  attributes: [.concurrent])
        
        dataRequest = EchdConnectionManager.sharedInstance.alamofireManager.request(
            getHost() + "/camera/ajaxGetCameraList?instance=\(sessionInstanceId)",
            method: .post,
            parameters: parameters,
            encoding: JSONEncoding.prettyPrinted,
            headers: getHeaders()).responseJSON(queue: queue) { response in
                
                switch response.result {
                case .success:
                  guard let json = try? response.result.get() as? JSONObject else {
                        fail(NSError(domain: "GetCameraListRequest::request", code: 406, userInfo: [NSLocalizedFailureReasonErrorKey: "error_invalid_json"]))
                        return
                    }

                    success(response.response?.statusCode, json)
                    
                case .failure(let error):
                    debugPrint("GetCameraListRequest::request: \(error)")
                    
                    fail(error)
                }
        }
    }
}
