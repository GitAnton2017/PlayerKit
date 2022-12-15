//
//  CameraStatus.swift
//  JsonParser
//
//  Created by Artem Lytkin on 25/02/2019.
//  Copyright © 2019 Artem Lytkin. All rights reserved.
//

import Foundation

final class CameraStatus: FilterNodeProtocol {
    
    private enum CodingKeys: String, CodingKey {
        case name
        case color
        case children
        case selected
        case id
    }
    
    var id: Int?
    var name: String?
    var children: [FilterNodeProtocol] = []
    var selected: Bool = true
    
    var color: String?
    
    init(name: String, children: [FilterNodeProtocol]) {
        self.name = name
        self.children = children
    }
}

extension CameraStatus: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(color, forKey: .color)
        if let children = children as? [CameraStatus] {
            try container.encode(children, forKey: .children)
        }
        if let id = id {
            try container.encode(id, forKey: .id)
        }
        try container.encode(selected, forKey: .selected)
    }
}

extension CameraStatus: Decodable {
    convenience init(from decoder: Decoder) throws {
        self.init(name: "", children: [])
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try values.decode(String.self, forKey: .name)
        let color: String? = try values.decodeIfPresent(String.self, forKey: .color)
        self.color = color
        
        // From local JSON:
        let id: Int? = try values.decodeIfPresent(Int.self, forKey: .id)
        self.id = id

        if let selected = try values.decodeIfPresent(Bool.self, forKey: .selected) {
            self.selected = selected
        }
        if let children = try values.decodeIfPresent([CameraStatus].self, forKey: .children) {
            self.children = children
        }
    }
}
