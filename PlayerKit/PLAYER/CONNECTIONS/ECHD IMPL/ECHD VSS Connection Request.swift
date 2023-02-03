//
//  ECHD VSS Connection Request.swift
//  PlayerKitFramework
//
//  Created by Anton V. Kalinin on 17.12.2022.
//

//import Alamofire

import Combine

final class ECHDVSSConnectionRequest: URLSessionRequestRepresentable {
 
 private let endPoint = "/camera/ajaxGetVideoUrls"
 private var urlSession: URLSession { NTXECHDManager.urlSession }
 
 var dataTask: URLSessionDataTask?
 var cameraId: Int
 var sessionCookie: String
 
 init(cameraId: Int, sessionCookie: String, resultHandler: @escaping (Result<Any, Error>) -> ()) {
  
  self.cameraId = cameraId
  self.sessionCookie = sessionCookie
  
  requestJSON(endPoint: endPoint,
              urlSession: urlSession,
              queryParameters: [.init(name: "id", value: "\(cameraId)")],
              resultHandler: resultHandler)
 }
 
 init(cameraId: Int, sessionCookie: String) {
  
  self.cameraId = cameraId
  self.sessionCookie = sessionCookie
  
 }
 
 @available(iOS 13.0, *)
 var jsonPublisher: AnyPublisher<Any, Error> {
  requestJSONPublisher(endPoint: endPoint,
                       urlSession: urlSession,
                       queryParameters: [.init(name: "id", value: "\(cameraId)")])
 }
 
 
 
 @available(iOS 15.0, *)
 var jsonData: Any {
  get async throws {
   try await requestJSON(endPoint: endPoint,
                         urlSession: urlSession,
                         queryParameters: [.init(name: "id", value: "\(cameraId)")])
  }
 }
}


/// ``CONNECTIONS MANAGER VSS CONNECTION REQUEST IMPLEMENTATIONS.
 
extension NTXECHDManager {
 
  /// Basic implementation with Result API.
 
 func requestVSSConnection(from searchResult: InputDevice,
                           resultHandler: @escaping VSSRequestResultHandler) -> URLSessionRequestRepresentable? {
  
  ECHDVSSConnectionRequest(cameraId: searchResult.id, sessionCookie: sessionCookie) { result in
   switch result {
    case let .success(json):
     guard let json = json as? [String : AnyObject] else {
      debugPrint("<<< --- [ RESULT API ] INVALID VSS CONNECTION REQUEST JSON RESULT --- >>>\n\(json)")
      resultHandler(.failure(NTXPlayerError.invalidVSSConnectionJSONObject(json: json)))
      return
     }
     
     resultHandler(.success(.init(data: json)))
     
    case let .failure(error):
     debugPrint("<<< --- [ RESULT API ] VSS CONNECTION REQUEST FAILED --- >>>\n\(error)")
     resultHandler(.failure(error))
   }
   
  }
 }
} //extension Basic implementation with Result API.


 
 @available(iOS 13.0, *)
 extension NTXECHDManager {
  
   ///Combine based implementation.
   
  func requestVSSConnection(from searchResult: Int) -> AnyPublisher <ECHDCamera, Error> {
   
   ECHDVSSConnectionRequest(cameraId: searchResult.id, sessionCookie: sessionCookie)
    .jsonPublisher
    .tryMap{ (json: Any) -> ECHDCamera in
     guard let json = json as? [String : AnyObject] else {
      debugPrint("<<< --- [ COMBINE API ] INVALID VSS CONNECTION REQUEST JSON RESULT --- >>>\n\(json)")
      throw NTXPlayerError.invalidVSSConnectionJSONObject(json: json)
     }
     return .init(data: json)
    }
    .receive(on: DispatchQueue.main)
    .eraseToAnyPublisher()
  }
 } //Combine based implementation.
 
 

  
@available(iOS 15.0, *)
extension NTXECHDManager {
 
///New Swift 5.5 Async Await implementation.
 
 func requestVSSConnection(from searchResult: Int) async throws -> ECHDCamera {
  
  let json = try await ECHDVSSConnectionRequest(cameraId: searchResult.id,
                                                sessionCookie: sessionCookie).jsonData
  
  guard let json = json as? [String : AnyObject] else {
   debugPrint("<<< --- [ ASYNC/AWAIT API ] INVALID VSS CONNECTION REQUEST JSON RESULT --- >>>\n\(json)")
   throw NTXPlayerError.invalidVSSConnectionJSONObject(json: json)
  }
  
  return .init(data: json)
 }
}//New Swift 5.5 Async Await implementation.


//internal final class ECHDVSSRequest: AbstractRequest {
//
// internal var dataRequest: DataRequest?
//
// private var cameraId: Int
// private var sessionInstanceId: Int
// private var sessionCookie: String
//
// init(cameraId: Int, sessionCookie: String, sessionInstanceId: Int = 0) {
//  self.cameraId = cameraId
//  self.sessionInstanceId = sessionInstanceId
//  self.sessionCookie = sessionCookie
// }
//
// func getCookie() -> String { sessionCookie }
//
// func getHost()   -> String { DefaultServerAddresses.main }
//
// internal func request(parameters: [String : Any] = [ : ],
//                       fail:    @escaping (Error) -> Void,
//                       success: @escaping (Int?, [String : Any?]) -> Void) {
//
//  let queue = DispatchQueue(label: "com.netris.echdCameraRequest",
//                            qos: .userInitiated,
//                            attributes: [.concurrent])
//
//  var parameters = parameters
//  parameters["id"] = cameraId
//  parameters["instance"] = sessionInstanceId
//
//  dataRequest = NTXECHDManager.alamofireSession
//   .request(getHost() + "/camera/ajaxGetVideoUrls",
//            method: .get,
//            parameters: parameters,
//            encoding: URLEncoding.queryString,
//            headers: getHeaders())
//   .responseJSON(queue: queue) { response in
//     if let error = response.error { fail(error) ; return }
//
//     if let json = try? response.result.get() as? [String: Any] {
//      success(response.response?.statusCode, json)
//     }
//  }
// }
//
//
//
//}


