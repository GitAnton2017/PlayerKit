//
//  ECHD Connections.swift
//  PlayerKitFramework
//
//  Created by Anton2016 on 16.12.2022.
//


public struct NTXCredentials: Codable {
 
 public var token: String
 public var sessionId: String
 
 public init(token: String, sessionId: String) {
  self.token = token
  self.sessionId = sessionId
 }
 
}

import Foundation
import Alamofire

internal class NTXECHDManager: NSObject, NTXPlayerConnectionsManager {
 
 struct DefaultServerAddresses {
  
  static let main = DefaultServerAddresses.setServerAddress()
   // В данный момент совпадает с главным хостом
  
  static let test = DefaultServerAddresses.setServerAddress()
  
  static let mainPortal = "https://echd.mos.ru"
  static let testPortal = "https://echd.mos.ru"
  static let testPortalWithoutPort = "https://testportal-echd.mos.ru:1443"
  static let demoPortal = "https://demoportal-echd.mos.ru"
  static let demoPortalWithPort = "https://demoportal-echd.mos.ru:1443"
  static let stage60 = "https://stage60-echd.mos.ru"
  
  static func setServerAddress() -> String {
 #if PROFILE_ALPHA
   return DefaultServerAddresses.mainPortal
 #else
   return DefaultServerAddresses.mainPortal
 #endif
  }
 }
 
 init(credentials: NTXCredentials) {
  self.credentials = credentials
  super.init()
  
 }
 
 static var alamofireSession: Session = {
  let urlSessionConfig = URLSessionConfiguration.default
  urlSessionConfig.timeoutIntervalForResource = Time.timeoutForRequests
  urlSessionConfig.timeoutIntervalForRequest = Time.timeoutForRequests
  urlSessionConfig.waitsForConnectivity = true
  urlSessionConfig.urlCache = nil
  urlSessionConfig.requestCachePolicy = .reloadIgnoringLocalCacheData
  let session = Session(configuration: urlSessionConfig)
  
  return session
 }()
 
 
 let credentials: NTXCredentials
 
 internal var sessionCookie: String {
  "JSESSIONID=\(credentials.sessionId);" + "grails_remember_me=\(credentials.token);"
 }
 
 var cameraRequest          : ECHDVSSRequest?
 var archiveControlsRequest : ECHDVSSArchiveControlsRequest?
 var photoRequest           : ECHDPhotoRequest?
 
 
 internal typealias InputDevice     = Int
 internal typealias Device          = EchdCamera
 internal typealias ArchiveControl  = EchdArchiveControl
 internal typealias PhotoShot       = Data
 
 internal typealias KeepAliveState   = ActivePlayer
 internal typealias KeepAliveService = EchdKeepAliveService
 
    
 internal var keepAliveService: KeepAliveService?
 
 internal func changeVSSStateForBeating(activePlayerState: KeepAliveState,
                                        for inputVSS:      InputDevice)  throws {
  
  debugPrint (#function, activePlayerState, inputVSS)
  
  let id = inputVSS.id
  
  guard let keepAliveService = keepAliveService else {
   debugPrint (#function, "No Keep Alive Service is running for VSS: \(id)")
   return
  }
  
  keepAliveService.payload.id.insert(id)
  
  guard activePlayerState.mode == .unchanged,
        let currentActivePlayers = keepAliveService.payload.players[id],
        var currentActivePlayerState = currentActivePlayers.first else {
   
   keepAliveService.payload.players[id] = [activePlayerState]
   return
  }
  
  currentActivePlayerState.state = activePlayerState.state
  
  if let archive = activePlayerState.archive,
     currentActivePlayerState.mode == .archiveVideo ||
      currentActivePlayerState.mode == .archiveSnapshot {
   
   currentActivePlayerState.archive = archive
  }
  
  keepAliveService.payload.players[id] = [currentActivePlayerState]
  
 }
 
  /// VSS CONNECTION REQUEST IMPL.
  ///
 internal func requestVSSConnection(from searchResult: InputDevice,
                                    resultHandler: @escaping VSSRequestResultHandler) -> AbstractRequest? {
  
  
  let cameraRequest = ECHDVSSRequest(cameraId: searchResult.id, sessionCookie: sessionCookie )
  
  self.cameraRequest = cameraRequest
  
  cameraRequest.request{ error in
   resultHandler(.failure(error))
   
  } success: { ( httpStatusCode, json ) in
   if let code = httpStatusCode, (400...404).contains(code) {
    resultHandler(.failure(NTXPlayerError.unauthorized(code: code)))
    return
   }
   
   resultHandler(.success(.init(data: json as [String : AnyObject])))
  }
  
  
  return cameraRequest
  
 }
 
  /// VSS ARCHIVE CONTROL INFORMATION CONTEXT REQUEST IMPL.
 internal func requestVSSArchive(for VSS: EchdCamera,
                                 resultHandler: @escaping VSSArchiveRequestResultHandler) -> AbstractRequest? {
  
  
  guard let url = VSS.getArchiveShotControlUrls()?.first else {
   resultHandler(.failure(EchdConnectionManagerError.noVSSControlURL))
   return nil
  }
  
  let archiveControlsRequest = ECHDVSSArchiveControlsRequest(url: url, sessionCookie: sessionCookie)
  self.archiveControlsRequest = archiveControlsRequest
  
  archiveControlsRequest.request{ error in
   resultHandler(.failure(error))
  } success: { ( httpStatusCode, json ) in
   resultHandler(.success(.init(data: json as [String : AnyObject])))
  }
  
  return archiveControlsRequest
  
 }
 
 internal func requestVSSPhotoShot(for VSS: EchdCamera,
                                   resultHandler: @escaping VSSPhotoShotRequestResultHandler) -> AbstractRequest? {
  
  
  guard let url = VSS.getLiveShotUrls()?.first else {
   resultHandler(.failure(EchdConnectionManagerError.noPhotoShotURL))
   return nil
  }
  
  let photoRequest = ECHDPhotoRequest(url: url, sessionCookie: sessionCookie)
  
  self.photoRequest = photoRequest
  
  photoRequest.request{ error in
   resultHandler(.failure(error))
   
  } success: { ( httpStatuscode, response ) in
   guard let data = response["image"] as? Data else {
    resultHandler(.failure(EchdConnectionManagerError.invalidPhotoShotData))
    return
   }
   
   resultHandler(.success(data))
   
  }
  
  return photoRequest
 }
 
 
 internal func requestVSSArchiveShot(for VSS: EchdCamera,
                                     depth: Int,
                                     resultHandler: @escaping VSSPhotoShotRequestResultHandler) -> AbstractRequest? {
  guard depth > 0 else { return nil }
  
  guard let url = VSS.getArchiveShotUrls()?.first else {
   resultHandler(.failure(EchdConnectionManagerError.noPhotoShotURL))
   return nil
  }
  
  let shotURLString = url + "&ts=\(depth)"
  
  let photoRequest = EchdMakePhotoRequest(url: shotURLString, camera: 0)
  
  photoRequest.request{ error in
   resultHandler(.failure(error))
   
  } success: { ( httpStatuscode, response ) in
   guard let data = response["image"] as? Data else {
    resultHandler(.failure(EchdConnectionManagerError.invalidPhotoShotData))
    return
   }
   
   resultHandler(.success(data))
   
  }
  return photoRequest
 }
 
 
 
 
 
 
}
