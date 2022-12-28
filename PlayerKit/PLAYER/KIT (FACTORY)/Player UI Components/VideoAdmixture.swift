//
//  VideoAdmixture.swift
//  AreaSight
//
//  Created by Artem Lytkin on 08/08/2019.
//  Copyright © 2019 Netris. All rights reserved.
//

import UIKit

protocol IAdmixtureView: AnyObject {
    var canvasWidth: CGFloat { get }
    var canvasHeight: CGFloat { get }
    var scale: Int { get }
    
    func redraw()
    func drawAt(minX: CGFloat, maxX: CGFloat, minY: CGFloat, maxY: CGFloat)
    func clear()
}

class VideoAdmixture {
    let options: Options
    weak var target: IAdmixtureView?
    
    private(set) var isShowTime = false
    
    private(set) var sequenceStep = 0
    private(set) var timeoutWasSetAt: TimeInterval = 0
    private(set) var lastTimeout: TimeInterval = 0
    private(set) var noiseRepeated: TimeInterval = 0
    
    init(options: Options, target: IAdmixtureView) {
        self.options = options
        self.target = target
        start()
    }
    
    private func makeTickStep() {
        let isSequenceTime = sequenceStep < options.zones.count
        var delay: TimeInterval = 0.01
        
        isShowTime = !isShowTime
        
        if isShowTime && isSequenceTime {
            let sequenceChar = options.zones[sequenceStep]
            showNoise(sequenceChar)
            sequenceStep += 1
            delay = TimeInterval.random(in: min(options.minNoiseDuration, options.maxNoiseDuration)...max(options.minNoiseDuration, options.maxNoiseDuration))
            
        } else if isShowTime && !isSequenceTime {
            if noiseRepeated == options.systemNoiseRepeat {
                noiseRepeated = 0
                sequenceStep = 0
            } else {
                showNoiseInSystemSector()
                delay = options.systemNoiseDuration
                noiseRepeated += 1
            }
            
        } else if !isShowTime && isSequenceTime {
            delay = TimeInterval.random(in: min(options.minNoiseDelay, options.maxNoiseDelay)...max(options.minNoiseDelay, options.maxNoiseDelay))
            hideNoise()
            
        } else if !isShowTime && !isSequenceTime {
            delay = options.systemNoiseDelay
        } 
        
        lastTimeout = delay
        timeoutWasSetAt = Date().timeIntervalSince1970
        Timer.scheduledTimer(withTimeInterval: TimeInterval(delay), repeats: false) { [weak self] _ in
            self?.tick()
        }
    }
    
    private func hideNoise() {
        target?.clear()
    }
    
    private func tick() {
        if lastTimeout > 0 {
            let delta = Date().timeIntervalSince1970 - TimeInterval(timeoutWasSetAt)
            if delta < TimeInterval(lastTimeout) {
                restart()
                return
            }
        }
        makeTickStep()
    }
    
    private func start() {
        Timer.scheduledTimer(withTimeInterval: 0, repeats: false) {[weak self] _ in
            self?.tick()
        }
    }
    
    private func restart() {
        start()
    }
    
    private func showNoise(_ sequenceChar: Character) {
        guard let sectorIndex = Int.init(String(sequenceChar), radix: GridConfig.sectors.count),
            let target = target else {
            return
        }
        let sector = GridConfig.sectors[sectorIndex]
        
        let cellWidth = target.canvasWidth / CGFloat(GridConfig.cols)
        let cellHeight = target.canvasHeight / CGFloat(GridConfig.rows)
        let horizontalPadding = target.canvasWidth * CGFloat(options.paddingRatio)
        let verticalPadding = target.canvasHeight * CGFloat(options.paddingRatio)
        let sectorWidth = cellWidth - 2 * horizontalPadding
        let sectorHeight = cellHeight - 2 * verticalPadding
    
        let minX = CGFloat(sector.x) * cellWidth + horizontalPadding
        let maxX = minX + sectorWidth - CGFloat(options.avatar.width)
        let minY = CGFloat(sector.y) * cellHeight + verticalPadding
        let maxY = minY + sectorHeight - CGFloat(options.avatar.height)
        
        target.drawAt(minX: minX, maxX: maxX, minY: minY, maxY: maxY)
    }
    
