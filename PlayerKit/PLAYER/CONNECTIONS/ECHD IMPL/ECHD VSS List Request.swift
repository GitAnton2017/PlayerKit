//
//  ECHD VSS List Request.swift
//  PlayerKit
//
//  Created by Anton2016 on 27.12.2022.
//

//import Alamofire

import Combine

class ECHDVSSListRequest: URLSessionRequestRepresentable {
 
 private let endPoint = "/camera/ajaxSearchCameraList"
 
 private var urlSession: URLSession { NTXECHDManager.urlSession }
 
 var dataTask: URLSessionDataTask?
 
 var sessionCookie: String
 
 private var cameraIDs: [ Int ]
 
 init(cameraIDs: [ Int ], sessionCookie: String) {
  self.cameraIDs = cameraIDs
  self.sessionCookie = sessionCookie
 }
 
 init(cameraIDs: [ Int ], sessionCookie: String, resultHandler: @escaping (Result<Any, Error>) -> ()) {
  
  self.cameraIDs = cameraIDs
  self.sessionCookie = sessionCookie
  
  requestJSON(endPoint: endPoint,
              urlSession: urlSession,
              bodyParameters: ["filter" : ["cameras" : cameraIDs ]],
              httpMethod: .post,
              resultHandler: resultHandler)
 }
 
 @available(iOS 13.0, *)
 var jsonPublisher: AnyPublisher<Any, Error> {
  requestJSONPublisher(endPoint: endPoint,
                       urlSession: urlSession,
                       bodyParameters: ["filter" : ["cameras" : cameraIDs ]],
                       httpMethod: .post)
 }
 
 
 
 @available(iOS 15.0, *)
 var jsonData: Any {
  get async throws {
   try await requestJSON(endPoint: endPoint,
                         urlSession: urlSession,
                         bodyParameters: ["filter" : ["cameras" : cameraIDs ]],
                         httpMethod: .post)
  }
 }
 
}


extension NTXECHDManager {
 
 func requestVSSShortDescription(for device: InputDevice,
                                 resultHandler: @escaping VSSShortDescriptionRequestHandler ) -> URLSessionRequestRepresentable? {
  
  ECHDVSSListRequest(cameraIDs: [device.id], sessionCookie: sessionCookie) { result in
   
   switch result {
     
    case let .success(json):
     
     guard let json = json as? [String : AnyObject] else {
      debugPrint("<<< --- [ RESULT API ] INVALID VSS LIST REQUEST JSON RESULT --- >>>\n\(json)")
      resultHandler(.failure(NTXPlayerError.invalidSettingsJSONObject(json: json)))
      return
     }
     
     guard let success = json["success"] as? Bool, success else {
      debugPrint("<<< --- [ RESULT API ] INVALID VSS LIST REQUEST JSON RESULT --- >>>\n\(json)")
      resultHandler(.failure(EchdConnectionManagerError.invalidCameraDescriptionData(json: json as [String : Any])))
      return
     }
     
     guard let cameras = json["cameras"] as? [ [String : Any] ]  else {
      debugPrint("<<< --- [ RESULT API ] INVALID VSS LIST REQUEST JSON RESULT --- >>>\n\(json)")
      resultHandler(.failure(EchdConnectionManagerError.invalidCameraDescriptionData(json: json as [String : Any])))
      return
     }
     
     guard let camera = cameras.first else { resultHandler(.success(nil)); return }
     
     resultHandler(.success(.init(json: camera)))
     
    case let .failure(error):
     debugPrint("<<< --- [ RESULT API ] VSS LIST REQUEST FAILED --- >>>\n\(error)")
     resultHandler(.failure(error))
   }
   
  }
 }
 
 
 
  ///Combine based implementation.
 
