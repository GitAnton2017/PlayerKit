//
//  ECHD VSS Photo Request.swift
//  PlayerKitFramework
//
//  Created by Anton2016 on 17.12.2022.
//

import Alamofire

internal final class ECHDPhotoRequest: AbstractRequest {
 internal var dataRequest: DataRequest?
 
 private var url: String
 private var sessionCookie: String
 
 init(url: String, sessionCookie: String){
  self.url = url
  self.sessionCookie = sessionCookie
 
 }
 
 func getCookie() -> String { sessionCookie }
 
 internal func request(parameters: [String : Any] = [:],
                       fail: @escaping (Error) -> (),
                       success: @escaping (Int?, [String : Any?]) -> () ) {
  
  let queue = DispatchQueue(label: "com.netris.echdMakePhotoRequest",
                            qos: .userInitiated,
                            attributes: [.concurrent])
  
  dataRequest = NTXECHDManager.alamofireSession
   .request( url, method: .get,
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
