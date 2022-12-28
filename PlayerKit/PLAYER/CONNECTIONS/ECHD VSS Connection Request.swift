//
//  ECHD VSS Connection Request.swift
//  PlayerKitFramework
//
//  Created by Anton V. Kalinin on 17.12.2022.
//

import Alamofire

internal final class ECHDVSSRequest: AbstractRequest {
 
 internal var dataRequest: DataRequest?
 
 private var cameraId: Int
 private var sessionInstanceId: Int
 private var sessionCookie: String
 
 init(cameraId: Int, sessionCookie: String, sessionInstanceId: Int = 0) {
  self.cameraId = cameraId
  self.sessionInstanceId = sessionInstanceId
  self.sessionCookie = sessionCookie
 }
 
 func getCookie() -> String { sessionCookie }
 
 func getHost()   -> String { NTXECHDManager.DefaultServerAddresses.main }
 
 internal func request(parameters: [String : Any] = [ : ],
                       fail:    @escaping (Error) -> Void,
                       success: @escaping (Int?, [String : Any?]) -> Void) {
  
  let queue = DispatchQueue(label: "com.netris.echdCameraRequest",
                            qos: .userInitiated,
                            attributes: [.concurrent])
  
  var parameters = parameters
  parameters["id"] = cameraId
  parameters["instance"] = sessionInstanceId
  
  dataRequest = NTXECHDManager.alamofireSession
   .request(getHost() + "/camera/ajaxGetVideoUrls",
            method: .get,
            parameters: parameters,
            encoding: URLEncoding.queryString,
            headers: getHeaders())
   .responseJSON(queue: queue) { response in
     if let error = response.error { fail(error) ; return }
     
     if let json = try? response.result.get() as? [String: Any] {
      success(response.response?.statusCode, json)
     }
  }
 }
 
 
 
}
