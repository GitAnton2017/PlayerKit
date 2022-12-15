//
//  EchdArchiveControlsRequest.swift
//  AreaSight
//
//  Created by Александр on 23.08.16.
//  Copyright © 2016 Netris. All rights reserved.
//

import Alamofire

internal final class EchdArchiveControlsRequest: AbstractRequest  {
 internal var dataRequest: DataRequest?
    private var urlString: String
    
    init(url: String){
        self.urlString = url
    }

 internal func request(parameters: [String : Any] = [:],
                     fail: @escaping (Error) -> Void,
                     success: @escaping (Int?, [String : Any?]) -> Void) {
  
        let queue = DispatchQueue(label: "com.netris.echdArchiveControlsRequest",
                                  qos: .userInitiated,
                                  attributes: [.concurrent])
        
        dataRequest = EchdConnectionManager.sharedInstance.alamofireManager.request(
            urlString,
            method: .post,
            parameters: parameters,
            encoding: URLEncoding.queryString,
            headers: getHeaders()).responseJSON(queue: queue) { response in
                if let error = response.error {
                    fail(error)
                    return
                }
                
                if let json = try? response.result.get() as? [String : Any] {
                    success(response.response?.statusCode, json)
                }
        }
    }
}
