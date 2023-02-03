//
//  ECHD Server Settings Request.swift
//  PlayerKit
//
//  Created by Anton2016 on 27.12.2022.
//


//import Alamofire

import Combine

final class ECHDServerSettingsRequest: URLSessionRequestRepresentable {
 
 private let endPoint = "/settings/ajaxGetSettings"
 private var urlSession: URLSession { NTXECHDManager.urlSession }
 
 var requestHeaders: [ String : String ]  {
  [ "X-Requested-With" : "XMLHttpRequest",
    "Cookie"           : sessionCookie,
    "User-Agent"       : userAgent   ]
  
 }
 
 var dataTask: URLSessionDataTask?
 
 var sessionCookie: String
 
 init(sessionCookie: String){
  self.sessionCookie = sessionCookie
 }
 
 init(sessionCookie: String, resultHandler: @escaping (Result<Any, Error>) -> ()) {
  
  self.sessionCookie = sessionCookie
  
  requestJSON(endPoint: endPoint, urlSession: urlSession,
              queryParameters: [.init(name: "source", value: "user,environment,mw-portal")],
              resultHandler: resultHandler)
 }
 
 @available(iOS 13.0, *)
 var jsonPublisher: AnyPublisher<Any, Error> {
  requestJSONPublisher(endPoint: endPoint,
                       urlSession: urlSession,
                       queryParameters: [.init(name: "source", value: "user,environment,mw-portal")])
 }
 
 
 
 @available(iOS 15.0, *)
 var jsonData: Any {
  get async throws {
   try await requestJSON(endPoint: endPoint,
                         urlSession: urlSession,
                         queryParameters: [.init(name: "source", value: "user,environment,mw-portal")])
  }
 }
 
}


 /// ``ECHD SECURITY SETTINGS REQUEST IMPLEMENTATIONS.
 
extension NTXECHDManager {
 
 func requestClientSecurityMarker(resultHandler: @escaping SecurityMarkerRequestHandler) -> URLSessionRequestRepresentable? {
  
  debugPrint("[ RESULT API ] - \(#function)")
  
  if let securityMarker = self.securityMarker {
   resultHandler(.success(securityMarker))
   return nil
  }
  
  return ECHDServerSettingsRequest(sessionCookie: sessionCookie) { [ weak self] result in
   
   guard let self = self else { return }
   
   switch result {
    case let .success(json):
     
     guard let json = json as? [String : AnyObject] else {
      debugPrint("<<< --- [ RESULT API ] INVALID SETTINGS REQUEST JSON RESULT --- >>>\n\(json)")
      resultHandler(.failure(NTXPlayerError.invalidSettingsJSONObject(json: json)))
      return
     }
     
     guard let environment = json["environment"] as? [ String : AnyObject ] else {
      debugPrint("<<< --- [ RESULT API ] INVALID SETTINGS REQUEST JSON RESULT --- >>>\n\(json)")
      resultHandler(.failure(EchdConnectionManagerError.invalidSecurityData(json: json as [String : Any])))
      return
     }
     
     guard let userProfile = environment["userProfile"] as? [ String : AnyObject ] else {
      debugPrint("<<< --- [ RESULT API ] INVALID SETTINGS REQUEST JSON RESULT --- >>>\n\(json)")
      resultHandler(.failure(EchdConnectionManagerError.invalidSecurityData(json: environment as [String : Any])))
      return
     }
     
     guard let securityMarker = userProfile["securityMarker"] as? String else {
      debugPrint("<<< --- [ RESULT API ] INVALID SETTINGS REQUEST JSON RESULT --- >>>\n\(json)")
      resultHandler(.failure(EchdConnectionManagerError.invalidSecurityData(json: userProfile as [String : Any])))
      return
     }
     
     DispatchQueue.main.async { [ weak self ] in self?.securityMarker = securityMarker }
     
     resultHandler(.success(securityMarker))
     
    case let .failure(error):
     debugPrint("<<< --- [ RESULT API ] SETTINGS REQUEST FAILED --- >>>\n\(error)")
     resultHandler(.failure(error))
   }
   
   
   
  }
 }
 
 
  ///Combine based implementation.
 
