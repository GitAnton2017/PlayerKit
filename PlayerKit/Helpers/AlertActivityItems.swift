//
//  AlertActivityItems.swift
//  AreaSight
//
//  Created by Shamil on 04.08.2020.
//  Copyright © 2020 Netris. All rights reserved.
//

import Foundation

enum AlertActivityItems {
    
    // MARK: - Camera
    
    case linkToVideo
    case caseNumber
    
    // MARK: - Localized
    
    var localized: String {
        switch self {
        
        // MARK: - Camera
        
        case .linkToVideo:
            return NSLocalizedString("alert_activity_item_link_to_video", comment: "Link to the video")
        case .caseNumber:
            return NSLocalizedString("alert_activity_item_case_number", comment: "Case number")
        }
    }
}
