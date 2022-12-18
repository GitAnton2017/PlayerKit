//
//  District.swift
//  JsonParser
//
//  Created by Artem Lytkin on 25/02/2019.
//  Copyright © 2019 Artem Lytkin. All rights reserved.
//

import Foundation

final class DistrictNode: FilterNodeProtocol {
    
    private enum CodingKeys: String, CodingKey {
        case name
        case id = "code"
        case color
        case geoDataIds
        case regions
    }
    
    private enum LocalDataCodingKeys: String, CodingKey {
        case name
        case id
        case color
        case geoDataIds
        case regions
        case children
        case selected
    }
    
    var id: Int?
    var name: String?
    var children: [FilterNodeProtocol] = []
    var selected: Bool = true
    
    var color: String?
    var geoDataIds: [Int]?
    var regions: [Int: RegionNode]?
    
    
    init(name: String, children: [FilterNodeProtocol]) {
        self.name = name
        self.children = children
        selected = true
    }
}

extension DistrictNode: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: LocalDataCodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(id, forKey: .id)
        try container.encode(color, forKey: .color)
        try container.encode(geoDataIds, forKey: .geoDataIds)
        
        if let districts = children as? [DistrictNode] {
            try container.encode(districts, forKey: .children)
        } else if let regions = children as? [RegionNode] {
            try container.encode(regions, forKey: .children)
        }
        
        try container.encode(selected, forKey: .selected)
    }
}

extension DistrictNode: Decodable {
    convenience init(from decoder: Decoder) throws {
        self.init(name: "", children: [])
        
        do {
            // From server JSON:
            let values = try decoder.container(keyedBy: CodingKeys.self)
            id = try values.decode(Int.self, forKey: .id)
            name = try values.decode(String.self, forKey: .name)
            let color: String? = try values.decodeIfPresent(String.self, forKey: .color)
            self.color = color
            let geoDataIds: [Int]? = try values.decodeIfPresent(Array<Int>.self, forKey: .geoDataIds)
            self.geoDataIds = geoDataIds
            let regions: [Int: RegionNode]? = try values.decodeIfPresent(Dictionary<Int, RegionNode>.self, forKey: .regions)
            self.regions = regions
            
            if let regionsUnwrapped = regions {
                children = []
                for (id, region) in regionsUnwrapped {
                    region.id = id
                    children.append(region)
                }
            }

            
        } catch DecodingError.keyNotFound {
            // From local JSON:
            
            let values = try decoder.container(keyedBy: LocalDataCodingKeys.self)
            let id: Int? = try values.decodeIfPresent(Int.self, forKey: .id)
            self.id = id
            let name: String? = try values.decodeIfPresent(String.self, forKey: .name)
            self.name = name
            let color: String? = try values.decodeIfPresent(String.self, forKey: .color)
            self.color = color
            let geoDataIds: [Int]? = try values.decodeIfPresent(Array<Int>.self, forKey: .geoDataIds)
            self.geoDataIds = geoDataIds
            
            if let selected = try values.decodeIfPresent(Bool.self, forKey: .selected) {
                self.selected = selected
            }
            
            if id == nil {
                let districts:[DistrictNode]? = try values.decodeIfPresent([DistrictNode].self, forKey: .children)
                if let unwrappedDistricts = districts {
                    children = unwrappedDistricts
                }
            } else {
                let regions:[RegionNode]? = try values.decodeIfPresent([RegionNode].self, forKey: .children)
                if let unwrappedRegions = regions {
                    self.children = unwrappedRegions
                }
            }
        }
    }
}
