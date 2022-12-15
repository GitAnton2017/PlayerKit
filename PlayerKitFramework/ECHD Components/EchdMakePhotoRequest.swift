//
//  EchdMakePhotoRequest.swift
//  AreaSight
//
//  Created by Александр on 23.01.17.
//  Copyright © 2017 Netris. All rights reserved.
//

import Alamofire

internal final class EchdMakePhotoRequest: AbstractRequest {
 internal var dataRequest: DataRequest?
    
    private var url: String
    private var camera: Int

    init(url: String, camera: Int){
        self.url = url
        self.camera = camera
    }

 internal func request(parameters: [String : Any] = [:],
                     fail: @escaping (Error) -> Void,
                     success: @escaping (Int?, [String : Any?]) -> Void) {
  
        let queue = DispatchQueue(label: "com.netris.echdMakePhotoRequest",
                                  qos: .userInitiated,
                                  attributes: [.concurrent])
        
        dataRequest = EchdConnectionManager
        .sharedInstance
        .alamofireManager
        .request( url,
                  method: .get,
                  parameters: parameters,
                  headers: getHeaders()).responseData(queue: queue) { response in
                      guard response.error == nil else {
                          fail(response.error!)
                          return
                      }
                      
                      if let imageData = response.data {
                          success(response.response?.statusCode, ["image": imageData])
                      }
        }
    }
}
