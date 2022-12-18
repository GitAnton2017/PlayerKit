//
//  Player States Delegate.swift
//  PlayerKitFramework
//
//  Created by Anton2016 on 16.12.2022.
//

import UIKit

public enum NTXVideoModuleError <Device: NTXVSSSearchResultContext> {
 
 case playerFailedToAuth        (error: Error, deviceID: Device.VSSIDType)
 case playerFailedToConnect     (error: Error, deviceID: Device.VSSIDType)//
 case playerFailedToGetInfo     (error: Error, deviceID: Device.VSSIDType)
 case playerFailedToPlay        (error: Error, deviceID: Device.VSSIDType)
 case playerFailedToPlayArchive (error: Error, deviceID: Device.VSSIDType, depthSeconds: Int)
 
}

public protocol NTXVideoModuleDelegate: AnyObject {
 
 associatedtype Device: NTXVSSSearchResultContext

 func playerWillChangeState         (deviceID: Device.VSSIDType, to state:  NTXVideoPlayerStates) //
 func playerDidChangeState          (deviceID: Device.VSSIDType, to state:  NTXVideoPlayerStates) //
 func playerDidFailedWithError      (deviceID: Device.VSSIDType, with error:  NTXVideoModuleError<Device>)//
 func playerControlDidPressed       (deviceID: Device.VSSIDType, for  action: NTXPlayerActions) //
 func playerWillShutdown            (deviceID: Device.VSSIDType) //
 func playerWillPlayArchiveVideo    (deviceID: Device.VSSIDType, depthSeconds: Int)//
 func playerFinishedPlayingArchive  (deviceID: Device.VSSIDType, depthSeconds: Int)//
 func playerWillStreamLiveVideo     (deviceID: Device.VSSIDType)//
 func playerFinishedLiveStreaming   (deviceID: Device.VSSIDType)//
 func playerMovedToOwner            (deviceID: Device.VSSIDType, ownerView: UIView) //
 func playerMutedStateDidChange     (deviceID: Device.VSSIDType, muted: Bool)
 

}

public extension NTXVideoModuleDelegate {
 func playerWillChangeState         (deviceID: Device.VSSIDType, to state:  NTXVideoPlayerStates) {
  debugPrint("PLAYER DELEGATE MESSAGE <\(#function)> FROM VSS ID (\(deviceID)) State: [\(state.rawValue)]")
 }
 
 func playerDidChangeState          (deviceID: Device.VSSIDType, to state:  NTXVideoPlayerStates) {
  debugPrint("PLAYER DELEGATE MESSAGE <\(#function)> FROM VSS ID (\(deviceID)) State: [\(state.rawValue)]")
 }
 
 func playerDidFailedWithError      (deviceID: Device.VSSIDType, with error:  NTXVideoModuleError<Device>){
  debugPrint("PLAYER DELEGATE MESSAGE <\(#function)> FROM VSS ID (\(deviceID)) Error: [\(error)]")
 }
 
 func playerControlDidPressed       (deviceID: Device.VSSIDType, for  action: NTXPlayerActions) {
  debugPrint("PLAYER DELEGATE MESSAGE <\(#function)> FROM VSS ID (\(deviceID)) Action: [\(action)]")
 }
 
 func playerWillShutdown            (deviceID: Device.VSSIDType) {
  debugPrint("PLAYER DELEGATE MESSAGE <\(#function)> FROM VSS ID (\(deviceID))")
 }
 
 func playerWillPlayArchiveVideo    (deviceID: Device.VSSIDType, depthSeconds: Int){
  debugPrint("PLAYER DELEGATE MESSAGE <\(#function)> FROM VSS ID (\(deviceID) Depth = \(depthSeconds) s.")
 }
 
 func playerFinishedPlayingArchive  (deviceID: Device.VSSIDType, depthSeconds: Int){
  debugPrint("PLAYER DELEGATE MESSAGE <\(#function)> FROM VSS ID (\(deviceID) Depth = \(depthSeconds) s.")
 }
 
 func playerWillStreamLiveVideo     (deviceID: Device.VSSIDType){
  debugPrint("PLAYER DELEGATE MESSAGE <\(#function)> FROM VSS ID (\(deviceID))")
 }
 
 func playerFinishedLiveStreaming   (deviceID: Device.VSSIDType){
  debugPrint("PLAYER DELEGATE MESSAGE <\(#function)> FROM VSS ID (\(deviceID))")
 }
 
 func playerMovedToOwner            (deviceID: Device.VSSIDType, ownerView: UIView) {
  debugPrint("PLAYER DELEGATE MESSAGE <\(#function)> FROM VSS ID (\(deviceID) Owner: \(ownerView)")
 }
 
 func playerMutedStateDidChange     (deviceID: Device.VSSIDType, muted: Bool){
  debugPrint("PLAYER DELEGATE MESSAGE <\(#function)> FROM VSS ID (\(deviceID) Muted State = \(muted)")
 }
}
