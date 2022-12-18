//
//  EchdSearchCameraListRequest.swift
//  AreaSight
//
//  Created by Александр Асиненко on 26.07.16.
//  Copyright © 2016 Netris. All rights reserved.
//

import UIKit
import Alamofire

class EchdSearchCameraListRequest: AbstractRequest {
    
    var dataRequest: DataRequest?
    
    func request(parameters: [String : Any], fail: @escaping (Error) -> Void, success: @escaping (Int?, [String : Any?]) -> Void) {
        // This cameras count check must be moved to a individual service
        let filter = parameters["filter"] as? [String: AnyObject]
        if let cameras = filter?["cameras"] as? [Int] {
            let isCamerasCountEmpty = cameras.isEmpty
            if isCamerasCountEmpty {
                return
            }
        }
        
        let queue = DispatchQueue(label: "com.netris.echdSearchCameraListRequest", qos: .userInitiated, attributes: [.concurrent])
        
        dataRequest = EchdConnectionManager.sharedInstance.alamofireManager.request(
            getHost() + "/camera/ajaxSearchCameraList",
            method: .post,
            parameters: parameters,
            encoding: JSONEncoding.prettyPrinted,
            headers: getHeaders()
        )
            .responseJSON(queue: queue) { response in
                switch response.result {
                case .success:
                    guard let json = try? response.result.get() as? JSONObject else {
                        fail(NSError(domain: "EchdSearchCameraListRequest::request", code: 406, userInfo: [NSLocalizedFailureReasonErrorKey: "error_invalid_json"]))
                        return
                    }
                    
                    success(response.response?.statusCode, json)
                    
                case .failure(let error):
                    debugPrint("EchdSearchCameraListRequest::request: \(error)")
                    
                    fail(error)
                }
            }
    }
}
