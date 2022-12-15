//
//  FilterNodeProtocol.swift
//  JsonParser
//
//  Created by Artem Lytkin on 25/02/2019.
//  Copyright © 2019 Artem Lytkin. All rights reserved.
//

import Foundation

protocol FilterNodeProtocol: AnyObject, Codable {
    var id: Int? { get set }
    var name: String? { get set }
    var children: [FilterNodeProtocol] { get set }
    var selected: Bool { get set }
}
