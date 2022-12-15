//
//  Player VSS Context.swift
//  AreaSightDemo
//
//  Created by Anton V. Kalinin on 05.12.2022.
//  Copyright © 2022 Netris. All rights reserved.
//

import Foundation

//The protocol that defined player interface object that is used as an input search VSS result from client
internal protocol NTXVSSSearchResultContext where Self: NSObject {
 associatedtype VSSIDType
 var id: VSSIDType { get set }
}

extension EchdSearchCamera: NTXVSSSearchResultContext {}
