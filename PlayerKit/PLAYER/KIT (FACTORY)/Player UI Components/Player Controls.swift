//
//  Player Controls.swift
//  AreaSightDemo
//
//  Created by Anton V. Kalinin on 03.12.2022.
//  Copyright © 2022 Netris. All rights reserved.
//

import Foundation
import UIKit

public enum NTXPlayerActions: String, Hashable, CaseIterable {
 
 case play               = "play.circle.fill"
 case pause              = "pause.circle.fill"
 case toggleMuting       = "speaker.slash.circle.fill"
 case playArchiveBack    = "backward.circle.fill"
 case playArchiveForward = "forward.circle.fill"
 case snapshot           = "photo.circle.fill"
 case stop               = "xmark.circle.fill"
 case refresh            = "arrow.clockwise.circle.fill"
 case record             = "recordingtape.circle.fill"
 case showVR             = "rotate.3d"
 
 var imageName: String { rawValue }
}

internal enum NTXPlayerControlGroup: Int {
 
 case topLeading         = 1030 //  __
                                // |\
 case topCentered        = 1200 //  ___
                                //   |
 case topTrailing        = 1330 //  __
                                //   /|
 case trailingCentered   = 1500 //  -|
 
 case bottomTrailing     = 1630 // _\|
 
 case bottomCentered     = 1800 // _|_
 
 case bottomLeading      = 1930 //  |/_
 
 case leadingCentered    = 2100 //  |-
 
 var tag: Int { rawValue }
 
 var orientation: NSLayoutConstraint.Axis {
  switch self {
   case .topLeading:       return .horizontal
   case .topCentered:      return .horizontal
   case .topTrailing:      return .horizontal
   case .trailingCentered: return .vertical
   case .bottomTrailing:   return .horizontal
   case .bottomCentered:   return .horizontal
   case .bottomLeading:    return .horizontal
   case .leadingCentered:  return .vertical
  }
 }
 
}

internal protocol NTXPlayerControl where Self: UIView {
 
 associatedtype Player: NTXMobileNativePlayerProtocol
 
 typealias ActionHandlerType = (Player) -> ()
 var player:                 Player { get }
 var playerAction:           NTXPlayerActions { get }
 var group:                  NTXPlayerControlGroup { get }
 var spacing:                CGFloat { get }
 var actionHandler:          ActionHandlerType { get }
 
 var debounceInterval: TimeInterval { get set }
 
 init(frame: CGRect,
      action: NTXPlayerActions,
      group: NTXPlayerControlGroup,
      player: Player,
      spacing: CGFloat,
      actionHandler:  @escaping ActionHandlerType)
 
}

