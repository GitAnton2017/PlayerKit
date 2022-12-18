//
//  EchdAreasRequest.swift
//  AreaSightDemo
//
//  Created by Ruslan Utashev on 20.07.2020.
//  Copyright © 2020 Netris. All rights reserved.
//

import Foundation
import Alamofire

class EchdAreasRequest: AbstractRequest {
    var dataRequest: DataRequest?
    
    func request(parameters: [String : Any], fail: @escaping (Error) -> Void, success: @escaping (Int?, [String : Any?]) -> Void) {
        AF.request(getHost() + "/ajax/areas",
                   method: HTTPMethod.post,
                   parameters: parameters,
                   encoding: JSONEncoding.default,
                   headers: getHeaders())
        .responseJSON(completionHandler: { item in
            guard let json = item.value as? [String: Any] else { return } //TODO: Прицепить fail
            let response = EchdMapAreaResponse(data: json)
            success(200, ["result": response.regionsCoordinates])

        })
    }
}
