//
//  Player States Delegate.swift
//  PlayerKitFramework
//
//  Created by Anton V. Kalinin on 16.12.2022.
//

import UIKit

public enum NTXVideoPlayerError <Device: NTXVSSSearchResultContext> {
 
 case playerFailedToAuth        (error: Error, deviceID: Device.VSSIDType, url: URL?)
 case playerFailedToConnect     (error: Error, deviceID: Device.VSSIDType, url: URL?)
 case playerFailedToGetInfo     (error: Error, deviceID: Device.VSSIDType, url: URL?)
 case playerFailedToPlay        (error: Error, deviceID: Device.VSSIDType, url: URL?)
 case playerFailedToPlayArchive (error: Error, deviceID: Device.VSSIDType, depthSeconds: Int, url: URL?)
 
}

public protocol NTXVideoPlayerDelegate: AnyObject {
 
 associatedtype Device: NTXVSSSearchResultContext
 
 var videoModuleDelegate: IVideoModuleDelegate? { get set }

 func playerWillChangeState         (deviceID: Device.VSSIDType, to state:    NTXVideoPlayerStates) //
 func playerDidChangeState          (deviceID: Device.VSSIDType, to state:    NTXVideoPlayerStates) //
 func playerDidFailedWithError      (deviceID: Device.VSSIDType, with error:  NTXVideoPlayerError<Device>)//
 func playerControlDidPressed       (deviceID: Device.VSSIDType, for  action: NTXPlayerActions) //
 func playerWillShutdown            (deviceID: Device.VSSIDType) //
 func playerWillPlayArchiveVideo    (deviceID: Device.VSSIDType, depthSeconds: Int)//
 func playerFinishedPlayingArchive  (deviceID: Device.VSSIDType, depthSeconds: Int)//
 func playerWillStreamLiveVideo     (deviceID: Device.VSSIDType)//
 func playerFinishedLiveStreaming   (deviceID: Device.VSSIDType)//
 func playerMovedToOwner            (deviceID: Device.VSSIDType, ownerView: UIView) //
 func playerMutedStateDidChange     (deviceID: Device.VSSIDType, muted: Bool)
 
 init ()
 
}

public extension NTXVideoPlayerDelegate {
 func playerWillChangeState         (deviceID: Device.VSSIDType, to state:  NTXVideoPlayerStates) {
//  debugPrint("PLAYER DELEGATE MESSAGE <\(#function)> FROM VSS ID (\(deviceID)) State: [\(state.rawValue)]")
  
 }
 
 func playerDidChangeState          (deviceID: Device.VSSIDType, to state:  NTXVideoPlayerStates) {
//  debugPrint("PLAYER DELEGATE MESSAGE <\(#function)> FROM VSS ID (\(deviceID)) State: [\(state.rawValue)]")
  
  videoModuleDelegate?.didChangeState(cameraId: "\(deviceID)", state: state)
 }
 
 func playerDidFailedWithError      (deviceID: Device.VSSIDType, with error:  NTXVideoPlayerError<Device>){
//  debugPrint("PLAYER DELEGATE MESSAGE <\(#function)> FROM VSS ID (\(deviceID)) Error: [\(error)]")

  switch error {
    
    
   case .playerFailedToAuth(error: let error, deviceID: let deviceID, url: let url):
    
    videoModuleDelegate?.didFailToAuth(error: .init(cameraId: "\(deviceID)",
                                                    description: error.localizedDescription,
                                                    url: url))
    
   case .playerFailedToConnect(error: let error, deviceID: let deviceID, url: let url):
    
    videoModuleDelegate?.didFailToConnect(error: .init(cameraId: "\(deviceID)",
                                                       description: error.localizedDescription,
                                                       url: url))
   case .playerFailedToGetInfo(error: let error, deviceID: let deviceID, url: let url):
    
    videoModuleDelegate?.didFailToGetInfo(error: .init(cameraId: "\(deviceID)",
                                                       description: error.localizedDescription,
                                                       url: url))
    
   case .playerFailedToPlay(error: let error, deviceID: let deviceID, url: let url):
    videoModuleDelegate?.didFailToPlay(error: .init(cameraId: "\(deviceID)",
                                                    description: error.localizedDescription,
                                                    url: url))
    
   case let .playerFailedToPlayArchive(error: error, deviceID: deviceID, depthSeconds: _ , url: url):
    videoModuleDelegate?.didFailToPlayArchive(error: .init(cameraId: "\(deviceID)",
                                                      description: error.localizedDescription,
                                                      url: url))
    
  }
 }
 
 func playerControlDidPressed       (deviceID: Device.VSSIDType, for  action: NTXPlayerActions) {
  //debugPrint("PLAYER DELEGATE MESSAGE <\(#function)> FROM VSS ID (\(deviceID)) Action: [\(action)]")
 }
 
 func playerWillShutdown            (deviceID: Device.VSSIDType) {
  //debugPrint("PLAYER DELEGATE MESSAGE <\(#function)> FROM VSS ID (\(deviceID))")
 }
 
 func playerWillPlayArchiveVideo    (deviceID: Device.VSSIDType, depthSeconds: Int){
  //debugPrint("PLAYER DELEGATE MESSAGE <\(#function)> FROM VSS ID (\(deviceID) Depth = \(depthSeconds) s.")
 }
 
 func playerFinishedPlayingArchive  (deviceID: Device.VSSIDType, depthSeconds: Int){
  //debugPrint("PLAYER DELEGATE MESSAGE <\(#function)> FROM VSS ID (\(deviceID) Depth = \(depthSeconds) s.")
 }
 
 func playerWillStreamLiveVideo     (deviceID: Device.VSSIDType){
  //debugPrint("PLAYER DELEGATE MESSAGE <\(#function)> FROM VSS ID (\(deviceID))")
 }
 
 func playerFinishedLiveStreaming   (deviceID: Device.VSSIDType){
  //debugPrint("PLAYER DELEGATE MESSAGE <\(#function)> FROM VSS ID (\(deviceID))")
 }
 
 func playerMovedToOwner            (deviceID: Device.VSSIDType, ownerView: UIView) {
  //debugPrint("PLAYER DELEGATE MESSAGE <\(#function)> FROM VSS ID (\(deviceID) Owner: \(ownerView)")
 }
 
 func playerMutedStateDidChange     (deviceID: Device.VSSIDType, muted: Bool){
  //debugPrint("PLAYER DELEGATE MESSAGE <\(#function)> FROM VSS ID (\(deviceID) Muted State = \(muted)")
 }
}


final public class DefaultPlayerDelegate: NTXVideoPlayerDelegate {
 public typealias Device = Int
 public init(){}
 public var videoModuleDelegate: IVideoModuleDelegate?
}
