//
//  HTTP Request Errors.swift
//  PlayerKit
//
//  Created by Anton2016 on 10.01.2023.
//

import Foundation

enum HTTPRequestError: Error {
 case invalidRequestURL
 case badServerResponse
 case requestError(statusCode: Int)
 case noResponseData
}
