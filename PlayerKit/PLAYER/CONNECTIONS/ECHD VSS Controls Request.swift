//
//  ECHD VSS Controls Request.swift
//  PlayerKitFramework
//
//  Created by Anton V. Kalinin on 17.12.2022.
//

import Alamofire

internal final class ECHDVSSArchiveControlsRequest: AbstractRequest  {
 
 internal var dataRequest: DataRequest?
 
 private var url: String
 private var sessionCookie: String
 
 init(url: String, sessionCookie: String){
  self.url = url
  self.sessionCookie = sessionCookie
 }
 
 func getCookie() -> String { sessionCookie }

 internal func request(parameters: [String : Any] = [ : ],
                       fail:    @escaping (Error) -> Void,
                       success: @escaping (Int?, [ String : Any? ]) -> Void) {
  
  let queue = DispatchQueue(label: "com.netris.echdArchiveControlsRequest",
                            qos: .userInitiated,
                            attributes: [.concurrent])
  
  dataRequest = NTXECHDManager.alamofireSession
   .request(url, method: .post, parameters: parameters,
            encoding: URLEncoding.queryString,
            headers: getHeaders() ).responseJSON(queue: queue) { response in
             if let error = response.error {
              fail(error)
              return
             }
             
             if let json = try? response.result.get() as? [String : Any] {
              success(response.response?.statusCode, json)
             }
            }
 }
}

