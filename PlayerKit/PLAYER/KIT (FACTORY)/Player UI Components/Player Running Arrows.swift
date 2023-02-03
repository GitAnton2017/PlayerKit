//
//  Player Running Arrows.swift
//  PlayerKit
//
//  Created by Anton2016 on 18.01.2023.
//

import UIKit

extension UIBezierPath {
 convenience init(points: [CGPoint]) {
  self.init()
  guard let p0 = points.first else {return}
  move(to: p0)
  points.dropFirst().forEach{addLine(to: $0)}
  close()
 }
}

final class RunningArrowView: UIView, NTXPlayerActivityIndicator {
 
 var color: UIColor! {
  get { arrowColor }
  set { arrowColor = newValue }
 }
 
 var runningTime: TimeInterval = 1
 
 func startAnimating() { isRunning = true }
 
 func stopAnimating() { isRunning = false }
 
 var stopAnimationHandler: ( () -> () )?
 
 var isAnimating: Bool { isRunning }
 
 var hidesWhenStopped = true
 
 private final var drawTimer: Timer? {
  didSet { oldValue?.invalidate() }
 }
 
 private final var runningArrowNumber = -1
 
 private func stopRunningAnimation() {
  isStopping = false
  drawTimer?.invalidate()
  drawTimer = nil
  runningArrowNumber = -1
  if hidesWhenStopped { isHidden = true }
  stopAnimationHandler?()
  
 }
 
 private func stoppingRunningAnimation(_ count: Int,
                                       _ runningTime: TimeInterval) {
  
  guard count > 0 else { stopRunningAnimation(); return }
  
  if isRunning { return }
  
  stopArrowCount = count
  
  DispatchQueue.main.asyncAfter(deadline: .now() + runningTime) { [ weak self ] in
   self?.stoppingRunningAnimation(count - 1, runningTime)
  }
 }
 
 private var isRunning = false {
  didSet {
   switch (oldValue, isRunning) {
     
    case (true, false):
     let count = arrowsCount
     let interval = runningTime / TimeInterval(count)
     isStopping = true
     stoppingRunningAnimation(count, interval)
     
    case (false, true):
     
     isHidden = false
     isStopping = false
     startPeriodicRedrawing(runningTime, arrowsCount)
     
    default: break
   }
  }
 }
 
 
 private var arrowsCount: Int {
  layoutIfNeeded() ///Has to get Bounds immediately to calculate relative parameters!!!!
  return Int((bounds.height + arrowPhase - h) / (arrowWidth + arrowPhase))
 }
 
 private var h: CGFloat {
  layoutIfNeeded()
  return bounds.width / (2 * tan(arrowSharpness / 2 ))
 }
 
 private var stopArrowCount: Int = 0
 
 private var isStopping = false
 
 private final var arrowColor: UIColor
 private final var arrowWidth: CGFloat
 private final var arrowPhase: CGFloat
 private final let arrowSharpness: CGFloat
 
 private final func drawRunningArrows() {
  
  guard isRunning || isStopping else { return }
  
  let N = isStopping ? stopArrowCount : arrowsCount
  
  let dA = 1.5 / CGFloat(N)
 
  for i in 0..<N {
   let dh = (arrowWidth + arrowPhase) * CGFloat(i)
   let p1 = CGPoint(x: 0, y: h + dh)
   let p2 = CGPoint(x: bounds.width / 2, y: dh)
   let p3 = CGPoint(x: bounds.width , y: h + dh)
   let p4 = CGPoint(x: bounds.width, y: h + dh + arrowWidth )
   let p5 = CGPoint(x: bounds.width / 2 , y: dh + arrowWidth)
   let p6 = CGPoint(x: 0, y: h + dh + arrowWidth)
   let path = UIBezierPath(points: [p1, p2 ,p3, p4, p5, p6])
   arrowColor.withAlphaComponent(1 - CGFloat(abs(i - runningArrowNumber)) * dA).setFill()
   path.fill()
  }
 }
 
 private var relativeArrowWidth: CGFloat = .zero
 private var relativeArrowPhase: CGFloat = .zero
 
 convenience init(arrowColor: UIColor,
                  relativeArrowWidth: CGFloat,
                  relativeArrowPhase: CGFloat,
                  arrowSharpness: CGFloat) {
  
  self.init(arrowColor: arrowColor,
            arrowWidth: .zero,
            arrowPhase: .zero,
            arrowSharpness: arrowSharpness)
  
  self.relativeArrowWidth = relativeArrowWidth
  self.relativeArrowPhase = relativeArrowPhase
  
  
 }
 
 init(arrowColor: UIColor,
      arrowWidth: CGFloat,
      arrowPhase: CGFloat,
      arrowSharpness: CGFloat) {
  
  self.arrowColor = arrowColor
  self.arrowWidth = arrowWidth
  self.arrowPhase = arrowPhase
  self.arrowSharpness = arrowSharpness
  
  super.init(frame: .zero)
  
  self.backgroundColor = .clear
 }
 
 
 override func layoutSubviews(){
  
  print(#function, String(describing: Self.self), bounds)
  
  super.layoutSubviews()
  guard bounds != .zero else { return }
  layoutSema.signal()
  runningArrowNumber = -1
  if arrowWidth == 0.0 && relativeArrowWidth > 0.0 && relativeArrowWidth <= 1.0 {
   arrowWidth = bounds.height * relativeArrowWidth
  }
  
  if arrowPhase == 0.0 && relativeArrowPhase > 0.0 && relativeArrowPhase <= 1.0 {
   arrowPhase = bounds.height * relativeArrowPhase
  }
  
 }
 
 private let layoutSema = DispatchSemaphore(value: 0)
 
 private func startPeriodicRedrawing (_ interval: TimeInterval, _ arrowsCount: Int) {
  DispatchQueue.global(qos: .userInteractive).async { [ weak self ] in
   self?.layoutSema.wait()
   DispatchQueue.main.async { [ weak self ] in
    self?.startDrawingTimer(interval, arrowsCount)
    self?.layoutSema.signal()
   }
  }
 }
 
 private final func startDrawingTimer(_ interval: TimeInterval, _ arrowsCount: Int) {
  
  let time = interval / TimeInterval(arrowsCount)
  
  drawTimer = Timer.scheduledTimer(withTimeInterval: time, repeats: true) { [ weak self ] timer in
   
   guard let self = self else { return }
   
   if self.runningArrowNumber > 0 { self.runningArrowNumber -= 1 }
   else {
    self.runningArrowNumber = self.isStopping ? self.stopArrowCount : self.arrowsCount
   }
   
   self.setNeedsDisplay()
  }
 }
 
 required init?(coder: NSCoder) {
  fatalError("init(coder:) has not been implemented")
 }
 
 
 override func draw(_ rect: CGRect) { drawRunningArrows() }
 
 deinit { drawTimer?.invalidate() }
 
}


