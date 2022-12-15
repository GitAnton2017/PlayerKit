//
//  LabelsTexts.swift
//  AreaSight
//
//  Created by Shamil on 6/18/20.
//  Copyright © 2020 Netris. All rights reserved.
//

import Foundation

enum LabelsTexts {
    
    // MARK: - Login
    
    case or
    
    // MARK: - User agreement
    
    case userAgreementButtonAccept
    case userAgreementButtonBack
    case userAgreementTitleLabel
    
    // MARK: - Change password
    
    case enterOldPassword
    case enterNewPassword
    case repeatNewPassword
    case passwordConfirmationMustMatch
    
    // MARK: - Map
    
    case zoom
    case nameMissing
    case addressMissing
    case cameraAnnotationDescription
    
    // MARK: - Menu filter
    
    case menuFilter
    case menuFilterStatuses
    case menuFilterAdministrativeDivision
    case menuFilterCameras
    case menuFilterDistricts
    case menuFilterGroups
    
    // MARK: - Cameras list

    case camerasListEmpty
    case camerasListAllCameras
    case camerasListFavorites
    case camerasListLast
    case camerasListRoute
    case camerasListResults
    case camerasListRemoveFavourites
    case camerasListAddFavourite
    case camerasListRemoveRoute
    case camerasListAddRoute
    
    // MARK: - Player

    case playerAccessDenied
    case playerErrorImageLoading
    case playerErrorSaveImage
    
    // MARK: - Archive date picker
    
    case archiveDatePickerSelectDate
    case archiveDatePickerSelectTime
    
    // MARK: - Presets
    
    case presets
    case presetsScreen
    case presetsFrom
    
    // MARK: - Settings
    
    case settingsChangePincodeDelete
    case settingsChangePincodeCreate
    case settingsNoManual
    case settingsDone
    
    // MARK: - Tickets

    case ticketsSubcategoryTreatment
    case ticketsMessage
    case ticketsCategoryAppeal
    case ticketsContentAppeal
    case ticketsClosed
    case ticketsOpen
    
    // MARK: - Info messages
    
    case update
    
    // MARK: - Other
    
    case connectionLost
    case connectionRestored
    
    // MARK: - Localized
    
