//
//  Region.swift
//  JsonParser
//
//  Created by Artem Lytkin on 25/02/2019.
//  Copyright © 2019 Artem Lytkin. All rights reserved.
//

import Foundation

final class RegionNode: FilterNodeProtocol {
    
    var id: Int?
    var name: String?
    var children: [FilterNodeProtocol] = []
    var selected: Bool = true
    
    var geoDataIds: [Int]?
    
    private enum CodingKeys: String, CodingKey {
        case name
        case selected
        case id
        case geoDataIds
    }
    
    var color: String?
}

extension RegionNode: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(selected, forKey: .selected)
        if let id = id {
            try container.encode(id, forKey: .id)
        }
    }
}

extension RegionNode: Decodable {
    convenience init(from decoder: Decoder) throws {
        self.init()
        do {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            
            self.name = try values.decode(String.self, forKey: .name)
            let geoDataIds: [Int]? = try values.decodeIfPresent(Array<Int>.self, forKey: .geoDataIds)
            self.geoDataIds = geoDataIds
            let id: Int? = try values.decodeIfPresent(Int.self, forKey: .id)
            self.id = id
            let selected: Bool? = try values.decodeIfPresent(Bool.self, forKey: .selected)
            if let unwrappedSelected = selected {
                self.selected = unwrappedSelected
            }
        } catch {
            debugPrint("Region::init: Error")
        }

    }
}
