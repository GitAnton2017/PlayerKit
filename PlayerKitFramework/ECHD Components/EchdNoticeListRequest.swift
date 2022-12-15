//
//  EchdNoticeListReqest.swift
//  NetrisSVSM
//
//  Created by netris on 18.05.16.
//  Copyright © 2016 netris. All rights reserved.
//

import Alamofire

class EchdNoticeListRequest: AbstractRequest {
    var dataRequest: DataRequest?
    
    func request(parameters: [String : Any], fail: @escaping (Error) -> Void, success: @escaping (Int?, [String : Any?]) -> Void) {
        
        let queue = DispatchQueue(label: "com.netris.response-noticeListRequest-queue", qos: .userInitiated, attributes: [.concurrent])
        
        dataRequest = EchdConnectionManager.sharedInstance.alamofireManager.request(
            getHost() + "/notice/getNoticeList",
            method: .post,
            parameters: parameters,
            encoding: JSONEncoding.prettyPrinted,
            headers: getHeaders())
            .responseJSON(queue: queue) { response in
                
                switch response.result {
                case .success:
                    
                    guard let json = try? response.result.get() as? JSONObject else { return }
                    success(response.response?.statusCode, json)
                    
                case .failure(let error):
                    debugPrint(error)
                    fail(error)
                }
        }
    }
}
