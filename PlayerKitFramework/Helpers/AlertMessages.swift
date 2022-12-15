//
//  AlertMessages.swift
//  AreaSightDemo
//
//  Created by Shamil Akhmadullin on 12.02.2020.
//  Copyright © 2020 Netris. All rights reserved.
//

import Foundation

enum AlertMessages {
    
    // MARK: - Tab bar
    
    case permissionsChanged
    case needRestartApplication
    
    // MARK: - Login
    
    case failedToConnect
    case tryLoginAgain
    case timeoutTryLoginLater
    case tryLoginLater
    case errorCode
    case sessionNotValid
    case noCookies
    case sessionInvalidMessage
    case serverNotFound
    case errorClientVersion
    case accountAlreadyExist
    case passwordWasChanged
    
    // MARK: - Change password
    
    case successChangePassword
    
    // MARK: - Change server
    
    case enterNewServerAddress
    
    // MARK: - Pincode
    
    case pincodeTouchIdError
    case pincodeTouchIdPermissionRequest
    case pincodeTooManyAttempts
    case pincodeLoginFailed
    case pincodeTouchIdRequest
    case pincodeFaceIdRequest
    case pincodeSimplifieldAuthorization
    case pincodePasswordExpired
    case pincodeGoTo
    case pincodeForPasswordChange
    
    // MARK: - Map
    
    case allowGeopositionAccessSettings
    
    // MARK: - Cameras list
    
    case camerasListDeleteFavorites
    case camerasListDeleteHistory
    case camerasListDeleteRoute
    case camerasListCanceledRequest
    case camerasListRouteRemovingError
    case camerasListRouteAddingError
    
    // MARK: - Camera
    
    case yourRequestWithNumber
    case successfullySent
    case requestIsNotApproved
    case newTicketWrongResponse
    case copied
    case allowAccessForSaveImages
    case linkToBroadcastGenerated
    case linkIsValid
    case linkCopied
    case cameraNotAddedToFavorites
    case cameraNotRemovedFromFavorites
    case infoLoaded
    case successSavedMessage
    case camera
    case archiveNumber
    
    // MARK: - Make archive
    
    case archiveLengthIsLong
    
    // MARK: - Presets
    
    case presetsControlNotAvailable
    case presetsControlAvailable
    
    // MARK: - Settings
    
    case settingsChangeUser
    case settingsDeletePincode
    case settingsBiometryNoPincode
    case settingsBiometryUnavailable
    case settingsBiometryIncorrectData
    
    // MARK: - No app
    
    case noAppPhoneHacked
    
    // MARK: - Localized

