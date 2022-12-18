//
//  EchdAddToFavoriteRequest.swift
//  AreaSight
//
//  Created by Александр on 18.01.17.
//  Copyright © 2017 Netris. All rights reserved.
//

import Alamofire

class EchdAddToFavoriteRequest: AbstractRequest {
    private var camera: Int
    var dataRequest: DataRequest?
    
    init(camera: Int) {
        self.camera = camera
    }

    func request(parameters: [String : Any] = [ : ],
                 fail: @escaping (Error) -> Void,
                 success: @escaping (Int?, [ String : Any? ]) -> Void) {
     
     dataRequest = EchdConnectionManager
      .sharedInstance
      .alamofireManager.request(
            getHost() + "/camera/ajaxAddToFavorite?id=\(camera)",
            method: .get,
            parameters: parameters,
            encoding: URLEncoding.queryString,
            headers: getHeaders())
      .responseJSON() { response in
                
                if let error = response.error {
                    fail(error)
                    return
                }

                if let json = try? response.result.get() as? [String: Any] {
                    
                    success(response.response?.statusCode, json)
                }
        }
    }
}
