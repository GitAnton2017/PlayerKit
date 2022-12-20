//
//  Player Keep Alive.swift
//  AreaSight
//
//  Created by Anton V. Kalinin on 09.12.2022.
//  Copyright © 2022 Netris. All rights reserved.
//

import Foundation

internal enum NTXKeepAliveError: Error {
 case noVSS
 case noKeepAliveService
}

internal protocol NTXPlayerKeepAliveModeRepresentable
 where Self: RawRepresentable & Codable, RawValue == String {
 
 static var liveVideo:       Self { get }
 static var liveSnapshot:    Self { get }
 static var archiveVideo:    Self { get }
 static var archiveSnapshot: Self { get }
 static var unchanged:       Self { get }
}

//IMPL:
extension ActivePlayer.Mode : NTXPlayerKeepAliveModeRepresentable {}

internal protocol NTXPlayerKeepAliveStateRepresentable
 where Self: RawRepresentable & Codable, RawValue == String  {
 static var  playing:        Self { get }
 static var  paused:         Self { get }
 static var  loading:        Self { get }
 static var  error:          Self { get }
 static var  suspended:      Self { get }
}

 //IMPL:
extension ActivePlayer.State : NTXPlayerKeepAliveStateRepresentable {}


internal protocol NTXPlayerKeepAliveArchiveRepresentable where Self: Codable  {
 var position:  Int  { get set }
 var scale:     Int  { get set }
}


 //IMPL:
extension ActivePlayer.Archive : NTXPlayerKeepAliveArchiveRepresentable {}

internal protocol NTXVSSKeepAliveServiceContext where Self: Codable {
 
 associatedtype Mode:    NTXPlayerKeepAliveModeRepresentable    ///PLAYER MODE
 associatedtype State:   NTXPlayerKeepAliveStateRepresentable   ///PLAYER STATE
 associatedtype Archive: NTXPlayerKeepAliveArchiveRepresentable ///PLAYER ARCHIVE
 
 var mode:    Mode     { get set }
 var state:   State    { get set }
 var archive: Archive? { get set }
 
 init(mode: Mode, state: State, archive: Archive?)
 
}

 //IMPL:
extension ActivePlayer: NTXVSSKeepAliveServiceContext {}

internal protocol NTXVSSKeepAliveServiceProvider where Self: NSObject {}

extension EchdKeepAliveService: NTXVSSKeepAliveServiceProvider {}
