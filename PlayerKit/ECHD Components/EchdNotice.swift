//
//  EchdNotice.swift
//  AreaSight
//
//  Created by Artem Lytkin on 27/03/2019.
//  Copyright © 2019 Netris. All rights reserved.
//

import Foundation

internal struct EchdNotice: Codable {
    var id: Int?
    var name: String?
    var checked: Bool?
    var description: String?
    
    private var _dateFinish: String?
    var dateFinish: String? {
        get {
            return _dateFinish
        }
        set {
            if let dateString = newValue,
                let date = dateString.toDateTime() {
                
                _dateFinish = formatDate(date)
            } else {
                _dateFinish = newValue
            }
        }
    }
    
    private var _dateRemove: String?
    var dateRemove: String? {
        get {
            return _dateRemove
        }
        set {
            if let dateString = newValue,
                let date = dateString.toDateTime() {
                
                _dateRemove = formatDate(date)
            } else {
                _dateRemove = newValue
            }
        }
    }
    
    private var _dateStart: String?
    var dateStart: String? {
        get {
            return _dateStart
        }
        set {
            if let dateString = newValue,
                let date = dateString.toDateTime() {
                
                _dateStart = formatDate(date)
            } else {
                _dateStart = newValue
            }
        }
    }
    
    func formatDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = DateFormats.dateFormatForNotice.rawValue
        let dateString = dateFormatter.string(from: date)
        return dateString
    }
}