    var localized: String {
        switch self {

        // MARK: - Login

        case .or:
            return NSLocalizedString("label_text_or", comment: "A text for the \"Select another user\" label")
            
        // MARK: - User agreement
            
        case .userAgreementButtonAccept:
            return NSLocalizedString("user_agreement_button_accept", comment: "To accept")
        case .userAgreementButtonBack:
            return NSLocalizedString("user_agreement_button_back", comment: "Back")
        case .userAgreementTitleLabel:
            return NSLocalizedString("user_agreement_title_label", comment: "User agreement")

        // MARK: - Change password

        case .enterOldPassword:
            return NSLocalizedString("enter_old_password", comment: "Enter your old password")
        case .enterNewPassword:
            return NSLocalizedString("enter_new_password", comment: "Enter your new password")
        case .repeatNewPassword:
            return NSLocalizedString("repeat_new_password", comment: "Repeat your new password")
        case .passwordConfirmationMustMatch:
            return NSLocalizedString("password_confirmation_must_match", comment: "The new password and the password confirmation must match")
            
        // MARK: - Map
        
        case .zoom:
            return NSLocalizedString("map_zoom", comment: "Zoom")
        case .nameMissing:
            return NSLocalizedString("map_name_missing", comment: "The name is missing")
        case .addressMissing:
            return NSLocalizedString("map_address_missing", comment: "The address is missing")
        case .cameraAnnotationDescription:
            return NSLocalizedString("map_camera_annotation_description_notext", comment: "No description")
            
        // MARK: - Menu filter
        
        case .menuFilter:
            return NSLocalizedString("menu_filter", comment: "Filter")
        case .menuFilterStatuses:
            return NSLocalizedString("menu_filter_statuses", comment: "Statuses")
        case .menuFilterAdministrativeDivision:
            return NSLocalizedString("menu_filter_administrative_division", comment: "Administrative division")
        case .menuFilterCameras:
            return NSLocalizedString("menu_filter_cameras", comment: "Cameras")
        case .menuFilterDistricts:
            return NSLocalizedString("menu_filter_districts", comment: "Districts")
        case .menuFilterGroups:
            return NSLocalizedString("menu_filter_groups", comment: "Groups")
            
        // MARK: - Cameras list

        case .camerasListEmpty:
            return NSLocalizedString("cameras_list_empty", comment: "Cameras list is empty")
        case .camerasListAllCameras:
            return NSLocalizedString("cameras_list_all_cameras", comment: "All cameras")
        case .camerasListFavorites:
            return NSLocalizedString("cameras_list_favorites", comment: "Favorites")
        case .camerasListLast:
            return NSLocalizedString("cameras_list_last", comment: "Last")
        case .camerasListRoute:
            return NSLocalizedString("cameras_list_route", comment: "Route")
        case .camerasListResults:
            return NSLocalizedString("cameras_list_results", comment: "Results")
        case .camerasListRemoveFavourites:
            return NSLocalizedString("cameras_list_remove_favourite", comment: "Remove from favourites")
        case .camerasListAddFavourite:
            return NSLocalizedString("cameras_list_add_favourite", comment: "Add to favourite")
        case .camerasListRemoveRoute:
            return NSLocalizedString("cameras_list_remove_route", comment: "Remove from route")
        case .camerasListAddRoute:
            return NSLocalizedString("cameras_list_add_route", comment: "Add to route")
            
        // MARK: - Player

        case .playerAccessDenied:
            return NSLocalizedString("player_access_denied", comment: "Access to photos is denied")
        case .playerErrorImageLoading:
            return NSLocalizedString("player_error_image_loading", comment: "Error loading image from camera")
        case .playerErrorSaveImage:
            return NSLocalizedString("player_error_save_image", comment: "Error when saving a photo. Try to update the picture.")
            
        // MARK: - Archive date picker
        
        case .archiveDatePickerSelectDate:
            return NSLocalizedString("archive_date_picker_select_date", comment: "Select a date")
        case .archiveDatePickerSelectTime:
            return NSLocalizedString("archive_date_picker_select_time", comment: "Select time")
            
        // MARK: - Presets
        
        case .presets:
            return NSLocalizedString("presets", comment: "Presets")
        case .presetsScreen:
            return NSLocalizedString("presets_screen", comment: "Screen")
        case .presetsFrom:
            return NSLocalizedString("presets_from", comment: "from")

        // MARK: - Settings

        case .settingsChangePincodeDelete:
            return NSLocalizedString("settings_changepincode_delete", comment: "Delete a pincode")
        case .settingsChangePincodeCreate:
            return NSLocalizedString("settings_changepincode_create", comment: "Create a pincode")
        case .settingsNoManual:
            return NSLocalizedString("settings_no_manual_label", comment: "The user's manual could not be downloaded")
        case .settingsDone:
            return NSLocalizedString("settings_done", comment: "Done")
            
        // MARK: - Tickets

        case .ticketsSubcategoryTreatment:
            return NSLocalizedString("tickets_subcategory_treatment", comment: "Subcategory of treatment")
        case .ticketsMessage:
            return NSLocalizedString("tickets_message", comment: "Message")
        case .ticketsCategoryAppeal:
            return NSLocalizedString("tickets_category_appeal", comment: "Category of the appeal")
        case .ticketsContentAppeal:
            return NSLocalizedString("tickets_content_appeal", comment: "Content of the appeal")
        case .ticketsClosed:
            return NSLocalizedString("tickets_closed", comment: "Closed")
        case .ticketsOpen:
            return NSLocalizedString("tickets_open", comment: "Open")
            
        // MARK: - Info messages
        
        case .update:
            return NSLocalizedString("info_messages_update", comment: "Update")
            
        // MARK: - Other
            
        case .connectionLost:
            return NSLocalizedString("connection_lost", comment: "Connection lost")
        case .connectionRestored:
            return NSLocalizedString("connection_restored", comment: "Connection restored")
        }
    }
}
