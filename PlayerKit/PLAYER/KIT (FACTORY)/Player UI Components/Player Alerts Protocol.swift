//
//  Player Alerts.swift
//  AreaSight
//
//  Created by Anton V. Kalinin on 10.12.2022.
//  Copyright © 2022 Netris. All rights reserved.
//

import Foundation
import UIKit

internal protocol NTXPlayerAlertRepresentable where Self: UIView {
 var alert:    NTXPlayerAlert? { get set }
 static var empty: Self { get }
}

internal struct NTXPlayerAlert  {
 
 internal static let empty = Self(message: "", image: nil, color: .clear, textColor: .clear)
 
 internal let message: String
 internal let image: UIImage?
 internal let color: UIColor
 internal let textColor: UIColor
 
 internal static func info(message: String) -> Self {
  .init(message: message, image: nil, color: .systemGreen, textColor: .white)
 }
 
 internal static func warning(message: String) -> Self {
  .init(message: message, image: nil, color: .systemYellow, textColor: .white)
 }
 
 internal static func error(message: String) -> Self {
  .init(message: message, image: nil, color: .systemRed, textColor: .white)
 }
}


 //IMPL

internal final class NTXPlayerDefaultAlertView:  UIView, NTXPlayerAlertRepresentable {
 internal static var empty: Self { .init()}
 
 internal var alert: NTXPlayerAlert?
 {
  didSet {
   alertLabel.text = alert?.message
   //alertImageView.image = alert?.image
   alertLabel.textColor = alert?.textColor
   backgroundColor = alert?.color
   
  }
 }
 
 
 
 private lazy var alertLabel: UILabel = {
  let label = UILabel(frame: .zero)
  label.translatesAutoresizingMaskIntoConstraints = false
  addSubview(label)
  label.numberOfLines = 0
  label.textAlignment = .center
  label.minimumScaleFactor = 0.05
  label.font = .systemFont(ofSize: 15)
  label.adjustsFontForContentSizeCategory = true
  label.adjustsFontSizeToFitWidth = true
  
  return label
 }()
 
// private lazy var alertImageView: UIImageView = {
//  let iv = UIImageView(frame: .zero)
//  iv.translatesAutoresizingMaskIntoConstraints = false
//  addSubview(iv)
//
//  return iv
// }()
 
 private func configureConstraints() {
  let cy1 = centerYAnchor.constraint(equalTo: alertLabel.centerYAnchor)
  //let cy2 = centerYAnchor.constraint(equalTo: alertImageView.centerYAnchor)
  let tt = trailingAnchor.constraint(equalTo: alertLabel.trailingAnchor, constant: 10)
  //let tl = alertImageView.trailingAnchor.constraint(equalTo: alertLabel.leadingAnchor, constant: -10)
  let ll = leadingAnchor.constraint(equalTo: alertLabel.leadingAnchor, constant: -10)
//  alertImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
//  alertImageView.setContentHuggingPriority(.required, for: .horizontal)
  let ah = alertLabel.heightAnchor.constraint(lessThanOrEqualTo: heightAnchor, multiplier: 0.9)
  NSLayoutConstraint.activate([cy1, /*cy2,*/ tt, /*tl,*/ ll, ah])
  
 }
 override init(frame: CGRect = .zero) {
  super.init(frame: frame)
  configureConstraints()
 }
 
 required init?(coder: NSCoder) {
  fatalError("init(coder:) has not been implemented")
 }
}



