//
//  AlertTitles.swift
//  AreaSightDemo
//
//  Created by Shamil Akhmadullin on 12.02.2020.
//  Copyright © 2020 Netris. All rights reserved.
//

import Foundation

enum AlertTitles {
    
    // MARK: - Application

    case error
    
    // MARK: - Login
    
    case sessionInvalidTitle
    case accountAlreadyExist
    
    // MARK: - Change server
    
    case addServerAddress
    
    // MARK: - Pincode
    
    case pincodeDeleteButton
    
    // MARK: - Tab bar
    
    case title
    case informed
    
    // MARK: - Map
    
    case accessDenied
    
    // MARK: - Camera
    
    case allowAccess
    case orderPlaced
    case requestWasSent
    case shareStream
    case attension
    
    // MARK: - Settings

    case settingsChangeUser
    case settingsDeletePincode
    
    // MARK: - No app

    case noAppDetectedJailbreak
    
    // MARK: - Localized
    
    var localized: String {
        switch self {
            
        // MARK: - Application
            
        case .error:
            return NSLocalizedString("alert_title_error", comment: "Error")
            
        // MARK: - Login

        case .sessionInvalidTitle:
            return NSLocalizedString("alert_title_session_invalid_title", comment: "A title for invalid session alert")
        case .accountAlreadyExist:
            return NSLocalizedString("alert_title_account_already_exists", comment: "This account is already exists")
            
        // MARK: - Change server
        
        case .addServerAddress:
            return NSLocalizedString("alert_title_add_server_address", comment: "Add server address")
            
        // MARK: - Pincode
        
        case .pincodeDeleteButton:
            return NSLocalizedString("pincode_button_delete", comment: "")
            
        // MARK: - Tab bar
            
        case .title:
            return NSLocalizedString("tab_bar_title", comment: "Title")
        case .informed:
            return NSLocalizedString("tab_bar_informed", comment: "Informed")
        
        // MARK: - Map
        
        case .accessDenied:
            return NSLocalizedString("alert_title_access_denied", comment: "Geoposition is denied")
            
        // MARK: - Camera
            
        case .allowAccess:
            return NSLocalizedString("alert_title_allow_access", comment: "Allow access")
        case .orderPlaced:
            return NSLocalizedString("alert_title_order_placed", comment: "The order is placed")
        case .requestWasSent:
            return NSLocalizedString("alert_title_request_was_sent", comment: "The request was sent")
        case .shareStream:
            return NSLocalizedString("alert_title_share_stream", comment: "To share the stream")
        case .attension:
            return NSLocalizedString("alert_attension", comment: "Attention")
            
        // MARK: - Settings

        case .settingsChangeUser:
            return NSLocalizedString("settings_alert_changeuser_title", comment: "A title for change alert")
        case .settingsDeletePincode:
            return NSLocalizedString("settings_alert_deletepincode_title", comment: "A title for delete alert")
            
        // MARK: - No app
        
        case .noAppDetectedJailbreak:
            return NSLocalizedString("no_app_jailbreak_detected", comment: "Jailbreak detected")
        }
    }
}
