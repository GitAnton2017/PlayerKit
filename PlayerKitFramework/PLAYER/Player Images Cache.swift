//
//  Player Images Cache.swift
//  AreaSight
//
//  Created by Anton V. Kalinin on 13.12.2022.
//  Copyright © 2022 Netris. All rights reserved.
//

import UIKit

extension UIImage {
 
 enum Quality: CGFloat, Codable, Hashable, CaseIterable {
  
  case lowest  = 0.00
  case low     = 0.25
  case medium  = 0.50
  case high    = 0.75
  case highest = 1.00
 }
 
 func jpegImage(quality: Quality) -> UIImage? {
  guard let imageData = jpegData(compressionQuality: quality.rawValue) else { return nil }
  return UIImage(data: imageData)
 }
}


class ArchiveImagesCache<Fetcher: NTXPlayerConnectionsManager> {
 
 
 
 func prefetch() {
  
 }
 
 var prefetchSize = 100
 
 let instance = ArchiveImagesCache()
 
 private init() {}
 
 private let cache = NSCache<NSNumber, UIImage>()
 
 subscript (depth: Int) -> UIImage? {
  get { cache.object(forKey: depth as NSNumber) }
  set {
   guard let object = newValue else {
    cache.removeObject(forKey: depth as NSNumber)
    return
   }
   cache.setObject(object, forKey: depth as NSNumber)
  }
 }
}

extension NTXPlayerConnectionsManager {
 
 typealias VSSArchiveShotsFetchHandler = (Result<[PhotoShot], Error>) -> ()
 
 
 func prefetchVSSArchiveShots(for VSS: EchdCamera,
                                     timeStamp: Int,
                                     resultHandler: @escaping VSSArchiveShotsFetchHandler) {
  
  guard let url = VSS.getArchiveShotUrls()?.first else {
   resultHandler(.failure(NTXPlayerError.noArchiveShotsURL))
   return
  }
  //TODO: -----
  let dispatchGroup = DispatchGroup()
  
  
  
 }
}
