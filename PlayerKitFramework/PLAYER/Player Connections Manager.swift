//
//  Player Connections Manager.swift
//  AreaSightDemo
//
//  Created by Anton V. Kalinin on 03.12.2022.
//  Copyright © 2022 Netris. All rights reserved.
//

import Foundation
import UIKit

 ///#Photoshot image data request should return data convertable to UIImage data representation.
internal protocol UIImageConvertable {
 var uiImage: UIImage? { get }
}


extension Data: UIImageConvertable {
 internal var uiImage: UIImage? { .init(data: self) }
}

///#The Prayer Adapter Protocol providing needed interface for remote connections from any type of the client app connections manager.
///
internal protocol NTXPlayerConnectionsManager where Self: NSObject {
 
 associatedtype Device                  : NTXVSSDeviceRequestContext
 associatedtype ArchiveControl          : NTXVSSArchiveControlContext
 associatedtype SearchResult            : NTXVSSSearchResultContext
 associatedtype PhotoShot               : UIImageConvertable
 
 //KEEP ALIVE SERVICE ABSTRACTIONS
 associatedtype KeepAliveState   : NTXVSSKeepAliveServiceContext
 associatedtype KeepAliveService : NTXVSSKeepAliveServiceProvider
 
 
 /// The adaptor should implement Keep Alive beating service method.
 var keepAliveService: KeepAliveService? { get set }

 func changeVSSStateForBeating(activePlayerState: KeepAliveState,
                               for inputVSS: SearchResult) throws
 
  /// The adaptor should implement camera (VSS) connection request method from client service.
 typealias VSSRequestResultHandler = (Result<Device, Error>) -> ()
 
 func requestVSSConnection(from searchResult: SearchResult,
                 resultHandler: @escaping VSSRequestResultHandler) -> AbstractRequest?
 
  /// The adaptor should implement method for fetching VSS archive context data from client service.
 typealias VSSArchiveRequestResultHandler = (Result<ArchiveControl, Error>) -> ()
 
 func requestVSSArchive(for VSS: Device,
                     resultHandler: @escaping VSSArchiveRequestResultHandler) -> AbstractRequest?
 
 
  /// The adaptor should implement method for fetching live photoshot image data from client service.
 typealias VSSPhotoShotRequestResultHandler = (Result<PhotoShot, Error>) -> ()
 
 func requestVSSPhotoShot(for VSS: Device,
                          resultHandler: @escaping VSSPhotoShotRequestResultHandler) -> AbstractRequest?
 
  /// The adaptor should implement method for fetching archive photoshot image data from client service.
  
 func requestVSSArchiveShot(for VSS: Device,
                            depth: Int,
                            resultHandler: @escaping VSSPhotoShotRequestResultHandler) -> AbstractRequest?
 
 
}


@available(iOS 13.0, *)
internal extension NTXPlayerConnectionsManager {
 
}

@available(iOS 15.0, *)
internal extension NTXPlayerConnectionsManager {
 
}


///CONNECTIONS MANAGER ADAPTOR IMPL.
extension EchdConnectionManager: NTXPlayerConnectionsManager {
 
 internal typealias Cancellable     = AbstractRequest
 internal typealias SearchResult    = EchdSearchCamera
 internal typealias Device          = EchdCamera
 internal typealias ArchiveControl  = EchdArchiveControl
 internal typealias PhotoShot       = Data
 
 internal typealias KeepAliveState = ActivePlayer
 internal typealias KeepAliveService = EchdKeepAliveService

 /// KEEP ALIVE IMPL.

 internal func changeVSSStateForBeating(activePlayerState: KeepAliveState,
                                      for inputVSS:      SearchResult)  throws {
  
  debugPrint (#function, activePlayerState, inputVSS)
  
  guard let id = inputVSS.id else { throw NTXKeepAliveError.noVSS }
  guard let keepAliveService = keepAliveService else { throw NTXKeepAliveError.noKeepAliveService}
 
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
 internal func requestVSSConnection(from searchResult: EchdSearchCamera,
                                  resultHandler: @escaping VSSRequestResultHandler) -> AbstractRequest? {
  guard getCookie() != nil else {
   
   let cookieError = NSError(domain: "EchdConnectionManager::requestCamera",
                             code: 401,
                             userInfo: [ NSLocalizedDescriptionKey        : "" ,
                                         NSLocalizedFailureReasonErrorKey : "no_auth_dat" ])
   
   debugPrint("EchdConnectionManager::requestCamera: \(cookieError)")
   
   resultHandler(.failure(cookieError))
   return nil
  
  }
  
  guard let VSS_ID = searchResult.id else {
   resultHandler(.failure(EchdConnectionManagerError.noVSS))
   return nil
  }
  
  let cameraRequest = EchdCameraRequest(cameraId: VSS_ID,
                                        sessionInstanceId: settingsService?.sessionInstanceId ?? 0)
  
  self.cameraRequest = cameraRequest
  
  cameraRequest.request{ error in
   resultHandler(.failure(error))
   
  } success: { ( httpStatusCode, json ) in
   resultHandler(.success(.init(data: json as [String : AnyObject])))
  }
  
  
  return cameraRequest
  
 }
 
 /// VSS ARCHIVE CONTROL INFORMATION CONTEXT REQUEST IMPL.
 internal func requestVSSArchive(for VSS: EchdCamera,
                               resultHandler: @escaping VSSArchiveRequestResultHandler) -> AbstractRequest? {
  guard getCookie() != nil else {
   let cookieError = NSError(domain: "EchdConnectionManager::requestArchiveControls",
                             code: 401,
                             userInfo: [ NSLocalizedDescriptionKey: "",
                                         NSLocalizedFailureReasonErrorKey: "no_auth_data" ])
   
   debugPrint("EchdConnectionManager::requestArchiveControls: \(cookieError)")
   
   resultHandler(.failure(cookieError))
   return nil
  }
  
  guard let url = VSS.getArchiveShotControlUrls()?.first else {
   resultHandler(.failure(EchdConnectionManagerError.noVSSControlURL))
   return nil
  }
  
  let archiveControlsRequest = EchdArchiveControlsRequest(url: url)
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
  
  let photoRequest = EchdMakePhotoRequest(url: url, camera: 0)
  
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






