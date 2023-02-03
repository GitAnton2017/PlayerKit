//
//  ECHD VSS Archive Photo Request.swift
//  PlayerKit
//
//  Created by Anton2016 on 11.01.2023.
//

import Combine

final class ECHDVSSArchivePhotoShotRequest: URLSessionRequestRepresentable {
 
 var requestHost: String { url + "&ts=\(depth)" }
 
 private var urlSession: URLSession { NTXECHDManager.urlSession }
 
 var dataTask: URLSessionDataTask?
 
 var sessionCookie: String
 
 private var url: String
 private var depth: Int
 
 init(archivePhotoShotURL url: String, depth: Int, sessionCookie: String) {
  self.url = url
  self.depth = depth
  self.sessionCookie = sessionCookie
  
 }
 
 init(archivePhotoShotURL url: String, depth: Int, sessionCookie: String,
      resultHandler: @escaping (Result<Data, Error>) -> ()) {
  
  self.url = url
  self.depth = depth
  self.sessionCookie = sessionCookie
  
  request(urlSession: urlSession, resultHandler: resultHandler)
 }
 

 @available(iOS 13.0, *)
 var dataPublisher: AnyPublisher<Data, Error> {
  requestPublisher(urlSession: urlSession)
 }
 
 
 @available(iOS 15.0, *)
 var data: Data {
  get async throws { try await request(urlSession: urlSession) }
 }
 
}


 /// ``VSS ARCHIVE PHOTO SHOTS REQUEST IMPLEMENTATIONS.
 ///
extension NTXECHDManager {
 
 func requestVSSArchiveShot(for VSS: ECHDCamera, depth: Int,
                            resultHandler: @escaping VSSPhotoShotRequestResultHandler) -> URLSessionRequestRepresentable? {
  
  //debugPrint("[ RESULT API ] - \(#function)")
  
  guard depth > 0 else { return nil }
  
  guard let url = VSS.getArchiveShotUrls()?.first else {
   debugPrint("[ RESULT API ] UNABLE TO PARSE ARCHIVE PHOTO SHOT CDN URL FROM VSS DATA!")
   resultHandler(.failure(EchdConnectionManagerError.noPhotoShotURL))
   return nil
  }
  
  return ECHDVSSArchivePhotoShotRequest(archivePhotoShotURL: url,
                                        depth: depth,
                                        sessionCookie: sessionCookie,
                                        resultHandler: resultHandler)
  
 }
 
 
  ///Combine based implementation.
 
 @available(iOS 13.0, *)
 func requestVSSArchiveShot(for VSS: ECHDCamera, depth: Int) -> AnyPublisher<Data, Error> {
  
  debugPrint("[ COMBINE API ] - \(#function)")
  
  guard depth > 0 else { return Empty().eraseToAnyPublisher() }
  
  guard let url = VSS.getArchiveShotUrls()?.first else {
   debugPrint("[ COMBINE API ] UNABLE TO PARSE ARCHIVE PHOTO SHOT CDN URL FROM VSS DATA!")
   return Fail<Data, Error>(error: EchdConnectionManagerError.noPhotoShotURL).eraseToAnyPublisher()
  }
  
  return ECHDVSSArchivePhotoShotRequest(archivePhotoShotURL: url,
                                        depth: depth,
                                        sessionCookie: sessionCookie).dataPublisher
  
 }
 
  ///New Swift 5.5 Async Await implementation.
 
 @available(iOS 15.0, *)
 func requestVSSArchiveShot(for VSS: ECHDCamera, depth: Int) async throws -> Data {
  
  debugPrint("[ ASYNC/AWAIT API ] - \(#function)")
  
  guard depth > 0 else { return .init() }
  
  guard let url = VSS.getArchiveShotUrls()?.first else {
   debugPrint("[ ASYNC/AWAIT API ] UNABLE TO PARSE ARCHIVE PHOTO SHOT CDN URL FROM VSS DATA!")
   throw EchdConnectionManagerError.noPhotoShotURL
  }
  
  return try await ECHDVSSArchivePhotoShotRequest(archivePhotoShotURL: url,
                                                  depth: depth,
                                                  sessionCookie: sessionCookie).data
  
 }
 
}
