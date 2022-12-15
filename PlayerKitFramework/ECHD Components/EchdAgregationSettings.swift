//
//  EchdAgregationSettings.swift
//  AreaSight
//
//  Created by Александр on 11.01.17.
//  Copyright © 2017 Netris. All rights reserved.
//

import UIKit

struct Tile: Hashable {
    let x: Int
    let y: Int
}

class EchdAgregationSettings: NSObject {

    static let sharedInstance = EchdAgregationSettings()
    
    var byZoom: [String: [String: Int]]?
    var districtZooms: [Int]?
    var notAggregatedZoom = 16
    var scale: Double = 1000000

    func initData(_ data: [String: AnyObject]) {
        let scale = data["scale"] as? Int ?? 1000000
        self.scale = Double(scale)
        notAggregatedZoom = data["notAggregatedZoom"] as? Int ?? 16
        districtZooms = data["districtZooms"] as? [Int]
        byZoom = data["byZoom"] as? [String: [String: Int]]
    }
    
    // MARK: - Tile
    
    func getTileX(fromPointLng longitude: Double, zoom: Int) -> Int? {
        guard let w = byZoom?[String(zoom)]?["w"],
            let tilew = byZoom?[String(zoom)]?["tilew"] else { return nil }
        
        let cellWidth = Double(w)
        let cellX = longitude * scale / cellWidth
        let cellCountInTileHorizontally = Double(tilew)
        
        // Divide by tilew to find tile X
        let tileX = Int( cellX / cellCountInTileHorizontally )
        
        return tileX
    }
    
    func getTileY(fromPointLat latitude: Double, zoom: Int) -> Int? {
        guard let h = byZoom?[String(zoom)]?["h"],
            let tileh = byZoom?[String(zoom)]?["tileh"] else { return nil }
        
        let cellHeight = Double(h)
        let cellY = latitude * scale / cellHeight
        let cellCountInTileVertically = Double(tileh)
        
        // Divide by tileh to find tile Y
        let tileY = Int( cellY / cellCountInTileVertically )
        
        return tileY
    }
    
    func getTileLeft(_ x: Int, zoom: Int) -> Double? {
        guard let w = byZoom?[String(zoom)]?["w"],
            let tilew = byZoom?[String(zoom)]?["tilew"] else { return nil }
        
        let tileX = Double(x)
        let cellWidth = Double(w)
        let cellCountInTileHorizontally = Double(tilew)
        
        let tileFirstCellX = tileX * cellCountInTileHorizontally
        let cellLongitudeInOurCoordinateSystem = tileFirstCellX * cellWidth
        let cellLongitudeInGeographicCoordinateSystem = cellLongitudeInOurCoordinateSystem / scale
        
        return cellLongitudeInGeographicCoordinateSystem
    }
    
    func getTileRight(_ x: Int, zoom: Int) -> Double? {
        guard let w = byZoom?[String(zoom)]?["w"],
            let tilew = byZoom?[String(zoom)]?["tilew"] else { return nil }
        
        let tileX = Double(x)
        let cellWidth = Double(w)
        let cellCountInTileHorizontally = Double(tilew)
        
        // tile rightmost cell right coordinate == horizontally next tile first cell left coordinate
        let horizontallyNextTileFirstCellX = (tileX + 1) * cellCountInTileHorizontally
        let cellLongitudeInOurCoordinateSystem = horizontallyNextTileFirstCellX * cellWidth
        let cellLongitudeInGeographicCoordinateSystem = cellLongitudeInOurCoordinateSystem / scale
        
        return cellLongitudeInGeographicCoordinateSystem
    }
    
    func getTileBottom(_ y: Int, zoom: Int) -> Double? {
        guard let h = byZoom?[String(zoom)]?["h"],
            let tileh = byZoom?[String(zoom)]?["tileh"] else { return nil }
        
        let tileY = Double(y)
        let cellHeight = Double(h)
        let cellCountInTileVertically = Double(tileh)
        
        let tileFirstCellY = tileY * cellCountInTileVertically
        let cellLatitudeInOurCoordinateSystem = tileFirstCellY * cellHeight
        let cellLatitudeInGeographicCoordinateSystem = cellLatitudeInOurCoordinateSystem / scale
        
        return cellLatitudeInGeographicCoordinateSystem
    }
    