    private func showNoiseInSystemSector() {
        guard let target = target else {
            return
        }
        
        let cellWidth = target.canvasWidth / CGFloat(GridConfig.cols)
        let horizontalPadding = target.canvasWidth * CGFloat(options.paddingRatio)
        let verticalPadding = target.canvasHeight * CGFloat(options.paddingRatio)
        let minX = (cellWidth) - horizontalPadding
        let maxX = minX + 2 * horizontalPadding - CGFloat(options.avatar.width)
        let minY = (target.canvasHeight) - CGFloat(GridConfig.rows + 1) * verticalPadding
        let maxY = minY + 2 * verticalPadding - CGFloat(options.avatar.height)
        
        target.drawAt(minX: minX, maxX: maxX, minY: minY, maxY: maxY)
    }
    
    // MARK: - Private
    
    private func secondsToMillis(_ input: Float) -> Int {
        let output = Int(input * 1000)
        return output
    }
    
}

class Options {
    let maxOpacity: Float
    let minOpacity: Float
    let edge: Int
    let minNoiseDuration: TimeInterval
    let maxNoiseDuration: TimeInterval
    let minNoiseDelay: TimeInterval
    let maxNoiseDelay: TimeInterval
    let rowSize: Int
    let offset: Int
    let systemNoiseDuration: TimeInterval
    let systemNoiseDelay: TimeInterval
    let systemNoiseRepeat: TimeInterval
    let paddingRatio: Float
    let colorString: String
    let zones: String
    let key: String
    
    let avatar: Avatar
    
    private init(maxOpacity: Float,
         minOpacity: Float,
         edge: Int,
         minNoiseDuration: TimeInterval,
         maxNoiseDuration: TimeInterval,
         minNoiseDelay: TimeInterval,
         maxNoiseDelay: TimeInterval,
         rowSize: Int,
         offset: Int,
         systemNoiseDuration: TimeInterval,
         systemNoiseDelay: TimeInterval,
         systemNoiseRepeat: TimeInterval,
         paddingRatio: Float,
         colorString: String,
         zones: String,
         key: String) {
        
        self.maxOpacity = maxOpacity
        self.minOpacity = minOpacity
        self.edge = edge
        self.minNoiseDuration = minNoiseDuration
        self.maxNoiseDuration = maxNoiseDuration
        self.minNoiseDelay = minNoiseDelay
        self.maxNoiseDelay = maxNoiseDelay
        self.rowSize = rowSize
        self.offset = offset
        self.systemNoiseDuration = systemNoiseDuration
        self.systemNoiseDelay = systemNoiseDelay
        self.systemNoiseRepeat = systemNoiseRepeat
        self.paddingRatio = paddingRatio
        self.colorString = colorString
        self.zones = zones
        self.key = key
        
        self.avatar = Options.createAvatar(key: key, edge: edge, offset: offset, rowSize: rowSize)
    }
    
    static func makeOptions(from data: String) -> Options?{
        let split = data.split(separator: ";")
        guard let maxOpacity = Float(split[0]),
            let minOpacity = Float(split[1]),
            let edge = Int(split[2]),
            let minNoiseDuration = TimeInterval(split[3]),
            let maxNoiseDuration = TimeInterval(split[4]),
            let minNoiseDelay = TimeInterval(split[5]),
            let maxNoiseDelay = TimeInterval(split[6]),
            let rowSize = Int(split[7]),
            let offset = Int(split[8]),
            let systemNoiseDuration = TimeInterval(split[9]),
            let systemNoiseDelay = TimeInterval(split[10]),
            let systemNoiseRepeat = TimeInterval(split[11]),
            let paddingRatio = Float(split[12]) else { return nil }
        
        let colorString = String(split[13]),
        zones = String(split[14]),
        key = String(split[15])
        
        let options = Options(maxOpacity: maxOpacity,
                              minOpacity: minOpacity,
                              edge: edge,
                              minNoiseDuration: minNoiseDuration,
                              maxNoiseDuration: maxNoiseDuration,
                              minNoiseDelay: minNoiseDelay,
                              maxNoiseDelay: maxNoiseDelay,
                              rowSize: rowSize,
                              offset: offset,
                              systemNoiseDuration: systemNoiseDuration,
                              systemNoiseDelay: systemNoiseDelay,
                              systemNoiseRepeat: systemNoiseRepeat,
                              paddingRatio: paddingRatio,
                              colorString: colorString,
                              zones: zones,
                              key: key)
        return options
    }
    
