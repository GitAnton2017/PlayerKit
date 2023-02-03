//
//  Player Beating Activity.swift
//  PlayerKit
//
//  Created by Anton2016 on 17.01.2023.
//

import UIKit

final class BeatingActivityView: UIView, NTXPlayerActivityIndicator {
 
 var color: UIColor! {
  get { barColor }
  set { barColor = newValue }
 }
 
 var runningTime: TimeInterval = 3.0
 
 func startAnimating() { isRunning = true }
 
 func stopAnimating() { isRunning = false }
 
 var isAnimating: Bool { isRunning }
 
 var hidesWhenStopped = true
 
 private final var drawTimer: Timer?
 private final var runningBarNumber = -1
 
 private func stopRunningAnimation() {
  drawTimer?.invalidate()
  drawTimer = nil
  runningBarNumber = -1
  if hidesWhenStopped { isHidden = true }
 }
 
 private func stoppingRunningAnimation(_ count: Int,
                                       _ runningTime: TimeInterval,
                                       _ devisor: CGFloat = 2) {
  if isRunning { return }
  guard count > 0 else { stopRunningAnimation(); return }
  
  maxBarHeight /= devisor
  
  DispatchQueue.main.asyncAfter(deadline: .now() + runningTime) { [ weak self ] in
   self?.stoppingRunningAnimation(count - 1, runningTime, devisor)
  }
 }
 
 var isRunning = false {
  didSet {
   switch (oldValue, isRunning) {
    case (true,  false) : stoppingRunningAnimation(10, runningTime / 10, 3)
    case (false, true ) : startPeriodicRedrawings(runningTime)
    default: break
   }
  }
 }
 
 private var N: Int {
  layoutIfNeeded() ///``'Has to get Bounds immediately to calculate relative parameters!!!!
  return Int((bounds.width + barPhase) / (barWidth + barPhase))
 }
 
 private final var barColor: UIColor
 private final let barWidth: CGFloat
 private final let barPhase: CGFloat
 
 private var maxBarHeight: CGFloat = .zero
 
 private final func drawRunningBars() {
  
  let N = self.N
  
  let dA = CGFloat.random(in: 0.05...1.0) / CGFloat(N)
  
  let mid = N / 2
  for i in 0..<N {
   let dh = (barWidth + barPhase) * CGFloat(i)
   
   let k = CGFloat(abs(i - mid))
   let ub = k > 0 ? maxBarHeight / k : maxBarHeight
   let h = CGFloat.random(in: 0...ub)
   let rect = CGRect(origin: CGPoint(x: dh, y: 0), size: .init(width: barWidth, height: h / 2))
   
   let cornerRadii = CGSize(width: barWidth / 2, height: barWidth / 2)
   
   
   let path1 = UIBezierPath(roundedRect: rect,
                            byRoundingCorners: [.bottomLeft, .bottomRight],
                            cornerRadii: cornerRadii)
   
   
   let path2 = UIBezierPath(roundedRect: rect,
                            byRoundingCorners: [.bottomLeft, .bottomRight],
                            cornerRadii: cornerRadii)
   
   let shift = CGAffineTransform(translationX: 0, y: bounds.height / 2  )
   
   path1.apply(CGAffineTransform(scaleX: 1, y: -1).concatenating(shift))
   
   path2.apply(shift)
   
   
   
   barColor.withAlphaComponent(1 - CGFloat(abs(i - runningBarNumber)) * dA).setFill()
   
   path1.append(path2)
   
   path1.fill()
   
  }
 }
 
 init(barColor: UIColor, barWidth: CGFloat, barPhase: CGFloat) {
  self.barColor = barColor
  self.barWidth = barWidth
  self.barPhase = barPhase
  
  super.init(frame: .zero)
  
  self.backgroundColor = .clear
 }
 
 
 override func layoutSubviews() {
  super.layoutSubviews()
  guard bounds != .zero else { return }
  layoutSema.signal()
  runningBarNumber = -1
 }
 
 
 private let layoutSema = DispatchSemaphore(value: 0)
 
 private func startPeriodicRedrawings(_ interval: TimeInterval) {
  DispatchQueue.global(qos: .userInteractive).async { [ weak self ] in
   self?.layoutSema.wait()
   DispatchQueue.main.async { [ weak self ] in
    self?.startDrawingTimer(interval)
    self?.layoutSema.signal()
   }
  }
 }
 
 private final func startDrawingTimer(_ runningTime: TimeInterval) {
  
  isHidden = false
  maxBarHeight = bounds.height
  
  let N = self.N
  
  let interval = runningTime / TimeInterval(N)
  drawTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [ weak self ] _ in
   guard let self = self else { return }
   if self.runningBarNumber > 0 { self.runningBarNumber -= 1 } else { self.runningBarNumber = N }
   self.setNeedsDisplay()
  }
 }
 
 required init?(coder: NSCoder) {
  fatalError("init(coder:) has not been implemented")
 }
 
 
 override func draw(_ rect: CGRect) {
  if ( runningBarNumber == -1 ) { runningBarNumber = N - 1 }
  drawRunningBars()
 }
 
 deinit {
  drawTimer?.invalidate()
 }
 
}
