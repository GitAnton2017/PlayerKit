//
//  Player Archive Controls View.swift
//  PlayerKit
//
//  Created by Anton2016 on 18.01.2023.
//

import UIKit

final internal class ArchiveControlsView: UIView, NTXPlayerTimeLine {
 
 func stopAnimating( _ stopAnimationHandler: ( () -> () )? = nil ) {
  
  if leftArrow.isAnimating  {
   leftArrow.stopAnimationHandler = { [ weak self ] in self?.isHidden = true; stopAnimationHandler?() }
   leftArrow.stopAnimating()
   
  }
  
  if rightArrow.isAnimating {
   rightArrow.stopAnimationHandler = { [ weak self ] in self?.isHidden = true; stopAnimationHandler?() }
   rightArrow.stopAnimating()
  }
  
 }
 
 
 private lazy var depthLabel = {
  let label = UILabel()
  label.numberOfLines = 1
  label.minimumScaleFactor = 0.05
  label.font = .systemFont(ofSize: 30)
  label.adjustsFontForContentSizeCategory = true
  label.adjustsFontSizeToFitWidth = true
  label.textAlignment = .center
  label.textColor = textColor
  label.backgroundColor = .clear
  return label.confined(centeredYIn: self,
                        applying: .init(top: 0, left: 20, bottom: 0, right: 20),
                        withRelativeSize: relativeArrowsSize * 0.7)
 }()
 
 private var sizeKVOTokens = Set<NSKeyValueObservation>()
 
 private lazy var rightArrow = {
  let arrow = RunningArrowView(arrowColor         : arrowColor,
                               relativeArrowWidth : relativeArrowWidth,
                               relativeArrowPhase : relativeArrowPhase,
                               arrowSharpness     : arrowSharpness)
  
  arrow.transform = arrow.transform.rotated(by: .pi / 2)
  return arrow.confined(toCenterRightOf   : self,
                        with              : relativeArrowsSize,
                        changeFrameTokens : &self.sizeKVOTokens)
 }()
 
 private lazy var leftArrow = {
  let arrow = RunningArrowView(arrowColor         : arrowColor,
                               relativeArrowWidth : relativeArrowWidth,
                               relativeArrowPhase : relativeArrowPhase,
                               arrowSharpness     : arrowSharpness)
  
  arrow.transform = arrow.transform.rotated(by: -.pi / 2)
  return arrow.confined(toCenterLeftOf    : self,
                        with              : relativeArrowsSize,
                        changeFrameTokens : &self.sizeKVOTokens)
 }()
 
 var textColor           : UIColor
 var arrowColor          : UIColor
 var relativeArrowWidth  : CGFloat
 var relativeArrowPhase  : CGFloat
 var arrowSharpness      : CGFloat
 var relativeArrowsSize  : CGFloat
 
 init(textColor           : UIColor = .systemOrange,
      arrowColor          : UIColor = .systemOrange,
      relativeArrowWidth  : CGFloat = 1/25,
      relativeArrowPhase  : CGFloat = 1/50,
      arrowSharpness      : CGFloat = .pi / 1.4,
      relativeArrowsSize  : CGFloat = 0.3) {
  
  self.textColor = textColor
  self.arrowColor = arrowColor
  self.relativeArrowWidth = relativeArrowWidth
  self.relativeArrowPhase = relativeArrowPhase
  self.arrowSharpness = arrowSharpness
  self.relativeArrowsSize = relativeArrowsSize
  
  super.init(frame: .zero)
  
  self.backgroundColor = .clear
 }
 
 required init?(coder: NSCoder) {
  fatalError("init(coder:) has not been implemented")
 }
 
 
 private var depthSeconds: Int = 0
 
 
 func setStartPosition(_ seconds: Int) {
  isHidden = true
  depthSeconds = seconds
  depthLabel.text = seconds < 0 ? "\(seconds) сек." : nil
 }
 
 override func layoutSubviews() {
//  print(#function, String(describing: Self.self), bounds)
  super.layoutSubviews()
  let _ = leftArrow
  let _ = rightArrow
  
 }
 
 func setTime(_ seconds: Int) {
  
  isHidden = false
  
  depthLabel.text = "[ \(seconds) сек. ]"
  
  if seconds < depthSeconds { leftArrow.startAnimating() }
  
  if seconds > depthSeconds { rightArrow.startAnimating() }
  
  depthSeconds = seconds
 }
}
