//
//  ECHD VSS Live Photo Request.swift
//  PlayerKitFramework
//
//  Created by Anton V. Kalinin on 17.12.2022.
//

//import Alamofire

import Combine

final class ECHDVSSLivePhotoShotRequest: URLSessionRequestRepresentable {
 
 var requestHost: String { url }
 
 private var urlSession: URLSession { NTXECHDManager.urlSession }
 
 var dataTask: URLSessionDataTask?
 
 var sessionCookie: String
 
 private var url: String
 
 init(livePhotoShotURL url: String, sessionCookie: String) {
  self.url = url
  self.sessionCookie = sessionCookie
  
 }
 
 init(livePhotoShotURL url: String,
      sessionCookie: String,
      resultHandler: @escaping (Result<Data, Error>) -> ()) {
  
  self.url = url
  self.sessionCookie = sessionCookie
  request(urlSession: urlSession, resultHandler: resultHandler)
 }
 
 @available(iOS 13.0, *)
 var dataPublisher: AnyPublisher<Data, Error> { requestPublisher(urlSession: urlSession) }
 
 
 @available(iOS 15.0, *)
 var data: Data {
  get async throws { try await request(urlSession: urlSession) }
 }
 
}

 /// ``VSS LIVE PHOTO SHOTS REQUEST IMPLEMENTATIONS.
 
extension NTXECHDManager {
 
 func requestVSSPhotoShot(for VSS: ECHDCamera,
                          resultHandler: @escaping VSSPhotoShotRequestResultHandler) -> URLSessionRequestRepresentable? {
  
  guard let url = VSS.getLiveShotUrls()?.first else {
   debugPrint("[ RESULT API ] UNABLE TO PARSE LIVE PHOTO SHOT CDN URL FROM VSS DATA!")
   resultHandler(.failure(EchdConnectionManagerError.noPhotoShotURL))
   return nil
  }
  
  return ECHDVSSLivePhotoShotRequest(livePhotoShotURL: url,
                                     sessionCookie: sessionCookie,
                                     resultHandler: resultHandler)
 }
 
  ///Combine based implementation.
 
 @available(iOS 13.0, *)
 func requestVSSPhotoShot(for VSS: ECHDCamera) -> AnyPublisher<Data, Error> {
  
  //debugPrint("[ COMBINE API ] - \(#function)")
  
  guard let url = VSS.getLiveShotUrls()?.first else {
   debugPrint("[ COMBINE API ] UNABLE TO PARSE LIVE PHOTO SHOT CDN URL FROM VSS DATA!")
   return Fail<Data, Error>(error: EchdConnectionManagerError.noPhotoShotURL).eraseToAnyPublisher()
  }
  
  return ECHDVSSLivePhotoShotRequest(livePhotoShotURL: url,
                                     sessionCookie: sessionCookie).dataPublisher
  
 }
  ///New Swift 5.5 Async Await implementation.
 
 @available(iOS 15.0, *)
 func requestVSSPhotoShot(for VSS: ECHDCamera) async throws  -> Data {
  
  debugPrint("[ ASYNC/AWAIT API ] - \(#function)")
  
  guard let url = VSS.getLiveShotUrls()?.first else {
   debugPrint("[ ASYNC/AWAIT API ] UNABLE TO PARSE LIVE PHOTO SHOT CDN URL FROM VSS DATA!")
   throw EchdConnectionManagerError.noPhotoShotURL
  }
  
  return try await ECHDVSSLivePhotoShotRequest(livePhotoShotURL: url, sessionCookie: sessionCookie).data
 }
}


//internal final class ECHDPhotoRequest: AbstractRequest {
//
// internal var dataRequest: DataRequest?
//
// private var url: String
// private var sessionCookie: String
//
// init(url: String, sessionCookie: String){
//  self.url = url
//  self.sessionCookie = sessionCookie
//
// }
//
// func getCookie() -> String { sessionCookie }
//
// internal func request(parameters: [String : Any] = [:],
//                       fail:    @escaping (Error) -> (),
//                       success: @escaping (Int?, [String : Any?]) -> () ) {
//
//  let queue = DispatchQueue(label: "com.netris.echdMakePhotoRequest",
//                            qos: .userInitiated,
//                            attributes: [.concurrent])
//
//  dataRequest = NTXECHDManager.alamofireSession
//   .request( url, method: .get,
//             parameters: parameters,
//             headers: getHeaders())
//   .responseData(queue: queue) { response in
//    guard response.error == nil else {
//     fail(response.error!)
//     return
//    }
//
//    if let imageData = response.data {
//     success(response.response?.statusCode, ["image": imageData])
//    }
//   }
// }
//}
