//
//  EchdFiltersService.swift
//  AreaSight
//
//  Created by Artem Lytkin on 15/02/2019.
//  Copyright © 2019 Netris. All rights reserved.
//
import Foundation

protocol EchdFiltersServiceProtocol {
    func getColor(for type: Int) -> String
    func getColor(status: Int) -> String
    func generateFilters() -> (nodes: [FilterNodeProtocol], filterIsOn: Bool)
    func saveFilters()
    func makeParameters() -> [String: Any]
    func filtersChanged() -> Bool
    func setFilterMode(_ isOn: Bool)
    func filterIsOn() -> Bool
}

class EchdFiltersService {
    
    static let instance = EchdFiltersService()
    
    private var filtersParser = FiltersParserAdaptor()
    
    private init() {}
    
    func initData(data: JSONObject) {
        filtersParser.parse(data: data)
    }
}

extension EchdFiltersService: EchdFiltersServiceProtocol {
    
    func getColor(for type: Int) -> String {
        return filtersParser.getColor(for: type)
    }
    
    func getColor(status: Int) -> String {
        return filtersParser.getColor(status: status)
    }
    
    func generateFilters() -> (nodes: [FilterNodeProtocol], filterIsOn: Bool) {
        return filtersParser.getNodes()
    }
    
    func saveFilters() {
        filtersParser.saveFilters()
    }
    
    func makeParameters() -> [String: Any] {
        return filtersParser.makeParameters()
    }
    
    func filtersChanged() -> Bool {
        return filtersParser.filtersChanged()
    }
    
    func setFilterMode(_ isOn: Bool) {
        filtersParser.setFilterMode(isOn)
    }
    
    func filterIsOn() -> Bool {
        return filtersParser.filterIsOn()
    }
}