    private static func createAvatar(key: String, edge: Int, offset: Int, rowSize: Int) -> Avatar {
        let id = key.isInverted ? key.invert().withStopSign : key.withStopSign
        let numberOfRows = id.count % rowSize == 0 ?
            id.count / rowSize :
            Int(floor(Float(id.count) / Float(rowSize))) + 1
        
        let rowWidth = edge * rowSize + offset * (rowSize - 1)
        let inversionSignWidth = 2 * offset + edge
        let width = rowWidth + inversionSignWidth
        let height = numberOfRows * (edge + offset) - offset
        
        let avatar = Avatar(width: width, height: height)
        
        drawAvatar(key: key, edge: edge, offset: offset, rowSize: rowSize, id: id, avatar: avatar)
        
        return avatar
    }
    
    private static func drawAvatar(key: String, edge: Int, offset: Int, rowSize: Int, id: String, avatar: Avatar) {
        let merge = true
        let mergeEndChar = false
        
        var y = 0
        var x = 0
        var rowOffset = 0
        
        if key.isInverted {
            avatar.drawPoint(x: x, y: y, width: edge, height: edge)
            rowOffset = edge + 2 * offset
            x = rowOffset
        }
        
        var i = 0
        var rowPos = 0
        while i < id.count {
            let isOne = id[i] == "1"
            
            if rowPos > rowSize - 1 {
                x = rowOffset
                y += edge + offset
                rowPos = 0
            }
            
            if isOne { avatar.drawPoint(x: x, y: y, width: edge, height: edge) }
            
            if merge,
                rowPos != rowSize - 1,
                i + 2 < id.count || mergeEndChar,
                isOne,
                id[i + 1] == "1" {
                avatar.drawPoint(x: x + offset, y: y, width: offset, height: offset)
            }
            
            x += edge + offset
            
            i += 1
            rowPos += 1
        }
    }
}

extension String {
    var isInverted: Bool {
        get {
            return moreZerosThanOnes()
        }
    }
    
    var withStopSign: String {
        return self + "1"
    }
    
    private func moreZerosThanOnes() -> Bool {
        var zerosCount = 0
        var onesCount = 0
        
        for char in self {
            if char == "0" {
                zerosCount += 1
            }
            if char == "1" {
                onesCount += 1
            }
        }
        
        return zerosCount > onesCount
    }
    
    func invert() -> String {
        var res = ""
        for char in self {
            if char == "0" {
                res += "1"
            } else if char == "1" {
                res += "0"
            }
        }
        
        return res
    }
}

class Avatar {
    let width: Int
    let height: Int
    var canvas: Array<Array<Bool>>
    
    init(width: Int, height: Int) {
        self.width = width
        self.height = height
        canvas = Array(repeating: Array(repeating: false, count: width), count: height)
    }
    
    func drawPoint(x: Int, y: Int, width: Int, height: Int) {
        for i in 0..<width {
            for j in 0..<height {
                canvas[y + j][x + i] = true
            }
        }
    }
}

extension String {
    subscript (i: Int) -> Character {
        return self[index(startIndex, offsetBy: i)]
    }
    subscript (bounds: CountableRange<Int>) -> Substring {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return self[start ..< end]
    }
    subscript (bounds: CountableClosedRange<Int>) -> Substring {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return self[start ... end]
    }
    subscript (bounds: CountablePartialRangeFrom<Int>) -> Substring {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(endIndex, offsetBy: -1)
        return self[start ... end]
    }
    subscript (bounds: PartialRangeThrough<Int>) -> Substring {
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return self[startIndex ... end]
    }
    subscript (bounds: PartialRangeUpTo<Int>) -> Substring {
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return self[startIndex ..< end]
    }
}
extension Substring {
    subscript (i: Int) -> Character {
        return self[index(startIndex, offsetBy: i)]
    }
    subscript (bounds: CountableRange<Int>) -> Substring {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return self[start ..< end]
    }
    subscript (bounds: CountableClosedRange<Int>) -> Substring {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return self[start ... end]
    }
    subscript (bounds: CountablePartialRangeFrom<Int>) -> Substring {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(endIndex, offsetBy: -1)
        return self[start ... end]
    }
    subscript (bounds: PartialRangeThrough<Int>) -> Substring {
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return self[startIndex ... end]
    }
    subscript (bounds: PartialRangeUpTo<Int>) -> Substring {
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return self[startIndex ..< end]
    }
}

struct GridConfig {
    
    struct Sector {
        let x: Int
        let y: Int
        let width: Int
        let height: Int
    }
    
    static let rows = 2
    static let cols = 2
    
    static let sectors = [
        Sector(x: 0, y: 0, width: 1, height: 1),
        Sector(x: 1, y: 0, width: 1, height: 1),
        Sector(x: 1, y: 1, width: 1, height: 1),
        Sector(x: 0, y: 1, width: 1, height: 1)
    ]
}