 @available(iOS 13.0, *)
 func requestClientSecurityMarker() -> AnyPublisher<String, Error> {
  
  debugPrint("[ COMBINE API ] - \(#function)")
  
  if let securityMarker = self.securityMarker {
   return Just(securityMarker).setFailureType(to: Error.self).eraseToAnyPublisher()
  }
  
  return ECHDServerSettingsRequest(sessionCookie: sessionCookie)
   .jsonPublisher
   .tryMap{ ( json: Any ) -> String in
    guard let json = json as? [String : AnyObject] else {
     debugPrint("<<< --- [ COMBINE API ] INVALID SETTINGS REQUEST JSON RESULT --- >>>\n\(json)")
     throw NTXPlayerError.invalidSettingsJSONObject(json: json)
    }
    
    guard let environment = json["environment"] as? [ String : AnyObject ] else {
     debugPrint("<<< --- [ COMBINE API ] INVALID SETTINGS REQUEST JSON RESULT --- >>>\n\(json)")
     throw EchdConnectionManagerError.invalidSecurityData(json: json as [String : Any])
    }
    
    guard let userProfile = environment["userProfile"] as? [ String : AnyObject ] else {
     debugPrint("<<< --- [ COMBINE API ] INVALID SETTINGS REQUEST JSON RESULT --- >>>\n\(json)")
     throw EchdConnectionManagerError.invalidSecurityData(json: environment as [String : Any])
    }
    
    guard let securityMarker = userProfile["securityMarker"] as? String else {
     debugPrint("<<< --- [ COMBINE API ] INVALID SETTINGS REQUEST JSON RESULT --- >>>\n\(json)")
     throw EchdConnectionManagerError.invalidSecurityData(json: userProfile as [String : Any])
    }
    
    return securityMarker
   }
   .receive(on: DispatchQueue.main)
   .handleEvents(receiveOutput: { [ weak self ] in self?.securityMarker = $0 })
   .eraseToAnyPublisher()
  
 }
 
  ///New Swift 5.5 Async Await implementation.
 
 @available(iOS 15.0, *)
 func requestClientSecurityMarker() async throws -> String {
  
  debugPrint("[ ASYNC/AWAIT API ] - \(#function)")
  
  if let securityMarker = self.securityMarker { return securityMarker }
  
  let json = try await ECHDServerSettingsRequest(sessionCookie: sessionCookie).jsonData
  
  guard let json = json as? [String : AnyObject] else {
   debugPrint("<<< --- [ ASYNC/AWAIT API ] INVALID SETTINGS REQUEST JSON RESULT --- >>>\n\(json)")
   throw NTXPlayerError.invalidSettingsJSONObject(json: json)
  }
  
  guard let environment = json["environment"] as? [ String : AnyObject ] else {
   debugPrint("<<< --- [ ASYNC/AWAIT API ] INVALID SETTINGS REQUEST JSON RESULT --- >>>\n\(json)")
   throw EchdConnectionManagerError.invalidSecurityData(json: json as [String : Any])
  }
  
  guard let userProfile = environment["userProfile"] as? [ String : AnyObject ] else {
   debugPrint("<<< --- [ ASYNC/AWAIT API ] INVALID SETTINGS REQUEST JSON RESULT --- >>>\n\(json)")
   throw EchdConnectionManagerError.invalidSecurityData(json: environment as [String : Any])
  }
  
  guard let securityMarker = userProfile["securityMarker"] as? String else {
   debugPrint("<<< --- [ ASYNC/AWAIT API ] INVALID SETTINGS REQUEST JSON RESULT --- >>>\n\(json)")
   throw EchdConnectionManagerError.invalidSecurityData(json: userProfile as [String : Any])
  }
  
  await MainActor.run { self.securityMarker = securityMarker }
  
  return securityMarker
  
  
 }
}

//internal final class __ECHDServerSettingsRequest: AbstractRequest {
//
// var dataRequest: DataRequest?
//
// private var sessionCookie: String
//
// init(sessionCookie: String){
//  self.sessionCookie = sessionCookie
// }
//
// func getCookie() -> String { sessionCookie }
//
// func getHost()   -> String { DefaultServerAddresses.main }
//
// func request(parameters: [String : Any] = [:],
//              fail:       @escaping (Error) -> Void,
//              success:    @escaping (Int?, [String : Any?]) -> Void) {
//
//  let queue = DispatchQueue(label:  "com.netris.echdSettingsRequest",
//                            qos:    .userInitiated,
//                            attributes: [ .concurrent ])
//
//  var headers = getHeaders()
//
//  headers["Content-Type"] = nil
//
//  let endPoint = getHost() + "/settings/ajaxGetSettings?source=user,environment,mw-portal"
//
//  dataRequest = NTXECHDManager.alamofireSession.request( endPoint,
//                                                         method: .get,
//                                                         headers: headers)
//   .responseJSON(queue: queue) { response in
//
//    switch response.result {
//     case .success:
//      guard let json = try? response.result.get() as? [String : Any]  else {
//       debugPrint("EchdSettingsRequest::request: Wrong data: \(String(describing: response.result))")
//
//       fail(NSError(domain: "EchdSettingsRequest::request", code: 206,
//                    userInfo: [NSLocalizedDescriptionKey: response.result]))
//
//       return
//      }
//
//      success(response.response?.statusCode, json)
//
//     case .failure(let error):
//      debugPrint("EchdSettingsRequest::request:(2): \(error)")
//
//      fail(error)
//    }
//   }
// }
//}