    func getTileTop(_ y: Int, zoom: Int) -> Double? {
        guard let h = byZoom?[String(zoom)]?["h"],
            let tileh = byZoom?[String(zoom)]?["tileh"] else { return nil }
        
        let tileY = Double(y)
        let cellHeight = Double(h)
        let cellCountInTileVertically = Double(tileh)
        
        // tile topmost cell top coordinate == vertically next tile first cell bottom coordinate
        let verticallyNextTileFirstCellY = (tileY + 1) * cellCountInTileVertically
        let cellLatitudeInOurCoordinateSystem = verticallyNextTileFirstCellY * cellHeight
        let cellLatitudeInGeographicCoordinateSystem = cellLatitudeInOurCoordinateSystem / scale
        
        return cellLatitudeInGeographicCoordinateSystem
    }
    
    // MARK: - Cell
    
    func getCellX(fromPointLng longitude: Double, zoom: Int) -> Int? {
        guard let w = byZoom?[String(zoom)]?["w"] else { return nil }
        
        let cellWidth = Double(w)
        let cellX = longitude * scale / cellWidth

        return Int( cellX )
    }
    
    func getCellY(fromPointLat latitude: Double, zoom: Int) -> Int? {
        guard let h = byZoom?[String(zoom)]?["h"] else { return nil }
        
        let cellHeight = Double(h)
        let cellY = latitude * scale / cellHeight
        
        return Int( cellY )
    }
    
    func getCellCenterLatitude(y: Int, zoom: Int) -> Double? {
        guard let h = byZoom?[String(zoom)]?["h"] else { return nil }
        
        let cellY = Double(y)
        let cellHeight = Double(h)
        
        // Add 0.5 because we want a center coordinate, not a bottom
        let cellCenterLatitudeInOurCoordinateSystem = (cellY + 0.5) * cellHeight
        let cellCenterLatitudeInGeographicCoordinateSystem = cellCenterLatitudeInOurCoordinateSystem / scale
        
        return cellCenterLatitudeInGeographicCoordinateSystem
    }
    
    func getCellCenterLongitude(x: Int, zoom: Int) -> Double? {
        guard let w = byZoom?[String(zoom)]?["w"] else { return nil }
        
        let cellX = Double(x)
        let cellWidth = Double(w)
        
        let cellCenterLongitudeInOurCoordinateSystem = (cellX + 0.5) * cellWidth
        let cellCenterLongitudeInGeographicCoordinateSystem = cellCenterLongitudeInOurCoordinateSystem / scale
        
        return cellCenterLongitudeInGeographicCoordinateSystem
    }
    
    // MARK: - MicroCell
    
    func getMicroCellX(fromPointLng longitude: Double, zoom: Int) -> Int? {
        
        var newZoom = zoom
        
        if zoom < 18 {
            newZoom += 1
        }
        
        guard let w = byZoom?[String(newZoom)]?["w"] else { return nil }
        
        let microCellWidth = Double(w)
        let microCellX = longitude * scale / microCellWidth
        
        return Int( microCellX )
    }
    
    func getMicroCellY(fromPointLat latitude: Double, zoom: Int) -> Int? {
        var newZoom = zoom
        
        if zoom < 18 {
            newZoom += 1
        }
        
        guard let h = byZoom?[String(newZoom)]?["h"] else { return nil }
        
        let microCellHeight = Double(h)
        let microCellY = latitude * scale / microCellHeight
        
        return Int( microCellY )
    }
    
    func getMicroCellCenterLongitude(x: Int, zoom: Int) -> Double? {
        var newZoom = zoom
        
        if zoom < 18 {
            newZoom += 1
        }
        
        guard let w = byZoom?[String(newZoom)]?["w"] else { return nil }
        
        let cellX = Double(x)
        let cellWidth = Double(w)
        
        let cellCenterLongitudeInOurCoordinateSystem = (cellX + 0.5) * cellWidth
        let cellCenterLongitudeInGeographicCoordinateSystem = cellCenterLongitudeInOurCoordinateSystem / scale
        
        return cellCenterLongitudeInGeographicCoordinateSystem
    }
    
    func getMicroCellCenterLatitude(y: Int, zoom: Int) -> Double? {
        var newZoom = zoom
        
        if zoom < 18 {
            newZoom += 1
        }
        
        guard let h = byZoom?[String(newZoom)]?["h"] else { return nil }
        
        let cellY = Double(y)
        let cellHeight = Double(h)
        
        // Add 0.5 because we want a center coordinate, not a bottom
        let cellCenterLatitudeInOurCoordinateSystem = (cellY + 0.5) * cellHeight
        let cellCenterLatitudeInGeographicCoordinateSystem = cellCenterLatitudeInOurCoordinateSystem / scale
        
        return cellCenterLatitudeInGeographicCoordinateSystem
    }
}
