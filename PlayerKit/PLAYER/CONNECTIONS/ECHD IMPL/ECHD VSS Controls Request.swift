//
//  ECHD VSS Controls Request.swift
//  PlayerKitFramework
//
//  Created by Anton V. Kalinin on 17.12.2022.
//

//import Alamofire

import Combine

final class ECHDVSSArchiveControlsRequest: URLSessionRequestRepresentable {
 
 var requestHost: String { url }
 
 var dataTask: URLSessionDataTask?
 private var urlSession: URLSession { NTXECHDManager.urlSession }
 
 var sessionCookie: String
 private var url: String
 
 init(archiveURL url: String, sessionCookie: String,
      resultHandler: @escaping (Result<Any, Error>) -> ()) {
  
  self.url = url
  self.sessionCookie = sessionCookie
  requestJSON(urlSession: urlSession, resultHandler: resultHandler)
 }
 
 init(archiveURL url: String, sessionCookie: String) {
  self.url = url
  self.sessionCookie = sessionCookie
 }
 
 @available(iOS 13.0, *)
 var jsonPublisher: AnyPublisher<Any, Error> { requestJSONPublisher(urlSession: urlSession) }
 
 
 @available(iOS 15.0, *)
 var jsonData: Any {
  get async throws { try await requestJSON(urlSession: urlSession) }
 }
 
 
 
}

 /// ``VSS ARCHIVE CONTROL INFORMATION CONTEXT REQUEST IMPLEMENTATIONS.
 
extension NTXECHDManager {
 
 func requestVSSArchive(for VSS: ECHDCamera,
                        resultHandler: @escaping VSSArchiveRequestResultHandler) -> URLSessionRequestRepresentable? {
  
  guard let url = VSS.getArchiveShotControlUrls()?.first else {
   debugPrint("[ RESULT API ] UNABLE TO PARSE ARCHIVE CONTROLS CDN URL FROM VSS DATA!")
   
   if #available(iOS 13.0, *) {
    if let data = try? JSONSerialization.data(withJSONObject: VSS.json as Any,
                                              options: [.withoutEscapingSlashes, .prettyPrinted]),
       let jsonStr = String(data: data, encoding: .utf8) {
     print(jsonStr)
    }
   } else {
    if let data = try? JSONSerialization.data(withJSONObject: VSS.json as Any, options: [ .prettyPrinted]),
       let jsonStr = String(data: data, encoding: .utf8) {
     print(jsonStr)
    }
   }
   
   resultHandler(.failure(EchdConnectionManagerError.noVSSControlURL))
   return nil
  }
  
  return ECHDVSSArchiveControlsRequest(archiveURL: url, sessionCookie: sessionCookie) { result in
   switch result {
    case let .success(json):
     guard let json = json as? [String : AnyObject] else {
      print("<<< --- [ RESULT API ] INVALID VSS ARCHIVE CONTROLS REQUEST JSON RESULT --- >>>\n\(json)")
      resultHandler(.failure(NTXPlayerError.invalidArchiveControlsJSONObject(json: json)))
      return
     }
     
     resultHandler(.success(.init(data: json)))
     
    case let .failure(error):
     debugPrint("<<< --- [ RESULT API ] VSS ARCHIVE CONTROLS REQUEST FAILED --- >>>\n\(error)")
     resultHandler(.failure(error))
   }
  }
  
 }
 
  ///Combine based implementation.
 
 @available(iOS 13.0, *)
 func requestVSSArchive(for VSS: ECHDCamera) -> AnyPublisher <ECHDArchiveControl, Error> {
  
  guard let url = VSS.getArchiveShotControlUrls()?.first else {
   debugPrint("[ COMBINE API ] UNABLE TO PARSE ARCHIVE CONTROLS CDN URL FROM VSS DATA!")
   return Fail<ECHDArchiveControl, Error>(error: EchdConnectionManagerError.noVSSControlURL)
    .eraseToAnyPublisher()
  }
  
  return ECHDVSSArchiveControlsRequest(archiveURL: url, sessionCookie: sessionCookie)
   .jsonPublisher
   .compactMap{ $0 as? [String : AnyObject] }
   .map{ .init(data: $0) }
   .receive(on: DispatchQueue.main)
   .eraseToAnyPublisher()
 }
 
 
  
 ///New Swift 5.5 Async Await implementation.
 
 @available(iOS 15.0, *)
 func requestVSSArchive(for VSS: ECHDCamera) async throws -> ECHDArchiveControl {
  
  guard let url = VSS.getArchiveShotControlUrls()?.first else {
   debugPrint("[ ASYNC/AWAIT API ] UNABLE TO PARSE ARCHIVE CONTROLS CDN URL FROM VSS DATA!")
   throw EchdConnectionManagerError.noVSSControlURL
  }
  
  let json = try await ECHDVSSArchiveControlsRequest(archiveURL: url, sessionCookie: sessionCookie).jsonData
  
  guard let json = json as? [String : AnyObject] else {
   debugPrint("<<< --- [ ASYNC/AWAIT API ] INVALID VSS ARCHIVE CONTROL REQUEST JSON RESULT --- >>>\n\(json)")
   throw NTXPlayerError.invalidVSSConnectionJSONObject(json: json)
  }
  
  return .init(data: json)
 }
 
}

//internal final class __ECHDVSSArchiveControlsRequest: AbstractRequest  {
//
// internal var dataRequest: DataRequest?
//
// private var url: String
// private var sessionCookie: String
//
// init(url: String, sessionCookie: String){
//  self.url = url
//  self.sessionCookie = sessionCookie
// }
//
// func getCookie() -> String { sessionCookie }
//
// internal func request(parameters: [String : Any] = [ : ],
//                       fail:    @escaping (Error) -> Void,
//                       success: @escaping (Int?, [ String : Any? ]) -> Void) {
//
//  let queue = DispatchQueue(label: "com.netris.echdArchiveControlsRequest",
//                            qos: .userInitiated,
//                            attributes: [.concurrent])
//
//  dataRequest = NTXECHDManager.alamofireSession
//   .request(url, method: .post, parameters: parameters,
//            encoding: URLEncoding.queryString,
//            headers: getHeaders() ).responseJSON(queue: queue) { response in
//             if let error = response.error {
//              fail(error)
//              return
//             }
//
//             if let json = try? response.result.get() as? [String : Any] {
//              success(response.response?.statusCode, json)
//             }
//            }
// }
//}

