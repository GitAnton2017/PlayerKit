//
//  URLSessionRequestRepresentable.swift
//  PlayerKit
//
//  Created by Anton2016 on 08.01.2023.
//

import Foundation
import UIKit
import Combine

typealias HTTPRequestHeaders = [ String : String ]

internal protocol URLSessionRequestRepresentable: AnyObject {

 var dataTask: URLSessionDataTask? { get set }

 var requestHost: String { get }
 
 var requestHeaders: HTTPRequestHeaders { get }
 
 var sessionCookie: String { get }
}



extension URLSessionRequestRepresentable {
 
 var requestHost: String { DefaultServerAddresses.main }
 
 func cancel() { dataTask?.cancel() }
 
 var requestURL: URL? { dataTask?.originalRequest?.url }
 
 var userAgent: String {
  var version = "?"
  if let tmpVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
   version = tmpVersion
  }
  
  var build = "?"
  if let tmpBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
   build = tmpBuild
  }
  
  return "Videogorod/\(version) ios/\(UIDevice.current.model) iOS/\(UIDevice.current.systemVersion) CFNetwork/0 Darwin/\(build)"
 }
 
 var requestHeaders: [ String : String ]  {
   [ "Content-Type"     : "application/json",
     "X-Requested-With" : "XMLHttpRequest",
     "Cookie"           : sessionCookie,
     "User-Agent"       : userAgent   ]
  
 }
 
 
 
 func getRequestURL(endPoint: String, queryParameters: [URLQueryItem]) -> URL? {
  
  guard let hostUrl = URL(string: requestHost) else { return nil }
  
  var urlParts = URLComponents()
  urlParts.path = endPoint
  urlParts.queryItems = queryParameters.isEmpty ? nil : queryParameters
  return urlParts.url(relativeTo: hostUrl)
         
 }
 
 
 
 
 
}
