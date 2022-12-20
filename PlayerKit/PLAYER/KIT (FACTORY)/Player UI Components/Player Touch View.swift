//
//  Player Touch View.swift
//  PlayerKit
//
//  Created by Anton2016 on 20.12.2022.
//

import UIKit

final internal class PlayerTouchView: UIView {
 
 var handler: ( () -> () )?
 
 @objc func tapped(){ handler?() }
 
 override init(frame: CGRect) {
  super.init(frame: frame)
  self.backgroundColor = .clear
  let tapGR = UITapGestureRecognizer(target: self, action: #selector(tapped))
  self.addGestureRecognizer(tapGR)
 }
 
 required init?(coder: NSCoder) {
  super.init(coder: coder)
 }
 
}
