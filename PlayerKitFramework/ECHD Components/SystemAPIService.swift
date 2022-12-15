//
//  SystemAPIService.swift
//  AreaSight
//
//  Created by Emin Alekperov on 19.12.2019.
//  Copyright © 2019 Netris. All rights reserved.
//

import UIKit

struct SystemAPIService {
    @discardableResult static func open(url: String) -> Bool {
        guard let url = URL(string: url) else { return false }
        
        UIApplication.shared.open(url)
        
        return true
    }
}