final internal class NTXDefaultPlayerButton<Player: NTXMobileNativePlayerProtocol> : UIButton,
                                                                                     NTXPlayerControl {
 var debounceInterval: TimeInterval = 0.0
 
 unowned internal let player: Player
 
 internal let playerAction: NTXPlayerActions
 
 internal let group: NTXPlayerControlGroup
 
 internal let spacing: CGFloat
 
 internal let  actionHandler: (Player) -> ()
 
 
 @available(iOS 13.0, *)
 private func setSFSImages() {
  let img = UIImage(systemName: playerAction.imageName)?
   .applyingSymbolConfiguration(.init(pointSize: 45))?
   .withTintColor(.systemOrange)
  
  print ("Contol for Action [\(playerAction)] uses SFS image \(img.debugDescription)")
  self.setImage(img, for: .normal)
 }
 
 private func setAssetImages() {
  let img = UIImage(named: playerAction.imageName,
                    in: .init(for: Self.self),
                    compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
  
  print ("Contol for Action [\(playerAction)] uses custom image \(img.debugDescription)")
 
  self.tintColor = .systemOrange
 
  self.setImage(img, for: .normal)
  
 }
 
 internal init(frame: CGRect = .zero,
               action: NTXPlayerActions,
               group: NTXPlayerControlGroup = .bottomCentered,
               player: Player,
               spacing: CGFloat = 3.0,
               actionHandler: @escaping ActionHandlerType) {
  
  self.player = player
  self.playerAction = action
  self.group = group
  self.actionHandler = actionHandler
  self.spacing = spacing
  
  super.init(frame: frame)
  if #available(iOS 13.0, *) { setSFSImages() } else { setAssetImages() }
  
  addTarget(self, action: #selector(pressed),  for: .touchDown)
  addTarget(self, action: #selector(released), for: .touchUpInside)
  addTarget(self, action: #selector(released), for: .touchCancel)
  
  self.tintColor = .white
 }
 
 private var timer: Timer?
 
 func withDebounce(_ interval: TimeInterval) -> Self {
  self.debounceInterval = interval
  return self
 }
 
 @objc func released() {
  timer?.invalidate()
  timer = nil
 }
 
 @objc func pressed() {
  
  guard debounceInterval > 0.0  else {
   actionHandler(player)
   return
  }
  
  
  timer = Timer.scheduledTimer(withTimeInterval: debounceInterval, repeats: true) { [ weak self ] timer in
   guard let self = self else {
    timer.invalidate()
    return
   }
   
   self.actionHandler(self.player)
  }
  
  
 }
 
 required init?(coder: NSCoder) {
  fatalError("init(coder:) has not been implemented")
 }
 
 
 
}


internal extension NTXPlayerControl {
 
 func controlGroupStack(type: NTXPlayerControlGroup, of container: UIView ) -> UIStackView {
  
  if let stackView = container.subviews.compactMap({$0 as? UIStackView}).first(where: {$0.tag == type.tag }) { return stackView
  }
  
  let stackView = UIStackView()
  stackView.translatesAutoresizingMaskIntoConstraints = false
  container.addSubview(stackView)
  stackView.tag = type.tag
  stackView.axis = type.orientation
  stackView.distribution = .equalCentering
  stackView.alignment = .center
  stackView.spacing = spacing
  return stackView
 }
 
 
 
 
 func confined(groupType: NTXPlayerControlGroup,
               of container: UIView,
               realtiveSize fraction: CGFloat) -> Self {
  
  let stackView = controlGroupStack(type: groupType, of: container)
  
  stackView.addArrangedSubview(self)
  
  var tps: NSLayoutConstraint?
  var lds: NSLayoutConstraint?
  
  switch groupType {
   case .topLeading:
    tps = container.topAnchor.constraint(equalTo: stackView.topAnchor, constant: -20)
    lds = container.leadingAnchor.constraint(equalTo: stackView.leadingAnchor, constant: -10)
    
   case .topCentered:
    tps = container.topAnchor.constraint(equalTo: stackView.topAnchor, constant: -20)
    lds = container.centerXAnchor.constraint(equalTo: stackView.centerXAnchor, constant: 0)
    
   case .topTrailing:
    tps = container.topAnchor.constraint(equalTo: stackView.topAnchor, constant: -20)
    lds = container.trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: 0)
    
   case .trailingCentered:
    tps = container.centerYAnchor.constraint(equalTo: stackView.centerYAnchor, constant: 0)
    lds = container.trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: 10)
    
   case .bottomTrailing:
    tps = container.bottomAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 20)
    lds = container.trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: 10)
    
   case .bottomCentered:
    tps = container.bottomAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 20)
    lds = container.centerXAnchor.constraint(equalTo: stackView.centerXAnchor, constant: 0)
    
   case .bottomLeading:
    tps = container.bottomAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 20)
    lds = container.leadingAnchor.constraint(equalTo: stackView.leadingAnchor, constant: -10)
    
   case .leadingCentered:
    tps = container.centerYAnchor.constraint(equalTo: stackView.centerYAnchor, constant: 0)
    lds = container.leadingAnchor.constraint(equalTo: stackView.leadingAnchor, constant: -10)
  }
  
  
  let rw = widthAnchor.constraint(equalTo: container.widthAnchor,  multiplier: fraction)
  let ch = heightAnchor.constraint(equalTo: container.heightAnchor,  multiplier: fraction)
  let ar = heightAnchor.constraint(equalTo: widthAnchor, multiplier: 1)
  
  let regular = [lds!, tps!, rw, ar]
  let compact = [lds!, tps!, ch, ar]
  
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
  
  player.notificationsTokens.append(token)
  
  return self
 }
 
}
