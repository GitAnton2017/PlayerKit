//
//  Parser.swift
//  JsonParser
//
//  Created by Artem Lytkin on 19/02/2019.
//  Copyright © 2019 Artem Lytkin. All rights reserved.
//

import Foundation

protocol FiltersParserProtocol {
    init()
    init(data: JSONObject)
    func parse(data: JSONObject)
    func getNodes() -> (nodes:[FilterNodeProtocol], filterIsOn: Bool)
    func saveFilters()
    func makeParameters() -> [String: Any]
    func filtersChanged() -> Bool
    func setFilterMode(_ isOn: Bool)
    func filterIsOn() -> Bool
    func getColor(for type: Int) -> String
    func getColor(status: Int) -> String

}

class FiltersParserAdaptor: FiltersParserProtocol {
    
    private var filtersParser: FiltersParser
    
    required init() {
        filtersParser = FiltersParser()
    }
    
    required init(data: JSONObject) {
        filtersParser = FiltersParser()
        
        parse(data: data)
    }
    
    func parse(data: JSONObject) {
        let jsonData = try? JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
        if let json = jsonData {
            filtersParser.initParser(with: json)
        }
    }
    
    func getNodes() -> (nodes: [FilterNodeProtocol], filterIsOn: Bool) {
        guard let filter = filtersParser.filter else { return ([], false) }
        
        var filterNodes: [FilterNodeProtocol] = []
        filterNodes.append(contentsOf: filter.districts)
        filterNodes.append(contentsOf: filter.types)
        filterNodes.append(contentsOf: filter.statuses)
        
        return (filterNodes, filtersParser.filterIsOn)
    }
    
    func saveFilters() {
        filtersParser.saveFilter()
    }
    
    func makeParameters() -> [String: Any] {
        return filtersParser.makeParameters()
    }
    
    func filtersChanged() -> Bool {
        filtersParser.filtersChanged = true
        return true
    }
    
    func setFilterMode(_ isOn: Bool) {
        filtersParser.setFilterMode(isOn)
    }
    
    func filterIsOn() -> Bool {
        return filtersParser.filterIsOn
    }
    
    func getColor(for type: Int) -> String {
        return filtersParser.color(for: type)
    }
    
    func getColor(status: Int) -> String {
        return filtersParser.color(status: status)
    }
}

// Filter models are made as a reference types, because we used them states through all application.

class FiltersParser: NSObject {
    
    fileprivate var filter: Filter? {
        didSet {
            filtersChanged = true
        }
    }
    
    private var cachedParameters: [String: Any] = [:]
    private var cameraTypeColors: [Int: String] = [:]
    
    fileprivate var filtersChanged: Bool = false
    fileprivate var filterIsOn: Bool = true
    private var queue = DispatchQueue(label: "com.netris.areasight.filters.parser")
    private let defaultColor = "#000000"
    
    convenience init(data: Data) {
        self.init()
        initParser(with: data)
    }
    
    // MARK: - internal

    internal func initParser(with data: Data) {
        let result = parseFilter(with: data)
        
        if let filter = result.filterEnv?.filter {
            setFilter(filter)
        }
    }
    
    internal func setFilterMode(_ isOn: Bool) {
        filterIsOn = isOn
    }
    
