//
//  EchdMakeVideoArchiveService.swift
//  AreaSight
//
//  Created by Artem Lytkin on 27.08.2018.
//  Copyright © 2018 Netris. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import UIKit

internal struct TimeLimit: Codable {
    var maximumDate: Date
    var minimumDate: Date
}

internal struct VideoArchiveOrderInfo: Codable {
    var id: String
    var number: Int
    var success: Bool
}

internal struct VideoArchiveOrderMessage: Codable {
    var message: String
    var success: Bool
}

protocol EchdMakeVideoArchiveServiceProtocol {
    
    func getCameraVideoArchiveOrderMinMaxDates( managerCredential: EchdConnectionManagerCredential,
                                                cameraId: Int,
                                                completion: @escaping ((TimeLimit?, Error?) -> Void) )
    
    func requestMakeOrderForVideoArchive( managerCredential: EchdConnectionManagerCredential,
                                          cameraId: Int,
                                          beginDate: Int,
                                          endDate: Int,
                                          reason: String,
                                          completion: @escaping ((VideoArchiveOrderInfo?, VideoArchiveOrderMessage?, Error?) -> Void) )
}

class EchdMakeVideoArchiveService: EchdMakeVideoArchiveServiceProtocol {
    
    // MARK - EchdMakeVideoArchiveServiceProtocol
    
    var alamofireManager: Session = {
        let urlSessionConfig = URLSessionConfiguration.default
        urlSessionConfig.timeoutIntervalForResource = Time.timeoutForRequests
        urlSessionConfig.timeoutIntervalForRequest = Time.timeoutForRequests
        urlSessionConfig.waitsForConnectivity = true
        let manager = Alamofire.Session(configuration: urlSessionConfig)
        return manager
    }()
    
    func getCameraVideoArchiveOrderMinMaxDates( managerCredential: EchdConnectionManagerCredential, cameraId: Int, completion: @escaping ((TimeLimit?, Error?) -> Void) ) {
        
        getCameraVideoUrlsForVideoArchive(managerCredential: managerCredential,
                                          cameraId: cameraId) { [weak self] (urlStrings, error) in
            
            // 1
            guard let urlStrings = urlStrings,
                let cookie = managerCredential.cookie,
                let cameraVideoLimitUrlString = self?.getValidUrlStringFrom(urlStrings) else {
                    completion(nil, error)
                    return
            }
                                            
            let headers = Headers.getHeadersWithCookie(cookie)
             
            // 2
            EchdConnectionManager.sharedInstance.alamofireManager.request(cameraVideoLimitUrlString,
                              method: .post,
                              parameters: nil,
                              headers: headers).responseJSON(completionHandler: { (response) in
                                guard let value = response.data else {
                                    completion(nil, error)
                                    return
                                }
                                // 3
                                let secondsFromGMT = Double(TimeZone.current.secondsFromGMT())
                                
                                let endDateString = Double( JSON(value)["recording"]["end"].doubleValue * 0.001 + secondsFromGMT)
                                let startDateString = Double( JSON(value)["recording"]["start"].doubleValue * 0.001 + secondsFromGMT)

                                let startDate = Date(timeIntervalSince1970: TimeInterval(startDateString))
                                let endDate = Date(timeIntervalSince1970: TimeInterval(endDateString))
                                
                                let timeLimit = TimeLimit(maximumDate: endDate, minimumDate: startDate)
                                
                                // 4
                                completion(timeLimit, nil)
                              })
        }
    }
    
    func requestMakeOrderForVideoArchive( managerCredential: EchdConnectionManagerCredential,
                                          cameraId: Int,
                                          beginDate: Int,
                                          endDate: Int,
                                          reason: String,
                                          completion: @escaping ((VideoArchiveOrderInfo?, VideoArchiveOrderMessage?, Error?) -> Void) ) {
        
        // 1
        guard let cookie = managerCredential.cookie else { return }
        guard let host = managerCredential.host else { return }
        
        let urlString = host + "/video/archive/task/create"
        let headers = Headers.getHeadersWithCookie(cookie)
        
        alamofireManager.request(urlString,
                          method: .get,
                          parameters:  [
                            "id": cameraId,
                            "beginDate": beginDate,
                            "endDate": endDate,
                            "reason": reason],
                          headers: headers).responseJSON { response in
                            // 1
                            guard let data = response.data else {
                                    debugPrint("EchdMakeVideoArchiveService::requestMakeOrderForVideoArchive: Error was occured while make archive request \(String(describing:response.error))")
                                    return
                            }

                            var customError: Error? = response.error
                            
                            // 2
                            let decoder = JSONDecoder()
                            
                            do {
                                let videoArchiveOrderInfo = try decoder.decode(VideoArchiveOrderInfo.self,
                                                                                from: data)
                                completion(videoArchiveOrderInfo, nil, nil)
                            } catch {
                                customError = error
                            }
                            
                            do {
                                let videoArchiveOrderMessage = try decoder.decode(VideoArchiveOrderMessage.self,
                                                                               from: data)
                                completion(nil, videoArchiveOrderMessage, nil)
                            } catch {
                                customError = error
                            }
                            
                            completion(nil, nil, customError)
        }
    }
    
    // MARK: - Private
    
    private func getValidUrlStringFrom(_ urlStrings: [String]) -> String? {
        for urlString in urlStrings {
            if let url = URL(string: urlString) {
                if UIApplication.shared.canOpenURL(url) {
                    return urlString
                }
            }
        }
        
        return nil
    }
    
    private func getCameraVideoUrlsForVideoArchive(managerCredential: EchdConnectionManagerCredential, cameraId: Int, completion: @escaping (([String]?, Error?) -> Void) ) {
        
        guard let cookie = managerCredential.cookie,
            let host = managerCredential.host else { return }
        
        let urlString = host + "/camera/ajaxGetVideoUrls"
        let headers = Headers.getHeadersWithCookie(cookie)
        
        EchdConnectionManager.sharedInstance.alamofireManager.request(urlString,
                          method: .get,
                          parameters: ["id": cameraId],
                          headers: headers)
            .responseJSON(completionHandler: { (response) in
                guard  let value = response.data else {
                    return
                }
                
                let urlStrings: [String]? = JSON(value)[String(cameraId)]["archive"]["shot"]["control"].array?.map { json in
                    if let urlString = json.string {
                       return urlString
                    } else {
                        return ""
                    }
                }

                completion(urlStrings, nil)
            })
    }
}
