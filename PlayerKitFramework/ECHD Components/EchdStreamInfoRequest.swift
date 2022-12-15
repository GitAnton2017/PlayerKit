//
//  EchdStreamInfoRequest.swift
//  AreaSight
//
//  Created by Artem Lytkin on 21/06/2019.
//  Copyright © 2019 Netris. All rights reserved.
//

import Alamofire

class StreamInfoRequest: AbstractRequest {
    var dataRequest: DataRequest?
    
    private var url: URL
    
    init(url: URL) {
        debugPrint("StreamInfoRequest::init: Url: \(url)")
        self.url = url
    }
    
    func request(parameters: [String : Any], fail: @escaping (Error) -> Void, success: @escaping (Int?, [String : Any?]) -> Void) {
        
        let queue = DispatchQueue(label: "com.netris.response-stream-info-queue", qos: .userInitiated, attributes: [.concurrent])
        
        dataRequest = EchdConnectionManager.sharedInstance.alamofireManager.request(
            url,
            method: .post
            )
            .responseJSON(queue: queue) { response in
                
                switch response.result {
                case .success:    
                    guard let json = try? response.result.get() as? JSONObject else { return }
                    success(response.response?.statusCode, json)
                    
                case .failure(let error):
                    debugPrint("StreamInfoRequest::request: Error: \(error.localizedDescription)")
                    
                    fail(error)
                }
        }
    }
}
