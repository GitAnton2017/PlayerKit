//
//  ECHD Server Settings Request.swift
//  PlayerKit
//
//  Created by Anton2016 on 27.12.2022.
//

import Alamofire

internal final class ECHDServerSettingsRequest: AbstractRequest {
 
 var dataRequest: DataRequest?
 
 private var sessionCookie: String
 
 init(sessionCookie: String){
  self.sessionCookie = sessionCookie
 }
 
 func getCookie() -> String { sessionCookie }
 
 
 func request(parameters: [String : Any] = [:],
              fail:       @escaping (Error) -> Void,
              success:    @escaping (Int?, [String : Any?]) -> Void) {
  
  let queue = DispatchQueue(label:  "com.netris.echdSettingsRequest",
                            qos:    .userInitiated,
                            attributes: [ .concurrent ])
  
  var headers = getHeaders()
  
  headers["Content-Type"] = nil
  
  let endPoint = getHost() + "/settings/ajaxGetSettings?source=user,environment,mw-portal"
  
  dataRequest = NTXECHDManager.alamofireSession.request( endPoint,
                                                         method: .get,
                                                         headers: headers)
   .responseJSON(queue: queue) { response in
    
    switch response.result {
     case .success:
      guard let json = try? response.result.get() as? [String : Any]  else {
       debugPrint("EchdSettingsRequest::request: Wrong data: \(String(describing: response.result))")
       
       fail(NSError(domain: "EchdSettingsRequest::request", code: 206,
                    userInfo: [NSLocalizedDescriptionKey: response.result]))
       
       return
      }
      
      success(response.response?.statusCode, json)
      
     case .failure(let error):
      debugPrint("EchdSettingsRequest::request:(2): \(error)")
      
      fail(error)
    }
   }
 }
}

