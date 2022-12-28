//
//  ECHD VSS List Request.swift
//  PlayerKit
//
//  Created by Anton2016 on 27.12.2022.
//

import Alamofire

class ECHDVSSListRequest: AbstractRequest {
 
 var dataRequest: DataRequest?
 
 func getCookie() -> String { sessionCookie }
 
 private var sessionCookie: String
 private var cameraIDs: [ Int ]
 
 init(cameraIDs: [ Int ], sessionCookie: String) {
  self.cameraIDs = cameraIDs
  self.sessionCookie = sessionCookie
 }
 
 func request(parameters: [String : Any] = [ : ],
              fail: @escaping (Error) -> Void,
              success: @escaping (Int?, [ String : Any? ]) -> Void) {
  
  var filtered = parameters
  
  filtered["filter"] = ["cameras" : cameraIDs ]
  
  let queue = DispatchQueue(label: "com.netris.echdSearchCameraListRequest",
                            qos: .userInitiated,
                            attributes: [.concurrent])
  
  dataRequest = NTXECHDManager.alamofireSession.request(
   getHost() + "/camera/ajaxSearchCameraList",
   method: .post,
   parameters: filtered,
   encoding: JSONEncoding.default,
   headers: getHeaders()).responseJSON(queue: queue) { response in
    switch response.result {
      
     case .success:
      guard let json = response.value as? [ String : Any ] else {
       
       fail(NSError(domain: "EchdSearchCameraListRequest::request",
                    code: 406,
                    userInfo: [NSLocalizedFailureReasonErrorKey: "error_invalid_json"]))
       return
      }
      
//      debugPrint(#function, json)
      success(response.response?.statusCode, json)
      
     case .failure(let error):
      debugPrint("EchdSearchCameraListRequest::request: \(error)")
      
      fail(error)
    }
  }
 }
}
