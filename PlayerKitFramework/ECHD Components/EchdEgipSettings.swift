//
//  EchdEgipSettings.swift
//  AreaSightDemo
//
//  Created by Ruslan Utashev on 10.06.2021.
//  Copyright © 2021 Netris. All rights reserved.
//

import Foundation

internal final class EchdEgipSettings {

    let baseUrl: String
    let bounds: Bounds
    let layers: [Layer]
    
    init?(_ map: [String: Any?]) {
        if let common = map["common"] as? [String: Any],
            let maps = common["maps"] as? [String: Any],
            let egip = maps["egip"] as? [String: Any],
            let baseUrl = egip["baseUrl"] as? String,
            let bounds = egip["bounds"] as? [String: Any],
            let bound = Bounds(bounds),
            let layers = egip["layers"] as? [AnyObject]
        {
            self.baseUrl = baseUrl
            self.bounds = bound
            self.layers = layers.compactMap { (layer) -> Layer? in
                return Layer(layer)
            }
        } else {
            return nil
        }
    }
}

extension EchdEgipSettings {
    
    struct Bounds {
        var east: Float
        var west: Float
        var north: Float
        var south: Float
        
        init(west: Float, east: Float, north: Float, south: Float) {
            self.east = east
            self.west = west
            self.north = north
            self.south = south
        }
        
        init?(_ map: Any) {
            guard let map = map as? [String: Any],
                let east = map["east"] as? Float,
                let west = map["west"] as? Float,
                let north = map["north"] as? Float,
                let south = map["south"] as? Float else { return nil }
                
            self.east = east
            self.west = west
            self.south = south
            self.north = north
        }
    }
    
    struct Layer {
        let layerId: String
        let layerName: String
        var layerOptions: [LayerOptions] = []
        
        init?(_ map: Any) {
            guard let layer = map as? [String: Any] else { return nil }
            guard let layerId = layer["layerId"] as? String,
                let layerName = layer["layerName"] as? String,
                let layerOptions = layer["layerOptions"] as? [AnyObject] else { return nil }
                
            self.layerId = layerId
            self.layerName = layerName
            self.layerOptions = layerOptions.compactMap({ (layer) -> LayerOptions? in
                return LayerOptions(layer)
            })
        }
    }
    
    struct LayerOptions {
        var maxZoom: Int
        var minZoom: Int
        var url: String
        var zoomOffset: Int
        var bounds: Bounds? = nil
        
        init?(_ map: Any) {
            guard let options = map as? [String: Any] else { return nil }
            guard let maxZoom = options["maxZoom"] as? Int,
                let minZoom = options["minZoom"] as? Int,
                let url = options["url"] as? String,
                let zoomOffset = options["zoomOffset"] as? Int else { return nil }
                
            self.maxZoom = maxZoom
            self.minZoom = minZoom
            self.url = url
            self.zoomOffset = zoomOffset
            
            if let bounds = options["bounds"] {
                self.bounds = Bounds(bounds)
            }
        }
    }
}
