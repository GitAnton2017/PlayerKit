//
//  EchdGetRootRequest.swift
//  AreaSight
//
//  Created by Artem Lytkin on 02/07/2019.
//  Copyright © 2019 Netris. All rights reserved.
//

import Alamofire

class EchdGetRootRequest: AbstractRequest {
    
    var dataRequest: DataRequest?
    
    func request(parameters: [String : Any] = [:], fail: @escaping (Error) -> Void, success: @escaping (Int?, [String : Any?]) -> Void) {
        
        let queue = DispatchQueue(label: "com.cnoon.response-echdGetRootRequest-queue", qos: .userInitiated, attributes: [.concurrent])
        
        dataRequest = EchdConnectionManager.sharedInstance.alamofireManager.request(
            getHost(),
            method: .get,
            headers: getHeaders()
            )
            .responseString(queue: queue) { response in
                
                switch response.result {
                case .success:
                    success(response.response?.statusCode, [:])
                    
                case .failure(let error):
                    debugPrint("EchdGetRootRequest::request:\(error)")
                    
                    fail(error)
                }
        }
    }
}
