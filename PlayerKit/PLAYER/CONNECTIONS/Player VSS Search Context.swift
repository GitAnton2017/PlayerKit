//
//  Player VSS Context.swift
//  AreaSightDemo
//
//  Created by Anton V. Kalinin on 05.12.2022.
//  Copyright © 2022 Netris. All rights reserved.
//

import Foundation

/// The protocol that defined player interface object that is used as an input search VSS result from client
/// It might be a any id representable type convertable to Int.

public protocol NTXVSSSearchResultContext {
 
 associatedtype VSSIDType
 var id: VSSIDType  { get }
}


extension Int: NTXVSSSearchResultContext {
 public var id: Self { self }
}

extension String : NTXVSSSearchResultContext {
 public var id: Int? { .init(self) }
}
