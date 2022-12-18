//
//  SmallNotificationBar.swift
//  AreaSightDemo
//
//  Created by Ruslan Utashev on 20/09/2019.
//  Copyright © 2019 Netris. All rights reserved.
//

import UIKit

class SmallNotificationBar: UIViewController {
    
 let failureColor = UIColor(named: "#fd3f31")
 let restoredColor = UIColor(named: "#a0b442")
 let fontColor = UIColor(named: "#ffffff")
 
    let fontSize = 10
    let height = 16
    let animationDuration: TimeInterval = 0.5
    let hideDelay: TimeInterval = 1.5
    let connectionManager = EchdConnectionManager.sharedInstance
    let warningView: UIView
    var width: Int
    var label: UILabel?
    var isOpened = false
    var closedPosition: CGPoint
    var openedPosition: CGPoint
    
    override func viewDidLayoutSubviews() {
        DispatchQueue.main.async { [self] in
            self.connectionManager.currentPresentingNotificationBar = self
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        connectionManager.currentPresentingNotificationBar = self
        switch connectionManager.getConnectionStatus() {
        case .interrupted, .stopped, .none, .error(error: _):
            open()
        default:
            close()
            break
        }
    }
    
    required init(superview: UIView, parentView: UIView, setBarToTop: Bool = true) {
        width = Int(parentView.frame.width)
        let y = setBarToTop ?  Int(parentView.frame.origin.y) :  Int( parentView.frame.origin.y + parentView.frame.height)
        let rect = CGRect(x: 0, y: y, width: width, height: height)
        closedPosition = rect.origin
        openedPosition = CGPoint(x:0, y: Int(rect.origin.y) - height)
        warningView = UIView(frame: rect)
        
        super.init(nibName: nil, bundle: nil)
                
        view = UIView(frame: CGRect(x: 0, y: y, width: width, height: 0))
        
        // To prevent appearance of a red line during rotation (see #48845).
        view.isHidden = true
        
        warningView.clipsToBounds = true
        view.clipsToBounds = true
        view.addSubview(warningView)
        
        view.backgroundColor = UIColor.white
        warningView.frame.origin.y = 0
     
        let constraint = NSLayoutConstraint(item: view as Any,
                                            attribute: .top,
                                            relatedBy: .equal,
                                            toItem: warningView,
                                            attribute: .top,
                                            multiplier: 1,
                                            constant: 0)
        constraint.isActive = true
        
        setText()
        
        warningView.backgroundColor = failureColor
        
        superview.addSubview(view)
        if parentView != superview {
            superview.bringSubviewToFront(parentView)
        }
    }
    
    private func connectionLost() {
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            self.isOpened = true
            UIView.animate(withDuration: self.animationDuration, delay: 0, animations: {
                self.view.frame.size.height = CGFloat(self.height)
                self.view.frame.origin = self.openedPosition
            }, completion: nil)
        }
    }
    
    private func connectionRestored(completion: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            self.isOpened = false
            UIView.animate(withDuration: self.animationDuration, delay: 0, animations: {
                self.warningView.backgroundColor = self.restoredColor
                self.label?.text = LabelsTexts.connectionRestored.localized

            }, completion: nil)
            
            UIView.animate(withDuration: self.animationDuration, delay: self.hideDelay, animations: {
                self.view.frame.size.height = 0
                self.view.frame.origin = self.closedPosition
                
            }, completion: { _ in
                self.warningView.backgroundColor = self.failureColor

                self.label?.text = LabelsTexts.connectionLost.localized
                
                completion()
            })
        }
    }
    
    private func open() {
        DispatchQueue.main.async { [self] in
            self.isOpened = true
            self.view.isHidden = false
            self.view.frame.origin = self.openedPosition
        }
    }
        
    private func close() {
        DispatchQueue.main.async { [self] in
            self.isOpened = false
            self.view.isHidden = true
            self.view.frame.origin = self.closedPosition
        }
    }
    
    func setText() {
        label = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: height))
        label?.text = LabelsTexts.connectionLost.localized
        label?.textColor = fontColor
        label?.font = label!.font.withSize(CGFloat(fontSize))
        label?.textAlignment = .center
        warningView.addSubview(label!)
    }
    
    func showWarning() {
        DispatchQueue.main.async { [self] in
            if self.isOpened { return }
            self.view.isHidden = false
            self.connectionLost()
        }
    }
    
    func hideWarning() {
        DispatchQueue.main.async { [self] in
            if !self.isOpened { return }
            
            self.connectionRestored() {
                self.view.isHidden = true
            }
        }
    }
    
    func destroy() {
        view.removeFromSuperview()
        warningView.removeFromSuperview()
        
    }
        
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
