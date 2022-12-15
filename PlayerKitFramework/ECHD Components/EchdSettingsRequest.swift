//
//  EchdSettingsRequest.swift
//  NetrisSVSM
//
//  Created by netris on 12.05.16.
//  Copyright © 2016 netris. All rights reserved.
//

import Alamofire

class EchdSettingsRequest: AbstractRequest {
    var dataRequest: DataRequest?

    func request(parameters: [String : Any] = [:], fail: @escaping (Error) -> Void, success: @escaping (Int?, [String : Any?]) -> Void) {
        
        let queue = DispatchQueue(label: "com.netris.echdSettingsRequest", qos: .userInitiated, attributes: [.concurrent])
        
        var headers = getHeaders()
        headers["Content-Type"] = nil

        dataRequest = EchdConnectionManager.sharedInstance.alamofireManager.request(
            getHost() + "/settings/ajaxGetSettings?source=user,environment,mw-portal",
            method: .get,
            headers: headers
            )
            .responseJSON(queue: queue) { response in

                if let url = response.response?.url {
                    self.checkCookies(for: url, success: { sessionId, token in
                        if let sessionId = sessionId {
                            EchdConnectionManager.sharedInstance.setSessionId(sessionId)
                        }
                        
                    }, fail: { error in
                        debugPrint("EchdSettingsRequest::request:(1): \(error)")
                        
                        fail(error)
                    })
                }
                
                switch response.result {
                case .success:
                  
                  guard let json = try? response.result.get() as? JSONObject else {
                   debugPrint("EchdSettingsRequest::request: Wrong data: \(String(describing: response.result))")
                        
                   fail(NSError(domain: "EchdSettingsRequest::request", code: 206, userInfo: [NSLocalizedDescriptionKey: response.result ]))
                        
                        return
                    }
                    
                    success(response.response?.statusCode, json)

                case .failure(let error):
                    debugPrint("EchdSettingsRequest::request:(2): \(error)")
                    
                    fail(error)
                }
        }
    }
}