 @available(iOS 13.0, *)
 func requestVSSShortDescription(for device: Int) -> AnyPublisher<VSSShortDescription?, Error> {
  
  ECHDVSSListRequest(cameraIDs: [device.id], sessionCookie: sessionCookie)
   .jsonPublisher
   .tryMap { (json: Any) -> VSSShortDescription? in
    guard let json = json as? [String : AnyObject] else {
     debugPrint("<<< --- [ COMBINE API ] INVALID VSS LIST REQUEST JSON RESULT --- >>>\n\(json)")
     throw NTXPlayerError.invalidSettingsJSONObject(json: json)
    }
    
    guard let success = json["success"] as? Bool, success else {
     debugPrint("<<< --- [ COMBINE API ] INVALID VSS LIST REQUEST JSON RESULT --- >>>\n\(json)")
     throw EchdConnectionManagerError.invalidCameraDescriptionData(json: json as [String : Any])
    }
    
    guard let cameras = json["cameras"] as? [ [String : Any] ]  else {
     debugPrint("<<< --- [ COMBINE API ] INVALID VSS LIST REQUEST JSON RESULT --- >>>\n\(json)")
     throw EchdConnectionManagerError.invalidCameraDescriptionData(json: json as [String : Any])
    }
    
    guard let camera = cameras.first else { return nil }
    
    return .init(json: camera)
    
   }
   .receive(on: DispatchQueue.main)
   .eraseToAnyPublisher()
 }
 
 
 
  ///New Swift 5.5 Async Await implementation.
 
 @available(iOS 15.0, *)
 func requestVSSShortDescription(for device: Int) async throws -> VSSShortDescription? {
  
  let json = try await ECHDVSSListRequest(cameraIDs: [device.id], sessionCookie: sessionCookie).jsonData
  
  guard let json = json as? [String : AnyObject] else {
   debugPrint("<<< --- [ ASYNC/AWAIT API ] INVALID VSS LIST REQUEST JSON RESULT --- >>>\n\(json)")
   throw NTXPlayerError.invalidSettingsJSONObject(json: json)
  }
  
  guard let success = json["success"] as? Bool, success else {
   debugPrint("<<< --- [ ASYNC/AWAIT API ] INVALID VSS LIST REQUEST JSON RESULT --- >>>\n\(json)")
   throw EchdConnectionManagerError.invalidCameraDescriptionData(json: json as [String : Any])
  }
  
  guard let cameras = json["cameras"] as? [ [String : Any] ]  else {
   debugPrint("<<< --- [ ASYNC/AWAIT API ] INVALID VSS LIST REQUEST JSON RESULT --- >>>\n\(json)")
   throw EchdConnectionManagerError.invalidCameraDescriptionData(json: json as [String : Any])
  }
  
  guard let camera = cameras.first else { return nil }
  
  return .init(json: camera)
 }
 
}

//class __ECHDVSSListRequest: AbstractRequest {
//
// var dataRequest: DataRequest?
//
// func getCookie() -> String { sessionCookie }
//
// func getHost()   -> String { DefaultServerAddresses.main }
//
// private var sessionCookie: String
// private var cameraIDs: [ Int ]
//
// init(cameraIDs: [ Int ], sessionCookie: String) {
//  self.cameraIDs = cameraIDs
//  self.sessionCookie = sessionCookie
// }
//
//
//
//
// func request(parameters: [String : Any] = [ : ],
//              fail: @escaping (Error) -> Void,
//              success: @escaping (Int?, [ String : Any? ]) -> Void) {
//
//  var filtered = parameters
//
//  filtered["filter"] = ["cameras" : cameraIDs ]
//
//  let queue = DispatchQueue(label: "com.netris.echdSearchCameraListRequest",
//                            qos: .userInitiated,
//                            attributes: [.concurrent])
//
//  dataRequest = NTXECHDManager.alamofireSession.request(
//   getHost() + "/camera/ajaxSearchCameraList",
//   method: .post,
//   parameters: filtered,
//   encoding: JSONEncoding.default,
//   headers: getHeaders()).responseJSON(queue: queue) { response in
//    switch response.result {
//
//     case .success:
//      guard let json = response.value as? [ String : Any ] else {
//
//       fail(NSError(domain: "EchdSearchCameraListRequest::request",
//                    code: 406,
//                    userInfo: [NSLocalizedFailureReasonErrorKey: "error_invalid_json"]))
//       return
//      }
//
////      debugPrint(#function, json)
//      success(response.response?.statusCode, json)
//
//     case .failure(let error):
//      debugPrint("EchdSearchCameraListRequest::request: \(error)")
//
//      fail(error)
//    }
//  }
// }
//}