    var localized: String {
        switch self {
        
        // MARK: - Tab bar
        
        case .permissionsChanged:
            return NSLocalizedString("tab_bar_permissions_changed", comment: "Account permissions have been changed")
        case .needRestartApplication:
            return NSLocalizedString("tab_bar_need_restart_application", comment: "To update the data, you need to restart the application")
            
        // MARK: - Login
            
        case .failedToConnect:
            return NSLocalizedString("alert_message_failed_to_connect", comment: "Failed to connect")
        case .tryLoginAgain:
            return NSLocalizedString("alert_message_try_login_again", comment: "The authorization request was aborted. Try logging in again.")
        case .timeoutTryLoginLater:
            return NSLocalizedString("alert_message_timeout_try_login_later", comment: "The server response timeout limit has been exceeded. Try logging in later.")
        case .tryLoginLater:
            return NSLocalizedString("alert_message_try_login_later", comment: "Try logging in later.")
        case .errorCode:
            return NSLocalizedString("alert_message_error_code", comment: "Error code")
        case .sessionNotValid:
            return NSLocalizedString("alert_message_session_invalid_server_response", comment: "A session in not valid. Invalid JSON")
        case .noCookies:
            return NSLocalizedString("alert_message_session_invalid_no_cookies", comment: "A session in not valid. No cookies")
        case .sessionInvalidMessage:
            return NSLocalizedString("alert_message_session_invalid_message", comment: "A session in not valid")
        case .serverNotFound:
            return NSLocalizedString("error_server_not_found", comment: "Server not found")
        case .errorClientVersion:
            return NSLocalizedString("error_client_version", comment: "This version of the app is outdated")
        case .accountAlreadyExist:
            return NSLocalizedString("alert_message_account_already_exists", comment: "Does a user want to save an old pincod or create a new one?")
        case .passwordWasChanged:
            return NSLocalizedString("alert_message_password_was_changed", comment: "The password was changed. You need to re-authorize.")
            
        // MARK: - Change password
            
        case .successChangePassword:
            return NSLocalizedString("success_change_password", comment: "The password change is successful")
        
        // MARK: - Change server
            
        case .enterNewServerAddress:
            return NSLocalizedString("alert_message_enter_new_server_address", comment: "Please enter the new server address below")
            
        // MARK: - Pincode
        
        case .pincodeTouchIdError:
            return NSLocalizedString("pincode_touchid_alert_message", comment: "Put your finger to enter")
        case .pincodeTouchIdPermissionRequest:
            return NSLocalizedString("pincode_touchid_permission_request", comment: "For simplified authorization")
        case .pincodeTooManyAttempts:
            return NSLocalizedString("pincode_error_too_many_attempts", comment: "Too many attempts")
        case .pincodeLoginFailed:
            return NSLocalizedString("pincode_login_failed", comment: "Login failed")
        case .pincodeTouchIdRequest:
            return NSLocalizedString("pincode_touchid_request", comment: "Use Touch ID for authorization?")
        case .pincodeFaceIdRequest:
            return NSLocalizedString("pincode_faceid_request", comment: "Use Face ID for authorization?")
        case .pincodeSimplifieldAuthorization:
            return NSLocalizedString("pincode_touchid_simplified_authorization", comment: "Simplified authorization")
        case .pincodePasswordExpired:
            return NSLocalizedString("pincode_password_expired", comment: "The password is expired")
        case .pincodeGoTo:
            return NSLocalizedString("pincode_go_to", comment: "Go to")
        case .pincodeForPasswordChange:
            return NSLocalizedString("pincode_for_password_change", comment: "for the password change")
        
        // MARK: - Map
        
        case .allowGeopositionAccessSettings:
            return NSLocalizedString("alert_message_allow_geoposition_access_settings", comment: "Allow access to geoposition in settings")
            
        // MARK: - Cameras list
        
        case .camerasListDeleteFavorites:
            return NSLocalizedString("cameras_list_delete_favorites", comment: "Delete all favourite cameras")
        case .camerasListDeleteHistory:
            return NSLocalizedString("cameras_list_delete_history", comment: "Delete all last viewed cameras")
        case .camerasListDeleteRoute:
            return NSLocalizedString("cameras_list_delete_route", comment: "Delete all routes")
        case .camerasListCanceledRequest:
            return NSLocalizedString("cameras_list_canceled_request", comment: "A request is cancelled")
        case .camerasListRouteRemovingError:
            return NSLocalizedString("cameras_list_route_removing_error", comment: "An error occurred while removing the camera from the route")
        case .camerasListRouteAddingError:
            return NSLocalizedString("cameras_list_route_adding_error", comment: "An error occurred while adding the camera to the route")
            
        // MARK: - Camera
            
        case .yourRequestWithNumber:
            return NSLocalizedString("alert_message_your_request_with_number", comment: "Your request with the number")
        case .successfullySent:
            return NSLocalizedString("alert_message_successfully_sent", comment: "successfully sent")
        case .requestIsNotApproved:
            return NSLocalizedString("alert_message_request_error_isnotapproved", comment: "A server didn't approve this request")
        case .newTicketWrongResponse:
            return NSLocalizedString("alert_message_request_error_wrongresponse", comment: "A server returned wrong data")
        case .copied:
            return NSLocalizedString("alert_message_copied", comment: "Copied")
        case .allowAccessForSaveImages:
            return NSLocalizedString("alert_message_allow_access_for_save_images", comment: "In order for you to save the footage, the AreaSights needs access to the gallery. Please enable access for AreaSights in device Settings > Privacy > Photos.")
        case .linkToBroadcastGenerated:
            return NSLocalizedString("alert_message_link_to_broadcast_generated", comment: "Link to the broadcast generated")
        case .linkIsValid:
            return NSLocalizedString("alert_message_link_is_valid", comment: "The link is valid for 5 days")
        case .linkCopied:
            return NSLocalizedString("alert_message_link_copied", comment: "Link copied")
        case .cameraNotAddedToFavorites:
            return NSLocalizedString("alert_message_camera_not_added_to_favorites", comment: "The camera could not be added to the favorites list. Try again later")
        case .cameraNotRemovedFromFavorites:
            return NSLocalizedString("alert_message_camera_not_removed_from_favorites", comment: "The camera could not be removed from the favorites list. Try again later")
        case .infoLoaded:
            return NSLocalizedString("alert_message_info_loaded", comment: "Information is being loaded...")
        case .successSavedMessage:
            return NSLocalizedString("success_saved_message", comment: "The image from the camera uploaded")
        case .camera:
            return NSLocalizedString("alert_message_camera", comment: "Camera")
        case .archiveNumber:
            return NSLocalizedString("alert_message_archive_number", comment: "The archive number")
            
        // MARK: - Make archive
        
        case .archiveLengthIsLong:
            return NSLocalizedString("alert_archive_length_is_long", comment: "The unloading period is more than 6 hours. Are you sure?")
            
        // MARK: - Presets
        
        case .presetsControlNotAvailable:
            return NSLocalizedString("presets_control_not_available", comment: "Control is not available for the current number of cameras on the screen")
        case .presetsControlAvailable:
            return NSLocalizedString("presets_control_available", comment: "Control is available for the number of cameras on one screen")
        
        // MARK: - Settings
        
        case .settingsChangeUser:
            return NSLocalizedString("settings_alert_changeuser_message", comment: "A message for change alert")
        case .settingsDeletePincode:
            return NSLocalizedString("settings_alert_deletepincode_message", comment: "A message for delete alert")
        case .settingsBiometryNoPincode:
            return NSLocalizedString("settings_alert_biometry_message_nopincode", comment: "A message for biometic alert")
        case .settingsBiometryUnavailable:
            return NSLocalizedString("settings_alert_biometry_message_unavailable", comment: "A message for biometic alert")
        case .settingsBiometryIncorrectData:
            return NSLocalizedString("settings_alert_biometry_message_incorrect_data", comment: "A message for incorrect biometic data alert")
            
        // MARK: - No app
        
        case .noAppPhoneHacked:
            return NSLocalizedString("no_app_phone_hacked", comment: "The phone was hacked")
        }
    }
}
