//
//  EchdArchiveControl.swift
//  AreaSight
//
//  Created by Александр on 20.10.16.
//  Copyright © 2016 Netris. All rights reserved.
//

import UIKit

internal final class EchdArchiveControl: NSObject {

    var data:[String:AnyObject]?
    var success:Bool = false
 
    internal var depth:Int?
    internal var start:Int?
    internal var end:Int?
 
    var state:String?
    
    internal init(data:[String : AnyObject]){  // array
        self.data = data
        
        if (data["success"] as? Bool) != nil {
            if let recording:[String : AnyObject] = data["recording"] as? [String : AnyObject] {
                self.depth = recording["depth"] as? Int
                self.start = recording["start"] as? Int
                self.end = recording["end"] as? Int
                self.state = recording["state"] as? String
            }
        }
    }
}
