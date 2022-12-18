//
//  EchdMoveRequest.swift
//  AreaSight
//
//  Created by Александр on 03.02.17.
//  Copyright © 2017 Netris. All rights reserved.
//

import Alamofire

class EchdMoveRequest: AbstractRequest {
    var dataRequest: DataRequest?
    
    private var id: String
    private var command: String
    
    init(id: String, command: String) {
        self.command = command
        self.id = id
    }
    
    func request(parameters: [String : Any] = [:], fail: @escaping (Error) -> Void, success: @escaping (Int?, [String : Any?]) -> Void) {
        let queue = DispatchQueue(label: "com.netris.echdMoveRequest", qos: .userInitiated, attributes: [.concurrent])

        var parameters = parameters
        parameters["id"] = id
        parameters["command"] = command
        
        dataRequest = EchdConnectionManager.sharedInstance.alamofireManager.request(
            getHost() + "/cameraTurner/ajaxMove",
            method: .get,
            parameters: parameters,
            encoding: URLEncoding.queryString,
            headers: getHeaders()).responseJSON(queue: queue) { response in
               if let error = response.error  {
                    fail(error)
                    return
                }
                
             if let json = try? response.result.get() as? [String: Any] {
                    success(response.response?.statusCode, json)
                }
        }
    }
}
