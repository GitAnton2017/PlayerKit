//
//  CustomError.swift
//  AreaSight
//
//  Created by Shamil on 15.12.2020.
//  Copyright © 2020 Netris. All rights reserved.
//

import Foundation

class CustomError {
    
    static func getError(with data: Data, domain: String, statusCode: Int) -> NSError {
        let json = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any]
        let message = json?["message"] as? String ?? ""
        let error = NSError(domain: domain, code: statusCode, userInfo: [NSLocalizedDescriptionKey: message, NSLocalizedFailureReasonErrorKey: message])
        return error
    }
}
