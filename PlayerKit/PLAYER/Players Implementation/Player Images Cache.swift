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

internal protocol ArchiveImagesCacheDelegate where Self: AnyObject {
 
 var startSeconds: Int { get }
 var endSeconds:   Int { get }
 
 func fetchArchiveImage(depthSeconds: Int, handler: @escaping (UIImage?) -> () )
}


final internal class ArchiveImagesCache {
 
 var prefetchSize = 50
 
 var interval = 10
 
 var defaultImageQuality: UIImage.Quality = .low
 
 private let cache = NSCache<NSNumber, UIImage>()
 
 private let cacheQueue = DispatchQueue(label: "ArchiveImagesCache.Quueue", qos: .userInteractive)
 
 weak var delegate: ArchiveImagesCacheDelegate?
 
 var startSeconds: Int { delegate?.startSeconds ??  0 }
 
 var endSeconds:   Int { delegate?.endSeconds   ??  0 }
 
 private lazy var initialFetcher: () = { [ unowned self ] in
  
  debugPrint("IMAGE CACHE INITIALIZED", #function)
  
  prefetchSize = 50 // make first prefetch bigger first time requested
  prefetch(around: endSeconds)
  prefetchSize = 20
 }()
 
 func prefetch() {
//  debugPrint("IMAGE CACHE ACTIVITY", #function)
  _ = initialFetcher
 }
 
 func prefetch(around depth: Int, completion: ( ([ Int ]) -> () )? = nil) {
  
//  debugPrint("IMAGE CACHE ACTIVITY", #function, depth)
  
  guard let delegate = self.delegate else { return }
 
  let stride = Array(stride(from : max(startSeconds,  depth - interval * prefetchSize / 2),
                            to   : min(endSeconds  ,  depth + interval * prefetchSize / 2),
                            by   : interval))
  
  let group = DispatchGroup()
  var depthArray = [Int]()
  for depth in stride where self[depth] == nil {
   group.enter()
   delegate.fetchArchiveImage(depthSeconds: depth){ [ weak self ] image in
    guard let self = self else { return }
    guard let image = image?.jpegImage(quality: self.defaultImageQuality) else { return }
    self[depth] = image
    self.cacheQueue.async {
     depthArray.append(depth)
     group.leave()
    }
   }
  }
  
  group.notify(queue: .main){ completion?(depthArray) }
 }
 
 
 func image(with depth: Int, handler: @escaping (UIImage?) -> () ) {
  
//  debugPrint("IMAGE CACHE ACTIVITY", #function, depth)
  
  defer { prefetch(around: depth) }
  
  if let image = self[depth] {
   DispatchQueue.main.async { handler(image) }
   return
  }
  
  
  delegate?.fetchArchiveImage(depthSeconds: depth){ [ weak self ] image in
   guard let self = self else { return }
   
   defer { self.prefetch(around: depth) }
   guard let image = image?.jpegImage(quality: self.defaultImageQuality) else {
    DispatchQueue.main.async { handler(nil) }
    return
   }
   self[depth] = image
   DispatchQueue.main.async { handler(image) }
  }
 
  
  
 }
 
 func purge() {
  debugPrint(#function)
  cache.removeAllObjects()
 }
 
 subscript (depth: Int) -> UIImage? {
  get { cacheQueue.sync { cache.object(forKey: depth as NSNumber) } }
  set {
   cacheQueue.async { [ weak self ] in
    guard let object = newValue else {
     self?.cache.removeObject(forKey: depth as NSNumber)
     return
    }
    self?.cache.setObject(object, forKey: depth as NSNumber)
   }
   
  }
 }
}



