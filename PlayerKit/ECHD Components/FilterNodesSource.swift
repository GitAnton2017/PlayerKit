//
//  FilterNodesSource.swift
//  AreaSight
//
//  Created by Shamil on 09.03.2021.
//  Copyright © 2021 Netris. All rights reserved.
//

import Foundation

protocol FilterNodesSource: AnyObject {
    
    func generateFilters() -> (nodes: [FilterNodeProtocol], filterIsOn: Bool)
    func saveFilter()
    func filtersChanged()
    func setFilterMode(_ isOn: Bool)
    func filterRegionChanged(region: Int, status: Bool)
    func toggleRegions(to: Bool)
}
