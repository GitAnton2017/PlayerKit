//
//  EchdServerTimeRequest.swift
//  NetrisSVSM
//
//  Created by netris on 19.05.16.
//  Copyright © 2016 netris. All rights reserved.
//

import Alamofire

class EchdServerTimeRequest: AbstractRequest {
    var dataRequest: DataRequest?
    
    func request(parameters: [String : Any] = [:], fail: @escaping (Error) -> Void, success: @escaping (Int?, [String : Any?]) -> Void) {
        let queue = DispatchQueue(label: "com.netris.echdServerTimeRequest", qos: .userInitiated, attributes: [.concurrent])
        
        dataRequest = EchdConnectionManager.sharedInstance.alamofireManager.request(
            getHost() + "/ajaxGetDate",
            method: .get,
            headers: getHeaders()).responseString(queue: queue) { response in
                guard response.error == nil else {
                    fail(response.error!)
                    return
                }
                
                if let time = try? response.result.get() {
                    success(response.response?.statusCode, ["time": time])
                }
        }
    }
}