    internal func saveFilter() {
        
        guard let filter = filter else { return }
        
        let workItem = DispatchWorkItem {
            do {
                if let encoded = try? JSONEncoder().encode(filter) {
                    let data = try NSKeyedArchiver.archivedData(withRootObject: encoded, requiringSecureCoding: false)
                    
                    UserDefaults.standard.set(data, forKey: "filter")
                }
            } catch {
                debugPrint("FiltersParser::saveFilter: Error \(error)")
            }
            
            UserDefaults.standard.set(self.filterIsOn, forKey: "filterIsOn")
        }
        
        DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now(), execute: workItem)
    }
    
    // MARK: - Fileprivate
    
    fileprivate func makeParameters() -> [String: Any] {
        guard let filter = filter else { return [:] }
        
        var parameters: [String: Any] = [:]
        
        if !filterIsOn {
            parameters["districts"] = self.getSelectedDistricts(from: filter)
            parameters["regions"] = self.getSelectedRegions(from: filter)
            parameters["cameraTypes"] = self.getSelectedTypes(from: filter)
            parameters["cameraStatuses"] = self.getSelectedStatuses(from: filter)
            return parameters
        }
        
        if !filtersChanged {
            queue.sync {
                parameters = self.cachedParameters
            }
            return parameters
        }
        
        queue.async {
            self.cachedParameters["districts"] = self.getSelectedDistricts(from: filter)
            self.cachedParameters["regions"] = self.getSelectedRegions(from: filter)
            self.cachedParameters["cameraTypes"] = self.getSelectedTypes(from: filter)
            self.cachedParameters["cameraStatuses"] = self.getSelectedStatuses(from: filter)
        }
        
        filtersChanged = false
        
        queue.sync {
            parameters = self.cachedParameters
        }
        return parameters
    }
    
    fileprivate func color(for type: Int) -> String {
        guard filter != nil else { return defaultColor }
           
            var color = defaultColor
            queue.sync {
                color = cameraTypeColors[type] ?? defaultColor
            }
        
            return color
    }
    
    fileprivate func color(status: Int) -> String {
        return CameraStatusColor(id: status).getColor()
    }
    // MARK: - Private
    
    private func parseFilter(with data: Data) -> (filterEnv: FilterEnv?, error: Error?) {
        
        var filtersEnv: FilterEnv?

        do {
            filtersEnv = try JSONDecoder().decode(FilterEnv.self, from: data)
            
            guard let filter = filtersEnv?.filter else {
                throw NSError(domain: "empty", code: 10, userInfo: nil)
            }
            
            let districts = filter.districts
            var cameraTypes = filter.types
            var cameraStatuses = filter.statuses
            
            // Parse saved filters and set selected states for new filters:
            if let savedFilter = self.getSavedFilter() {
                
                // CameraTypes
                let selectedSavedTypesIds = getSelectedTypes(from: savedFilter)
                setSelectedState(for: cameraTypes, in: selectedSavedTypesIds)
                
                //--------------------------------------------------------------------------------------------------------------
                // Regions
                // Note: Processing regions in the first place than districts because a server side has boilerplate logic
                // When a district is selected we automatically check all its child regions. If there is even one unchecked region, we should look through saved regions.
                // Proccessing algorithm: 1. Look through checked regions. 2. Process through checked districts and auto-check its children if district is checked.
                let selectedSavedRegions = getSelectedRegions(from: savedFilter)
                let regions = districts.flatMap {
                    return $0.children
                }
                setSelectedState(for: regions, in: selectedSavedRegions)
                
                // Districts
                let selectedSavedDistrictsIds = getSelectedDistricts(from: savedFilter)
                setSelectedState(for: districts, in: selectedSavedDistrictsIds)
                districts.forEach {
                    if $0.selected {
                        $0.children.forEach { $0.selected = true }
                    }
                }
                //--------------------------------------------------------------------------------------------------------------
                
                // Statuses
                let selectedSavedStatutes = getSelectedStatuses(from: savedFilter)
                setSelectedState(for: cameraStatuses, in: selectedSavedStatutes)
            }

            let rootDistrict = makeRootDistrict(with: districts)
            if !rootDistrict.children.isEmpty {
                filter.districts = [rootDistrict]
            }
            
            let rootCameraType = makeRootCameraType(with: &cameraTypes)
            if !rootCameraType.children.isEmpty {
                filter.types = [rootCameraType]
            }

            let rootStatus = makeRootStatus(with: &cameraStatuses)
            if !rootStatus.children.isEmpty {
                filter.statuses = [rootStatus]
            }

        } catch {
            return (nil, error)
        }
        
        return (filtersEnv, nil)
    }
    
    private func setSelectedState(for filters: [FilterNodeProtocol], in selectedIds: [Int]) {
        filters.forEach {
            if let filterId = $0.id,
                !selectedIds.contains(filterId) {
                
                $0.selected = false
            }
        }
    }
    
    private func getSavedFilter() -> Filter? {
        if let decodedData = UserDefaults.standard.object(forKey: "filter") as? Data {
            
            filterIsOn = UserDefaults.standard.bool(forKey: "filterIsOn")
            
            do {
                if let filterData = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(decodedData) {
                    let decoder = JSONDecoder()
                    let savedFilter = try decoder.decode(Filter.self, from: filterData as! Data)
                    return savedFilter
                }
            } catch {
                debugPrint("FiltersParser::getSavedFilter: Error \(error)")
            }
        }
        return nil
    }
    
    private func makeRootStatus(with statutes: inout [CameraStatus]) -> CameraStatus {
        statutes.sort {
            guard let firstId = $0.id,
                let secondId = $1.id else {
                return false
            }
            return firstId < secondId
        }
        let rootStatus = CameraStatus(name: LabelsTexts.menuFilterStatuses.localized, children: statutes)
        
        let notSelected = rootStatus.children.filter {
            return !$0.selected
        }
        rootStatus.selected = notSelected.count > 0 ? false : true
        
        return rootStatus
    }
    
    private func makeRootDistrict(with districts: [DistrictNode]) -> DistrictNode {
        // Sort regions:
        districts.forEach {
            $0.children.sort {
                guard let firstId = $0.id, let secondId = $1.id else {
                    return false
                }
                return firstId < secondId
            }
        }
        
        let rootDistrict = DistrictNode(name: LabelsTexts.menuFilterAdministrativeDivision.localized, children: districts)
        rootDistrict.children.sort {
            guard let firstId = $0.id,
                let secondId = $1.id else {
                return false
            }
            return firstId < secondId
        }
        
        let notSelected = rootDistrict.children.filter {
            return !$0.selected
        }
        rootDistrict.selected = notSelected.count > 0 ? false : true
        
        return rootDistrict
    }
    
    private func makeRootCameraType(with cameraTypes: inout [CameraType]) -> CameraType {
        cameraTypes.sort {
            guard let firstOrder = $0.order,
                let secondOrder = $1.order else {
                return false
            }
            return firstOrder < secondOrder
        }
        let processedFilters = checkCameraTypes(initialSequence: cameraTypes)
        let rootCameraType = CameraType(name: LabelsTexts.menuFilterCameras.localized, children: processedFilters)
        
        let notSelected = rootCameraType.children.filter {
            return !$0.selected
        }
        rootCameraType.selected = notSelected.count > 0 ? false : true
        
        return rootCameraType
    }
    
    private func checkCameraTypes(initialSequence: [CameraType]) -> [CameraType] {
        
        var newArr: Set<CameraType> = []
        
        var i = 0
        
        while i < initialSequence.count {
            if let parentId = initialSequence[i].parent {
                let parent = initialSequence.first(where: { type in
                    return type.id == parentId
                })
                parent?.children.append(initialSequence[i])
            } else {
                newArr.insert(initialSequence[i])
            }
            i += 1
        }
        
        let sortedCameraTypes = newArr.sorted {
            guard let firstOrder = $0.order, let secondOrder = $1.order else {
                return false
            }
            return firstOrder < secondOrder
        }
        
        return sortedCameraTypes
    }
    
    private func makeCameraTypeColors(from filter: Filter) -> [Int: String] {
        
        var cameraTypeColors: [Int: String] = [:]
        
        if let rootEmptyCameraType = filter.types.first,
            let cameraTypes = getAllNodes(from: rootEmptyCameraType) as? [CameraType] {
            
            cameraTypeColors = cameraTypes.reduce([Int: String]()) { (dict, type) -> [Int: String] in
                var dictionary = dict
                if let id = type.id,
                    let color = type.color {
                    dictionary[id] = color
                }
                return dictionary
            }
            
        }
        
        return cameraTypeColors
    }
    
    private func getAllNodes(from node: FilterNodeProtocol) -> [FilterNodeProtocol] {
        var nodes: [FilterNodeProtocol] = []
        
        nodes.append(contentsOf: node.children)
        
        let nextLevelChildren = node.children.flatMap {
            getAllNodes(from: $0)
        }
        
        nodes.append(contentsOf: nextLevelChildren)
        
        return nodes
    }
    
    private func getSelectedDistricts(from filter: Filter) -> [Int] {
        var districts: [Int] = []
        
        if let rootEmptyDistrict = filter.districts.first {
            let selectedDistricts: [FilterNodeProtocol]!
            if filterIsOn {
                selectedDistricts = rootEmptyDistrict.children.filter {
                    return $0.selected
                }
            } else {
                selectedDistricts = rootEmptyDistrict.children
            }
            
            districts = selectedDistricts.compactMap {
                $0.id
            }
        }
        
        return districts
    }
    
    private func getSelectedRegions(from filter: Filter) -> [Int] {
        var regions: [Int] = []
        
        if let rootEmptyDistrict = filter.districts.first {
            
            // Note: We search not selected districts because when a district is selected district's regions aren't send with request.
            let notSelectedDistricts = rootEmptyDistrict.children.filter {
                return !$0.selected
            }
            let allRegions = notSelectedDistricts.flatMap {
                $0.children
            }
            
            let selectedRegions = allRegions.filter {
                return $0.selected
            }
            
            regions = selectedRegions.compactMap {
                $0.id
            }
        }
        
        return regions
    }
    
    private func getSelectedTypes(from filter: Filter) -> [Int] {
        var types: [Int] = []
        
        if let rootEmptyCameraType = filter.types.first {
            let cameraTypes = getAllNodes(from: rootEmptyCameraType)
            
            let selectedTypes: [FilterNodeProtocol]!
            if filterIsOn {
                selectedTypes = cameraTypes.filter {
                    return $0.selected
                }
            } else {
                selectedTypes = cameraTypes
            }
            
            types = selectedTypes.compactMap {
                $0.id
            }
        }
        
        return types
    }
    
    private func getSelectedStatuses(from filter: Filter) -> [Int] {
        var statuses: [Int] = []
        
        if let rootEmptyCameraStatus = filter.statuses.first {
            let cameraStatuses = getAllNodes(from: rootEmptyCameraStatus)
            
            let selectedCameraStatuses: [FilterNodeProtocol]!
            if filterIsOn {
                selectedCameraStatuses = cameraStatuses.filter {
                    return $0.selected
                }
            } else {
                selectedCameraStatuses = cameraStatuses
            }
            
            statuses = selectedCameraStatuses.compactMap {
                $0.id
            }
        }
        
        return statuses
    }
    
    private func setFilter(_ filter: Filter) {
        self.filter = filter
        self.cameraTypeColors = makeCameraTypeColors(from: filter)
    }
}

