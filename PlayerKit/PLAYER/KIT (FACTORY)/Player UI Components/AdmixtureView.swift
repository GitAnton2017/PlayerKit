//
//  AdmixtureView.swift
//  AreaSight
//
//  Created by Artem Lytkin on 12/08/2019.
//  Copyright © 2019 Netris. All rights reserved.
//

import UIKit

class AdmixtureView: UIView, IAdmixtureView {
    var canvasWidth: CGFloat {
        return bounds.width
    }
    
    var canvasHeight: CGFloat {
        return bounds.height
    }
    
    var scale: Int = 1
    private var scaleDP: CGFloat = 1.0
    
    private var options: Options?
    private var admixture: VideoAdmixture?
    private var drawPoint: CGPoint?
    
    private var currentPlayerWidth: CGFloat = 0
    private var currentPlayerHeight: CGFloat = 0
    private var currentVideoWidth: CGFloat = 0
    private var currentVideoHeight: CGFloat = 0
    private var isSizedCorrect = false
    
    func enableAdmixture(options: Options) {
        isUserInteractionEnabled = false
        self.options = options
        admixture = VideoAdmixture(options: options, target: self)
    }
    
    func redraw() {
        layer.sublayers?.forEach {
            $0.removeFromSuperlayer()
        }
        
        setNeedsDisplay()
    }
    
    func drawAt(minX: CGFloat, maxX: CGFloat, minY: CGFloat, maxY: CGFloat) {
        
        let absMinX = abs(minX)
        let absMaxX = abs(maxX)
        let absMinY = abs(minY)
        let absMaxY = abs(maxY)
        
        let x = CGFloat.random(in: min(absMinX, absMaxX)...max(absMinX, absMaxX))
        let y = CGFloat.random(in: min(absMinY, absMaxY)...max(absMinY, absMaxY))
        drawPoint = CGPoint(x: x, y: y)
        redraw()
    }
    
    func clear() {
        drawPoint = nil
        redraw()
    }
    
    override func draw(_ rect: CGRect) {
        guard let avatar = options?.avatar,
            let point = drawPoint,
            isSizedCorrect else {
                
                
                return
        }
        
        for x in 0..<avatar.width {
            for y in 0..<avatar.height {
                if avatar.canvas[y][x] {
                    
                    let layer = CALayer()
                    // TODO: - It has to get a color from settings
                    layer.backgroundColor = UIColor.black.cgColor
                    let tileOrigin = CGPoint(x: point.x + CGFloat(x) * CGFloat(scaleDP),
                                             y: point.y + CGFloat(y) * CGFloat(scaleDP))
                    let sizeOfTile = CGSize(width: scaleDP, height: scaleDP)
                    layer.frame = CGRect(origin: tileOrigin, size: sizeOfTile)
                    self.layer.addSublayer(layer)
                }
            }
        }
    }
    
    func resizeToPlayer(playerWidth: CGFloat, playerHeight: CGFloat, videoWidth: CGFloat, videoHeight: CGFloat, origin: CGPoint) {
        
        guard currentPlayerWidth != playerWidth,
            currentPlayerHeight != playerHeight,
            currentVideoWidth != videoWidth,
            currentVideoHeight != videoHeight else { return }
        
        currentPlayerWidth = playerWidth
        currentPlayerHeight = playerHeight
        currentVideoWidth = videoWidth
        currentVideoHeight = videoHeight
        
        let viewRatio = playerWidth / playerHeight
        let videoRatio = videoWidth / videoHeight
        var targetWidth: CGFloat = 0
        var targetHeight: CGFloat = 0
        
        if viewRatio <= videoRatio {
            targetWidth = playerWidth
            targetHeight = targetWidth / videoRatio
        } else {
            targetHeight = playerHeight
            targetWidth = targetHeight * videoRatio
        }
        
        DispatchQueue.main.async {
            let newSize = CGSize(width: targetWidth, height: targetHeight)
            let newFrame = CGRect(origin: origin, size: newSize)
            self.frame = newFrame
        }
        
        isSizedCorrect = true
        
        redraw()
    }
    
 
   
 
    @discardableResult
    public static func createAdmixture(videoRect: CGRect,
                                       attachedTo view: UIView,
                                       securityMarker: String) -> AdmixtureView? {
       
     debugPrint(#function)
     
     if let admixture = view.subviews.compactMap({$0 as? Self}).first {
      admixture.removeFromSuperview()
     }
     
     
     
     guard let options = Options.makeOptions(from: securityMarker) else { return nil }
            
     let admixture = AdmixtureView()
     
     admixture.backgroundColor = UIColor.white.withAlphaComponent(0.0000000000001)
     
     admixture.enableAdmixture(options: options)
     
     admixture.resizeToPlayer(playerWidth:   view.frame.width,
                              playerHeight:  view.frame.height,
                              videoWidth:    videoRect.width,
                              videoHeight:   videoRect.height,
                              origin:        videoRect.origin)
  
     view.addSubview(admixture)
  
     return admixture
        
        
       
    }
}
