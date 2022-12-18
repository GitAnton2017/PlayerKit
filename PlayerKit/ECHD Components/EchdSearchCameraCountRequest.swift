//
//  EchdSearchCameraListRequest.swift
//  AreaSight
//
//  Created by Александр Асиненко on 26.07.16.
//  Copyright © 2016 Netris. All rights reserved.
//

import UIKit
import Alamofire

class EchdSearchCameraCountRequest: AbstractRequest {
    
    var dataRequest: DataRequest?
    
    func request(parameters: [String : Any], fail: @escaping (Error) -> Void, success: @escaping (Int?, [String : Any?]) -> Void) {
        
        let queue = DispatchQueue(label: "com.netris.echdSearchCameraListRequest", qos: .userInitiated, attributes: [.concurrent])
        
        dataRequest = EchdConnectionManager.sharedInstance.alamofireManager.request(
            getHost() + "/camera/ajaxSearchCameraCount",
            method: .post,
            parameters: parameters,
            encoding: JSONEncoding.prettyPrinted,
            headers: getHeaders()
            )
            .responseJSON(queue: queue) { response in
                switch response.result {
                case .success:
                    guard let json = try? response.result.get() as? JSONObject else {
                        fail(NSError(domain: "EchdSearchCameraCountRequest::request", code: 406, userInfo: [NSLocalizedFailureReasonErrorKey: "error_invalid_json"]))
                        return
                    }
                    
                    success(response.response?.statusCode, json)
                    
                case .failure(let error):
                    debugPrint("EchdSearchCameraCountRequest::request: \(error)")
                    
                    fail(error)
                }
        }
    }
}
