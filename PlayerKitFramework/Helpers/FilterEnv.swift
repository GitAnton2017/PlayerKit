//
//  FilterEnv.swift
//  JsonParser
//
//  Created by Artem Lytkin on 21/02/2019.
//  Copyright © 2019 Artem Lytkin. All rights reserved.
//

import Foundation

class FilterEnv: Codable {
    
    private enum CodingKeys: String, CodingKey {
        case filter = "filters"
    }
    
    var filter: Filter
    
    init(filter: Filter) {
        self.filter = filter
    }
}

