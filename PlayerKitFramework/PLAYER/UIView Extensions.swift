//
//  UIView Extensions.swift
//  AreaSightDemo
//
//  Created by Anton V. Kalinin on 02.12.2022.
//  Copyright © 2022 Netris. All rights reserved.
//

import UIKit

extension UIView {
 
 func confined(centeredIn container: UIView) -> Self {
  
  translatesAutoresizingMaskIntoConstraints = false
  
  container.addSubview(self)
  
  container.centerXAnchor.constraint(equalTo:  centerXAnchor).isActive = true
  container.centerYAnchor.constraint(equalTo:  centerYAnchor).isActive = true
  
  return self
 }
 
 
 func confined(to container: UIView,
               applying insets: UIEdgeInsets = .zero ) -> Self {
  
  translatesAutoresizingMaskIntoConstraints = false
  
  container.addSubview(self)
  
  container.topAnchor     .constraint(equalTo:  topAnchor,      constant: -insets.top   ).isActive = true
  container.bottomAnchor  .constraint(equalTo:  bottomAnchor,   constant:  insets.bottom).isActive = true
  container.leadingAnchor .constraint(equalTo:  leadingAnchor,  constant:  -insets.left  ).isActive = true
  container.trailingAnchor.constraint(equalTo:  trailingAnchor, constant: insets.right ).isActive = true
  
  return self
 }
 
 func confined(centeredIn container: UIView,
               withAdaptiveRelativeSize fraction: CGFloat,
               changeFrameTokens: inout Set<NSKeyValueObservation>) -> Self {
  
  translatesAutoresizingMaskIntoConstraints = false
  
  container.addSubview(self)
  
  let cx = container.centerXAnchor.constraint(equalTo:  centerXAnchor)
  let cy = container.centerYAnchor.constraint(equalTo:  centerYAnchor)
  let rw = widthAnchor .constraint(equalTo: container.widthAnchor,   multiplier: fraction)
  let ch = heightAnchor.constraint(equalTo: container.heightAnchor,  multiplier: fraction)
  let ar = heightAnchor.constraint(equalTo: widthAnchor, multiplier: 1)
  
  let regular = [cx, cy, rw, ar]
  let compact = [cx, cy, ch, ar]
  
  let all = regular + compact
 
  NSLayoutConstraint.activate(regular)
  
  
  let token = container.observe(\.frame, options: [.new] ) { _ , change  in
   
   NSLayoutConstraint.deactivate(all)

   guard let frame = change.newValue else { return }
   
   if frame.width < frame.height {
    NSLayoutConstraint.activate(regular)
   } else {
    NSLayoutConstraint.activate(compact)
   }
  }
  
  changeFrameTokens.insert(token)
  
  return self
 }
 

 func confined(toTopRightOf container: UIView,
               with relativeSize: CGFloat,
               shift: CGPoint = .zero,
               changeFrameTokens: inout Set<NSKeyValueObservation>) -> Self {
  
  translatesAutoresizingMaskIntoConstraints = false

  container.addSubview(self)
  
  let trls = container.trailingAnchor.constraint(equalTo:  trailingAnchor, constant: shift.x)
  let tops = container.topAnchor     .constraint(equalTo:  topAnchor,      constant: shift.y)
  let rw = widthAnchor.constraint(equalTo: container.widthAnchor,  multiplier: relativeSize)
  let ch = heightAnchor.constraint(equalTo: container.heightAnchor,  multiplier: relativeSize)
  let ar = heightAnchor.constraint(equalTo: widthAnchor, multiplier: 1)
  
  let regular = [trls, tops, rw, ar]
  let compact = [trls, tops, ch, ar]
  
  let all = regular + compact
  
  NSLayoutConstraint.activate(regular)
  
  let token = container.observe(\.frame, options: [.new]) { _ , change  in
   
   NSLayoutConstraint.deactivate(all)
   
   guard let frame = change.newValue else { return }
   
   if frame.width < frame.height {
    NSLayoutConstraint.activate(regular)
   } else {
    NSLayoutConstraint.activate(compact)
   }
  }
  
  changeFrameTokens.insert(token)
  
  return self
 }
 
 func confined(toTopLeftOf container: UIView,
               withAdaptiveRelativeSize fraction: CGFloat,
               shift: CGPoint = .zero,
               changeFrameTokens: inout Set<NSKeyValueObservation>) -> Self {
  
  translatesAutoresizingMaskIntoConstraints = false
  
  container.addSubview(self)
  
  let leds = container.leadingAnchor.constraint(equalTo:  leadingAnchor, constant: shift.x)
  let tops = container.topAnchor     .constraint(equalTo:  topAnchor,      constant: shift.y)
  
  let rw = widthAnchor.constraint(equalTo: container.widthAnchor,  multiplier: fraction)
  let ch = heightAnchor.constraint(equalTo: container.heightAnchor,  multiplier: fraction)
  let ar = heightAnchor.constraint(equalTo: widthAnchor, multiplier: 1)
  
  let regular = [leds, tops, rw, ar]
  let compact = [leds, tops, ch, ar]
  
  let all = regular + compact
  
  NSLayoutConstraint.activate(regular)
  
  let token = container.observe(\.frame, options: [.new]) { _ , change  in
   
   NSLayoutConstraint.deactivate(all)
   
   guard let frame = change.newValue else { return }
   
   if frame.width < frame.height {
    NSLayoutConstraint.activate(regular)
   } else {
    NSLayoutConstraint.activate(compact)
   }
  }
  
  changeFrameTokens.insert(token)
  
  return self
 }
 
 
 func confined(toTopCenterOf container: UIView,
               withAdaptiveRelativeHeight fraction: CGFloat,
               shift: CGPoint = .zero,
               changeFrameTokens: inout Set<NSKeyValueObservation>) -> Self {
  
  translatesAutoresizingMaskIntoConstraints = false
  
  container.addSubview(self)
  
  let cx = container.centerXAnchor.constraint(equalTo:  centerXAnchor, constant: shift.x)
  let tops = container.topAnchor.constraint(equalTo:  topAnchor,      constant: shift.y)
  let w = widthAnchor.constraint(equalTo: container.widthAnchor,  multiplier: 1)
  let rh = heightAnchor.constraint(equalTo: container.heightAnchor,  multiplier: fraction)
  let ch = heightAnchor.constraint(equalTo: container.widthAnchor,  multiplier: fraction)
  
  
  let regular = [cx, tops, w, rh]
  let compact = [cx, tops, w, ch]
  
  let all = regular + compact
  
  NSLayoutConstraint.activate(regular)
  
  let token = container.observe(\.frame, options: [.new]) { _ , change  in
   
   NSLayoutConstraint.deactivate(all)
   
   guard let frame = change.newValue else { return }
   
   if frame.width < frame.height {
    NSLayoutConstraint.activate(regular)
   } else {
    NSLayoutConstraint.activate(compact)
   }
  }
  
  changeFrameTokens.insert(token)
  
  return self
 }
 
 
 func confined(hiddenOnTopCenterOf container: UIView,
               withAdaptiveRelativeHeight fraction: CGFloat,
               changeFrameTokens: inout Set<NSKeyValueObservation>) -> Self {
  
  confined(toTopCenterOf: container,
           withAdaptiveRelativeHeight: fraction,
           shift: .init(x: 0.0, y: container.bounds.height * fraction),
           changeFrameTokens: &changeFrameTokens)
 }
 
 

 
 
 
}
