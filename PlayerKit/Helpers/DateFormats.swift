//
//  DateFormats.swift
//  AreaSight
//
//  Created by Shamil on 7/2/20.
//  Copyright © 2020 Netris. All rights reserved.
//

import Foundation

enum DateFormats: String {
    
    case dayMonth = "dd MMM, HH:mm:ss"
    case dayMonthYear = "dd.MM.yyyy HH:mm:ss"
    case dayMonthYearWithoutTime = "dd MMMM yyyy"
    
    case dateFormatForTickets = "d MMM Y HH:mm"
    case dateFormatForNotice = "dd.MM.yyyy"
    
    case llll = "LLLL"
    
    case timeZoneAbbreviation = "MSD"
}
