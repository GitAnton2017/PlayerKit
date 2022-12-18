//
//  LoginViewControllerDelegate.swift
//  AreaSight
//
//  Created by Shamil on 03.02.2021.
//  Copyright © 2021 Netris. All rights reserved.
//

import Foundation

protocol LoginViewControllerDelegate: AnyObject {
    
    func loginSentAction(_ action: LoginViewControllerActions, parameters: [String: Any]?)
}
