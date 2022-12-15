//
//  EchdMoveZoomRequest.swift
//  AreaSight
//
//  Created by Александр on 03.02.17.
//  Copyright © 2017 Netris. All rights reserved.
//

import Alamofire

class EchdMoveZoomRequest: AbstractRequest {
    var dataRequest: DataRequest?
    
    private var id: String
    private var isZoomIn: Bool
    
    init(id: String, isZoomIn: Bool){
        self.id = id
        self.isZoomIn = isZoomIn
    }
    
    func request(parameters: [String : Any] = [:], fail: @escaping (Error) -> Void, success: @escaping (Int?, [String : Any?]) -> Void) {
        
        let queue = DispatchQueue(label: "com.netris.echdMoveZoomRequest", qos: .userInitiated, attributes: [.concurrent])
        
        var parameters = parameters
        parameters["id"] = id
        parameters["command"] = isZoomIn ? "Z1" : "W1"
        
        dataRequest = EchdConnectionManager.sharedInstance.alamofireManager.request(
            getHost() + "/cameraTurner/ajaxMove",
            method: .get,
            parameters: parameters,
            encoding: URLEncoding.queryString,
            headers: getHeaders()).responseJSON(queue: queue) { response in
                guard response.error == nil else {
                    fail(response.error!)
                    return
                }
                
                if let json = try? response.result.get() as? [String: Any] {
                    success(response.response?.statusCode, json)
                }
        }
    }
}
