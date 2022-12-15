//
//  TimeLineView.swift
//  AreaSight
//
//  Created by Александр on 12.10.16.
//  Copyright © 2016 Netris. All rights reserved.
//

//import UIKit
//import QuartzCore
//
//protocol TimeLineViewDelegate: AnyObject {
//    func timeLineViewDelegate(_ sender:TimeLineView?, time:Int)
//    func timeLineViewDelegate(_ sender:TimeLineView?, nextDay:Bool)
//    func timeLineViewDelegate(_ time: Int)
//    func timeLineView(_ sender: TimeLineView?, currentTime: Int)
//    func timeLineViewScaleBegan()
//    func timeLineViewScaleEnded(_ scale: UInt)
//}
//
//public final class TimeLineView: UIView, UIGestureRecognizerDelegate {
//    
//    static let defaultHeight: CGFloat = 50
//    
//    var contextImage:CGContext?
//    let timeImageContext = UIGraphicsGetCurrentContext()
//    
//    weak var delegate:TimeLineViewDelegate?
//    
//    var backgroundLayer:CALayer = CALayer()
//    var timeLayer:CALayer = CALayer()
//    var centerLayer:CALayer = CALayer()
//    var currentTimeLayer:CALayer = CALayer()
//    var badSectorsLayer:CALayer = CALayer()
//    
//    var firstPoint:CGPoint?
//    var secondPoint:CGPoint?
//    var img:UIImage = UIImage()
//    
//    var minImageWidth:Int = 1440
//    var maxImageWidth:Int = 86400
//    let constCurrentImageWidth:Int = 1440
//    var currentImageWidth:Int = 1440
//    
//    var pinch:UIPinchGestureRecognizer?
//    
//    var scale:Double = 1
//    var isTouchMode = false
//    
//    let queue:DispatchQueue = DispatchQueue(label: "redraw")
//    let queueTimer:DispatchQueue = DispatchQueue(label: "timer")
//    
//    var longpressTapGesture:UILongPressGestureRecognizer?
//    var startScale:Double?
//    
//    var upShift:Double = 0.0
//    
//    var timer:Timer?
//    
//    var currentTimePosition = 0
//    var startTimePosition = 0
//    
//    var underlayerWidth = UIScreen.main.bounds.width
//    var badSectors:[(Int,Int)] = [(Int,Int)]()
//    
//    let previewMaxScale: UInt = 12
//    
//    public func setStartPosition(_ seconds:Int) {
//        startTimePosition = seconds
//    }
//    
//    public func setTime(_ seconds:Int) {
//        currentTimePosition = seconds
//        
//        delegate?.timeLineView(self, currentTime: currentTimePosition)
//        let currentTimeImg = drawTimeImage(Int(underlayerWidth), time: currentTimePosition)
//        let res = Double(img.size.width - underlayerWidth) * (Double(seconds) / Double(maxImageWidth))
//        CATransaction.begin()
//        timeLayer.position.x = -CGFloat(res)
//        currentTimeLayer.anchorPoint = CGPoint(x: 0, y: 0)
//        currentTimeLayer.bounds = CGRect(x: 0, y: 0, width: currentTimeImg.size.width, height: currentTimeImg.size.height)
//        currentTimeLayer.contents = currentTimeImg.cgImage
//        currentTimeLayer.position = CGPoint(x: 0, y: 0)
//        currentTimeLayer.isHidden = true
//        CATransaction.commit()
//    }
//    
//    ////////////////////////////////////////////////////////
//    // 1 touch move
//    ////////////////////////////////////////////////////////
// public  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        self.isTouchMode = true
//        CATransaction.begin()
//        currentTimeLayer.isHidden = false
//        CATransaction.commit()
//    }
//    
// public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
//        if timeLayer.position.x > 0 || timeLayer.position.x < -img.size.width + underlayerWidth  {
//            return
//        }
//        
//        let t = touches.first
//        let currentPoint = t?.location(in: self)
//        
//        if let point = t?.previousLocation(in: self), let cPoint = currentPoint {
//            let delta = point.x - cPoint.x
//            let pos = timeLayer.position.x - delta
//            if pos > 0 {
//                CATransaction.begin()
//                timeLayer.position = CGPoint(x: 0, y: timeLayer.position.y)
//                CATransaction.commit()
//            }
//            else if pos < -img.size.width + underlayerWidth {
//                CATransaction.begin()
//                timeLayer.position = CGPoint(x: -img.size.width + underlayerWidth, y: timeLayer.position.y)
//                CATransaction.commit()
//            }
//            else{
//                CATransaction.begin()
//                timeLayer.position = CGPoint(x: timeLayer.position.x - delta, y: timeLayer.position.y)
//                CATransaction.commit()
//            }
//        }
//        
//        ///////////////////////////
//        
//        let positionDouble = Double(abs(self.timeLayer.position.x))
//        let res = positionDouble * Double(self.maxImageWidth) / Double(self.img.size.width - underlayerWidth)
//        let currentTimeImg = self.drawTimeImage(Int(underlayerWidth), time: Int(res))
//        CATransaction.begin()
//        self.currentTimeLayer.anchorPoint = CGPoint(x: 0, y: 0)
//        self.currentTimeLayer.bounds = CGRect(x: 0, y: 0, width: currentTimeImg.size.width, height: currentTimeImg.size.height)
//        self.currentTimeLayer.contents = currentTimeImg.cgImage
//        self.currentTimeLayer.position = CGPoint(x: 0, y: 0)
//        CATransaction.commit()
//        delegate?.timeLineViewDelegate(Int(res))
//    }
//    
// public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
//        let positionDouble = Double(abs(timeLayer.position.x))
//        let res = positionDouble * Double(maxImageWidth) / Double(img.size.width - underlayerWidth)
//        currentTimePosition = Int(res)
//        let currentTimeImg = drawTimeImage(Int(underlayerWidth), time: Int(res))
//        CATransaction.begin()
//        currentTimeLayer.anchorPoint = CGPoint(x: 0, y: 0)
//        currentTimeLayer.bounds = CGRect(x: 0, y: 0, width: currentTimeImg.size.width, height: currentTimeImg.size.height)
//        currentTimeLayer.contents = currentTimeImg.cgImage
//        currentTimeLayer.position = CGPoint(x: 0, y: 0)
//        currentTimeLayer.isHidden = true
//        CATransaction.commit()
//        delegate?.timeLineViewDelegate(self, time: currentTimePosition)
//        self.isTouchMode = false
//    }
//    
//    ////////////////////////////////////////////////////////
//    // pinch scale
//    ////////////////////////////////////////////////////////
//    @objc func handlePinch() {
//        if let pinch = pinch {
//            let scale = pinch.scale
//            self.scale = self.scale * Double(scale)
//            if self.scale > 40.3 {
//                self.scale = 40.3
//            }else if self.scale < 0.8 {
//                self.scale = 0.8
//            }
//            redrawForScale()
//        }
//    }
//    
//    ////////////////////////////////////////////////////////
//    // longpress scale
//    ////////////////////////////////////////////////////////
//    @objc func longpressTapButton(_ sender: UILongPressGestureRecognizer) {
//        let state:UIGestureRecognizer.State = sender.state
//        let location = sender.location(in: self)
//        
//        switch state {
//        case .began:
//            self.isTouchMode = true
//            self.startScale = self.scale
//            upShift = Double(location.y)
//            delegate?.timeLineViewScaleBegan()
//        case .changed:
//            let delta = upShift - Double(location.y)
//            var sc = Double( Int(Int((self.startScale! + delta / 10) / 2) * 2))
//            if sc > 40.3 {
//                sc = 40.3
//            }else if sc < 0.9 {
//                sc = 0.9
//            }
//            if sc != self.scale {
//                self.scale = sc
//                self.redrawForScale()
//            }
//            break
//        case .ended:
//            var roundedScale = UInt(scale)
//            if UInt(scale) >= previewMaxScale {
//                roundedScale = previewMaxScale
//            }
//            upShift = 0
//            self.isTouchMode = false
//            delegate?.timeLineViewScaleEnded(roundedScale)
//            break
//        case .failed:
//            self.isTouchMode = false
//            break
//        case .cancelled:
//            self.isTouchMode = false
//            break
//        default:
//            break
//        }
//    }
//    
//    func redrawForScale() {
//        if Double(self.constCurrentImageWidth) * self.scale < 1440 {
//            self.currentImageWidth = 1440
//        }else if Double(self.constCurrentImageWidth) * self.scale > Double(self.maxImageWidth) {
//            self.currentImageWidth = self.maxImageWidth
//        }else{
//            self.currentImageWidth = Int(Double(self.constCurrentImageWidth) * self.scale)
//        }
//        self.img = self.drawCustomImage(Int(underlayerWidth))
//        CATransaction.begin()
//        self.timeLayer.anchorPoint = CGPoint(x: 0, y: 0)
//        self.timeLayer.bounds = CGRect(x: 0, y: 0, width: self.img.size.width, height: self.img.size.height)
//        self.timeLayer.contents = self.img.cgImage
//        CATransaction.commit()
//        self.setTime(self.currentTimePosition)
//    }
//    
//    /*
//     init
//     */
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        
//        adaptLayer()
//        
//        currentTimeLayer.isHidden = true
//        
//        pinch = UIPinchGestureRecognizer(target: self, action: #selector(TimeLineView.handlePinch))
//        self.addGestureRecognizer(pinch!)
//        
//        longpressTapGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.longpressTapButton(_:)))
//        longpressTapGesture?.delegate = self
//        self.addGestureRecognizer(longpressTapGesture!)
//    }
//    
//    required init?(coder aDecoder: NSCoder) {
//        super.init(coder: aDecoder)
//    }
//    
//    public convenience init() {
//        self.init(frame: CGRect.zero)
//    }
//    
//    func startTimer() {
//        if nil != timer {
//            timer?.invalidate()
//            timer = nil
//        }
//        timer = Timer(timeInterval: 1, target: self, selector: #selector(addSecond), userInfo: nil, repeats: true)
//        
//        if let timer = self.timer {
//            RunLoop.current.add(timer, forMode: RunLoop.Mode.default)//commonModes
//        }
//    }
//    
//    func stopTimer() {
//        timer?.invalidate()
//        timer = nil
//    }
//    
//    @objc func addSecond() {
//        if self.isTouchMode {
//            return
//        }
//        if self.currentTimePosition + 1 < 86400 {
//            let position = self.currentTimePosition + 1
//            self.setTime(position)
//        }else{
//            self.delegate?.timeLineViewDelegate(self, nextDay: true)
//            self.setTime(0)
//        }
//    }
//    
//    func drawTimeImage(_ screenWidth:Int, time:Int) -> UIImage {
//        let size: CGSize = CGSize(width: screenWidth, height: 50)
//        let opaque = false
//        let scale: CGFloat = 0
//        UIGraphicsBeginImageContextWithOptions(size, opaque, scale)
//        UIColor.white.set()
//        timeImageContext?.beginPath()
//        let textColor = UIColor.white
//        let textFont = UIFont(name: "SFUIDisplay-Light", size: 10)!
//        let text:NSString = timeToString(time) as NSString
//
//        let rect = CGRect(x: screenWidth / 2 - 19 , y:2, width: 60, height: 20)
//        text.draw(in: rect, withAttributes: [NSAttributedString.Key.font:textFont,NSAttributedString.Key.foregroundColor:textColor])
//        let image = UIGraphicsGetImageFromCurrentImageContext()!
//        UIGraphicsEndImageContext()
//        return image
//    }
//    
//    func drawCustomImage(_ screenWidth:Int) -> UIImage {
//        let size: CGSize = CGSize(width: currentImageWidth + screenWidth, height: 50)
//        let opaque = false
//        let scale: CGFloat = 0
//        UIGraphicsBeginImageContextWithOptions(size, opaque, scale)
//        contextImage = UIGraphicsGetCurrentContext()
//        contextImage?.setLineWidth(1.0)
//        UIColor.white.set()
//        
//        contextImage?.beginPath()
//        
//        let textColor = UIColor.white
//        let textFont = UIFont(name: "SFUIDisplay-Light", size: 10)!
//        let textFontAttributes = [NSAttributedString.Key.font:textFont,NSAttributedString.Key.foregroundColor:textColor]
//        let hourWidth:Double = Double(currentImageWidth) / Double(24)
//        let halfScreenWidth:Double = Double(screenWidth) / Double(2)
//        
//        for i in 0..<25 {
//            var text:NSString = "\(i):00" as NSString
//            if i < 10 {
//                text = "0\(i):00" as NSString
//            }
//            
//            let rect = CGRect(x: Int(Double(i) * hourWidth - Double(12) + halfScreenWidth), y: 34, width: 40, height: 30)
//            text.draw(in: rect, withAttributes: textFontAttributes)
//            
//            
//            var linesCount = Int(5.0 * self.scale)
//            if linesCount > 5 {
//                linesCount = linesCount + 15
//            }
//            let linesCount1 = Double(linesCount + 1)
//            if i < 24 {
//                let hourX = Double(i) * hourWidth
//                
//                for item in 1...linesCount {
//                    contextImage?.move(to: CGPoint(x:hourX +  (hourWidth / linesCount1) * Double(item) + halfScreenWidth, y:20))
//                    contextImage?.addLine(to: CGPoint(x:hourX + (hourWidth / linesCount1) * Double(item) + halfScreenWidth, y:30))
//                }
//            }
//        }
//        contextImage?.strokePath()
//        contextImage?.setLineWidth(2.0)
//        contextImage?.beginPath()
//        for i in 0..<25 {
//            contextImage?.move(to: CGPoint(x:Double(i) * hourWidth + halfScreenWidth, y:20))
//            contextImage?.addLine(to: CGPoint(x:Double(i) * hourWidth + halfScreenWidth, y:30))
//        }
//        contextImage?.strokePath()
//        let image = UIGraphicsGetImageFromCurrentImageContext()!
//        UIGraphicsEndImageContext()
//        return image
//    }
//    
//    func drawCenterLineImage(_ screenWidth:Int) -> UIImage {
//        let size: CGSize = CGSize(width: screenWidth, height: 50)
//        let opaque = false
//        let scale: CGFloat = 0
//        UIGraphicsBeginImageContextWithOptions(size, opaque, scale)
//        let context = UIGraphicsGetCurrentContext()
//        context?.beginPath()
//        context?.setLineWidth(2.0)
//        UIColor.red.set()
//        context?.beginPath()
//        context?.move(to: CGPoint(x:screenWidth / 2, y:15))
//        context?.addLine(to: CGPoint(x: screenWidth / 2, y:35))
//        context?.strokePath()
//        let image = UIGraphicsGetImageFromCurrentImageContext()!
//        UIGraphicsEndImageContext()
//        return image
//    }
//    
//    func timeToString(_ time:Int) -> String {
//
//        let hours:Int = time / 3600
//        let minutes:Int = (time - hours * 3600) / 60
//        let seconds:Int = (time - hours * 3600) - minutes * 60
//        var hoursStr = "\(hours)"
//        if hours < 10 {
//            hoursStr = "0\(hours)"
//        }
//        var minutesStr = "\(minutes)"
//        if minutes < 10 {
//            minutesStr = "0\(minutes)"
//        }
//        var secondsStr = "\(seconds)"
//        if seconds < 10 {
//            secondsStr = "0\(seconds)"
//        }
//        return "\(hoursStr):\(minutesStr):\(secondsStr)"
//    }
//    
//    func adaptLayer() {
//        backgroundLayer.anchorPoint = CGPoint(x: 0, y: 0)
//        backgroundLayer.backgroundColor = UIColor(red: 0, green: 0, blue: 0.0, alpha: 0.2).cgColor
//        backgroundLayer.bounds = CGRect(x: 0, y: 0, width: Int(underlayerWidth), height: 50)
//        backgroundLayer.position = CGPoint(x: 0, y: 0)
//        self.layer.addSublayer(backgroundLayer)
//        
//        img = drawCustomImage(Int(underlayerWidth))
//        timeLayer.anchorPoint = CGPoint(x: 0, y: 0)
//        timeLayer.bounds = CGRect(x: 0, y: 0, width: img.size.width, height: img.size.height)
//        timeLayer.contents = img.cgImage
//        timeLayer.position = CGPoint(x: 0 , y: 0)
//        self.layer.addSublayer(timeLayer)
//        
//        let lineImg = drawCenterLineImage(Int(underlayerWidth))
//        centerLayer.anchorPoint = CGPoint(x: 0, y: 0)
//        centerLayer.bounds = CGRect(x: 0, y: 0, width: lineImg.size.width, height: lineImg.size.height)
//        centerLayer.contents = lineImg.cgImage
//        centerLayer.position = CGPoint(x: 0, y: 0)
//        self.layer.addSublayer(centerLayer)
//        
//        let currentTimeImg = drawTimeImage(Int(underlayerWidth), time: 43202)
//        currentTimeLayer.anchorPoint = CGPoint(x: 0, y: 0)
//        currentTimeLayer.bounds = CGRect(x: 0, y: 0, width: currentTimeImg.size.width, height: currentTimeImg.size.height)
//        currentTimeLayer.contents = currentTimeImg.cgImage
//        currentTimeLayer.position = CGPoint(x: 0, y: 0)
//        self.layer.addSublayer(currentTimeLayer)
//        
//        if currentTimePosition != 0 {
//            setTime(currentTimePosition)
//        }
//    }
//    
//    func destroy() {
//        timer?.invalidate()
//        timer = nil
//        delegate = nil
//        removeFromSuperview()
//    }
//    
//    deinit {
//        timer?.invalidate()
//        timer = nil
//    }
//    
//}
//
