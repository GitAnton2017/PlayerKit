//
//  AlertActions.swift
//  AreaSightDemo
//
//  Created by Shamil Akhmadullin on 12.02.2020.
//  Copyright © 2020 Netris. All rights reserved.
//

import Foundation

enum AlertActions {
    
    // MARK: - Application
    
    case add
    case cancel
    case close
    case send
    case copy
    case open
    case ok
    case replace
    
    // MARK: - Tab bar
    
    case reject
    case now
    
    // MARK: - Login
    
    case change
    case useOldPincode
    case newPincode
    
    // MARK: - Map
    
    case goOver
    
    // MARK: - Camera
    
    case notNow
    case transmit
    case copyLink
    
    // MARK: - Settings
    
    case settingsBiometryOk
    case settingsCancel
    case settingsYes
    case settings
    
    // MARK: - Localized
    
    var localized: String {
        switch self {
            
        // MARK: - Application
            
        case .add:
            return NSLocalizedString("alert_action_add", comment: "Add")
        case .cancel:
            return NSLocalizedString("alert_action_cancel", comment: "Cancel")
        case .close:
            return NSLocalizedString("alert_action_close", comment: "Close")
        case .send:
            return NSLocalizedString("alert_action_send", comment: "Send")
        case .copy:
            return NSLocalizedString("alert_action_copy", comment: "Copy")
        case .open:
            return NSLocalizedString("alert_action_open", comment: "Open")
        case .ok:
            return NSLocalizedString("alert_action_ok", comment: "Ok")
        case .replace:
            return NSLocalizedString("alert_action_replace", comment: "Replace")
            
        // MARK: - Tab bar
        
        case .reject:
            return NSLocalizedString("tab_bar_reject", comment: "Reject")
        case .now:
            return NSLocalizedString("tab_bar_now", comment: "Now")
            
        // MARK: - Login
            
        case .change:
            return NSLocalizedString("alert_action_change", comment: "Change it")
        case .useOldPincode:
            return NSLocalizedString("alert_action_use_old_pincode", comment: "Old pincode")
        case .newPincode:
            return NSLocalizedString("alert_action_create_new_pincode", comment: "New pincode")
            
        // MARK: - Map
            
        case .goOver:
            return NSLocalizedString("alert_action_go_over", comment: "Go over")
            
        // MARK: - Camera
            
        case .notNow:
            return NSLocalizedString("alert_action_not_now", comment: "Not now")
        case .transmit:
            return NSLocalizedString("alert_action_transmit", comment: "Transmit")
        case .copyLink:
            return NSLocalizedString("alert_action_copy_link", comment: "Copy the link")
            
        // MARK: - Settings
            
        case .settingsBiometryOk:
            return NSLocalizedString("settings_alert_biometry_ok", comment: "A \"ok\" button title for biometic alert")
        case .settingsCancel:
            return NSLocalizedString("settings_alert_cancel", comment: "A \"cancel\" button title for delete alert")
        case .settingsYes:
            return NSLocalizedString("settings_alert_yes", comment: "An \"agree\" button title for change alert")
        case .settings:
            return NSLocalizedString("alert_action_settings", comment: "Settings")
        }
    }
}
