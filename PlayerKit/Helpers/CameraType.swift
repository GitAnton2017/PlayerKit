//
//  CameraTypeNode.swift
//  JsonParser
//
//  Created by Artem Lytkin on 25/02/2019.
//  Copyright © 2019 Artem Lytkin. All rights reserved.
//

import Foundation

final class CameraType: FilterNodeProtocol, Hashable {
    
    private enum CodingKeys: String, CodingKey {
        case name
        case id = "code"
        case color
        case order
        case hint
        case parent
    }
    
    private enum LocalDataCodingKeys: String, CodingKey {
        case name
        case id
        case color
        case order
        case hint
        case parent
        case children
        case selected
    }
    
    static func == (lhs: CameraType, rhs: CameraType) -> Bool {
        return lhs.name == rhs.name && lhs.id == rhs.id
    }
    
    var id: Int?
    var name: String?
    var children: [FilterNodeProtocol] = []
    var selected: Bool = true

    var color: String?
    var order: Int?
    var hint: String?
    var parent: Int?
    
    init(name: String, children: [FilterNodeProtocol]) {
        self.name = name
        self.children = children
    }
    
    func hash(into hasher: inout Hasher) {
        return hasher.combine(id ?? 0)
    }
}

extension CameraType: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: LocalDataCodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(id, forKey: .id)
        try container.encode(color, forKey: .color)
        try container.encode(order, forKey: .order)
        try container.encode(hint, forKey: .hint)
        try container.encode(selected, forKey: .selected)
        try container.encode(parent, forKey: .parent)
        
        if let children = children as? [CameraType] {
            try container.encode(children, forKey: .children)
        }
    }
}

extension CameraType: Decodable {
    convenience init(from decoder: Decoder) throws {
        
        self.init(name: "", children: [])
        
        do {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            id = try values.decode(Int.self, forKey: .id)
            name = try values.decode(String.self, forKey: .name)
            let color: String? = try values.decodeIfPresent(String.self, forKey: .color)
            self.color = color
            let order: Int? = try values.decodeIfPresent(Int.self, forKey: .order)
            self.order = order
            let hint: String? = try values.decodeIfPresent(String.self, forKey: .hint)
            self.hint = hint
            let parent: Int? = try values.decodeIfPresent(Int.self, forKey: .parent)
            self.parent = parent
            
        } catch DecodingError.keyNotFound {
            let values = try decoder.container(keyedBy: LocalDataCodingKeys.self)
            let id: Int? = try values.decodeIfPresent(Int.self, forKey: .id)
            self.id = id
            let name: String? = try values.decodeIfPresent(String.self, forKey: .name)
            self.name = name
            let color: String? = try values.decodeIfPresent(String.self, forKey: .color)
            self.color = color
            let order: Int? = try values.decodeIfPresent(Int.self, forKey: .order)
            self.order = order
            let hint: String? = try values.decodeIfPresent(String.self, forKey: .hint)
            self.hint = hint
            let parent: Int? = try values.decodeIfPresent(Int.self, forKey: .parent)
            self.parent = parent
            
            if let children = try values.decodeIfPresent([CameraType].self, forKey: .children) {
                self.children = children
            }
            if let selected = try values.decodeIfPresent(Bool.self, forKey: .selected) {
                self.selected = selected
            }
        }
    }
}
