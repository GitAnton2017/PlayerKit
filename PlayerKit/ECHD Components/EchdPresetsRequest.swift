//
//  EchdPresetsRequest.swift
//  NetrisSVSM
//
//  Created by netris on 13.05.16.
//  Copyright © 2016 netris. All rights reserved.
//

import Alamofire

class EchdPresetsRequest: AbstractRequest {
    var dataRequest: DataRequest?
    
    func request(parameters: [String : Any] = [:], fail: @escaping (Error) -> Void, success: @escaping (Int?, [String : Any?]) -> Void) {
        let queue = DispatchQueue(label: "com.netris.echdPresetsRequest", qos: .userInitiated, attributes: [.concurrent])

        dataRequest = EchdConnectionManager.sharedInstance.alamofireManager.request(
            getHost() + "/camera/preset/ajaxList",
            method: .get,
            headers: getHeaders()).responseJSON(queue: queue) { response in
                if let error = response.error  {
                    fail(error)
                    return
                }
                
                if let presets = try? response.result.get() as? [[String: Any]] {
                    success(response.response?.statusCode, ["presets": presets])
                }
        }
    }
}
