//
//  HTTP Methods.swift
//  PlayerKit
//
//  Created by Anton2016 on 10.01.2023.
//

import Foundation

enum HTTPMethods: String, Equatable, Hashable {
 
 case connect    = "CONNECT"   /// `CONNECT` method.
 case delete     = "DELETE"    /// `DELETE` method.
 case get        = "GET"       /// `GET` method.
 case head       = "HEAD"      /// `HEAD` method.
 case options    = "OPTIONS"   /// `OPTIONS` method.
 case patch      = "PATCH"     /// `PATCH` method.
 case post       = "POST"      /// `POST` method.
 case put        = "PUT"       /// `PUT` method.
 case query      = "QUERY"     /// `QUERY` method.
 case trace      = "TRACE"     /// `TRACE` method.
 
}
