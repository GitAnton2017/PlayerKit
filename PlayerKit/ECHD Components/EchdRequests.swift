//
//  EchdRequests.swift
//  AreaSight
//
//  Created by Александр on 12.05.17.
//  Copyright © 2017 Netris. All rights reserved.
//

import UIKit

class EchdRequests: NSObject {

    // GET

    static let ajaxGetDateRequest = "/ajaxGetDate"

    static let getVideoUrlsRequest = "/camera/ajaxGetVideoUrls?id=&instance="
    static let getCameraListRequest = "/camera/ajaxGetCameraList?instance=&json="
    
    static let presetAjaxListRequest = "/camera/preset/ajaxList"

    static let ajaxAddToFavorite = "/camera/ajaxAddToFavorite?id="
    static let ajaxRemoveFromFavorite = "/camera/ajaxRemoveFromFavorite?id="
    
    static let echdMakePhotoRequest = "from json"

    static let cameraManagerAjaxGetPositionRequest = "/cameraManager/ajaxGetPosition?ids="
    static let cameraTurnerAjaxMoveRequest = "/cameraTurner/ajaxMove?id=&command="
    static let cameraTurnerAjaxGoToHomeRequest = "/cameraTurner/ajaxGoToHome?id="

    // POST
    
    static let authRequest = "/j_spring_security_check"

    static let getNoticeListRequest = "/notice/getNoticeList"
    
    static let ajaxGetSettingsRequest = "/settings/ajaxGetSettings?source=user,environment,forms&format=json"
    static let ajaxSetUserSettingsRequest = "/settings/ajaxSetUserSettings"
    static let ajaxSearchCameraListRequest = "/camera/ajaxSearchCameraList?instance="

    static let echdArchiveControlsRequest = "from json"
    
    static let ajaxClearFavorite = "/camera/ajaxClearFavorite"
    
    static let ajaxClearCameraLastAccessHistory = "/camera/ajaxClearCameraLastAccessHistory"
    
}
