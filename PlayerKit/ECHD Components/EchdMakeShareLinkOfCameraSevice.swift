//
//  EchdMakeVideoArchiveService.swift
//  AreaSight
//
//  Created by Artem Lytkin on 27.08.2018.
//  Copyright © 2018 Netris. All rights reserved.
//

import Foundation
import Alamofire

struct ShareLinkOfCamera: Decodable {
    let success: Bool
    let url: String
}

protocol EchdMakeShareLinkOfCameraSeviceProtocol {
    
    func makeShareLiveVideoLinkOfCamera( managerCredential: EchdConnectionManagerCredential,
                                                cameraId: Int,
                                                completion: @escaping ((String?, Error?) -> Void) )
    
    func makeShareArchiveVideoLinkOfCamera( managerCredential: EchdConnectionManagerCredential,
                                cameraId: Int,
                                dateInSeconds: Int,
                                completion: @escaping ((String?, Error?) -> Void) )
}

class EchdMakeShareLinkOfCameraSevice: EchdMakeShareLinkOfCameraSeviceProtocol {
    
    func makeShareArchiveVideoLinkOfCamera(managerCredential: EchdConnectionManagerCredential, cameraId: Int, dateInSeconds: Int, completion: @escaping ((String?, Error?) -> Void)) {
        // 1
        guard let cookie = managerCredential.cookie else { return }
        guard let host = managerCredential.host else { return }
        
        let urlString = host + "/embed/generateLink"
        let headers = Headers.getHeadersWithCookie(cookie)
        
        // 2
        EchdConnectionManager.sharedInstance.alamofireManager.request(urlString,
                          method: .get,
                          parameters: ["id": cameraId, "position": dateInSeconds],
                          headers: headers).responseJSON { response in
                            // 1
                            guard let data = try? response.result.get() as? Data else {
                                    debugPrint("EchdMakeShareLinkOfCameraSevice::makeShareArchiveVideoLinkOfCamera: Error was occured while make archive request \(String(describing:response.error))")
                                    completion(nil, response.error)
                                    return
                            }
                            
                            // 2
                            let decoder = JSONDecoder()
                            let shareLinkOfCamera = try? decoder.decode(ShareLinkOfCamera.self,
                                                                        from: data)
                            
                            completion(shareLinkOfCamera?.url, nil)
        }
    }
    
    
    // MARK - EchdMakeShareLinkOfCameraSeviceProtocol
    
    func makeShareLiveVideoLinkOfCamera( managerCredential: EchdConnectionManagerCredential,
                                cameraId: Int,
                                completion: @escaping ((String?, Error?) -> Void) ) {
        // 1
        guard let cookie = managerCredential.cookie else { return }
        guard let host = managerCredential.host else { return }
        
        let urlString = host + "/embed/generateLink"
        let headers = Headers.getHeadersWithCookie(cookie)
        
        // 2
        EchdConnectionManager.sharedInstance.alamofireManager.request(urlString,
                          method: .get,
                          parameters: ["id": cameraId],
                          headers: headers).responseJSON { response in
                            // 1
                            guard let data = response.data else {
                                    completion(nil, response.error)
                                    debugPrint("EchdMakeShareLinkOfCameraSevice::makeShareLiveVideoLinkOfCamera: Error was occured while make archive request \(String(describing:response.error))")
                                    return
                            }
                            
                            // 2
                            let decoder = JSONDecoder()
                            let shareLinkOfCamera = try? decoder.decode(ShareLinkOfCamera.self,
                                                                            from: data)
                            
                            completion(shareLinkOfCamera?.url, nil)
        }
    }
    
}



/*
 A request response:
 
 {"success":true,"url":"http://obmen-video.echd.ru/TQX514"}
 */
