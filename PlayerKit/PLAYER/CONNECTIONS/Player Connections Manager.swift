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
 ///
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
 associatedtype InputDevice             : NTXVSSSearchResultContext
 associatedtype PhotoShot               : UIImageConvertable
 
 //KEEP ALIVE SERVICE ABSTRACTIONS
 associatedtype KeepAliveState   : NTXVSSKeepAliveServiceContext
 associatedtype KeepAliveService : NTXVSSKeepAliveServiceProvider
 
 
 /// The adaptor should implement Keep Alive beating service method.
 var keepAliveService: KeepAliveService? { get set }

 func changeVSSStateForBeating(activePlayerState: KeepAliveState,
                               for inputVSS:      InputDevice) throws
 
  /// The adaptor should implement camera (VSS) connection request method from client service.
 typealias VSSRequestResultHandler = (Result<Device, Error>) -> ()
 
 func requestVSSConnection(from searchResult: InputDevice,
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
 
  /// The adaptor should implement method for fetching client security server marker to be used to generate player admixture view.
 
 typealias SecurityMarkerRequestHandler = (Result<String, Error>) -> ()
 
 func requestClientSecurityMarker(resultHandler: @escaping SecurityMarkerRequestHandler) -> AbstractRequest?
 
  /// The adaptor should implement method for fetching short camera description information from server.
 
 typealias VSSShortDescriptionRequestHandler = (Result<VSSShortDescription?, Error>) -> ()
 
 func requestVSSShortDescription(for device: InputDevice,
                                 resultHandler: @escaping VSSShortDescriptionRequestHandler ) -> AbstractRequest?
 
}




@available(iOS 13.0, *)
internal extension NTXPlayerConnectionsManager {
 
}

@available(iOS 15.0, *)
internal extension NTXPlayerConnectionsManager {
 
}








