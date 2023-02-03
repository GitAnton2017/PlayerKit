//
//  EchdCamera.swift
//  NetrisSVSM
//
//  Created by netris on 17.05.16.
//  Copyright © 2016 netris. All rights reserved.
//

import UIKit

internal final class ECHDCamera : NSObject, NTXVSSDeviceRequestContext  {
    
    var json: [ String : AnyObject ]?
 
    var key: String?

    internal var archiveEnabled: Bool {
        if let _ = json?["archive"] as? [String : AnyObject] {
            return true
        } else {
            return false
        }
    }
    
    internal init(data:[String : AnyObject]) {
        key = Array(data.keys)[0]
        let d:[String:AnyObject] = data
        let r = Array(d.keys)
        json = d[r[0]] as? [String : AnyObject]
    }

    internal func isSuccess() -> Bool? {
        if let jsonObjects = json {
            let res = jsonObjects["success"]
            if let res = res {
                let success = res as? Bool
                return success
            }
        }
        return false
    }
    
    internal func getVersion() -> Int? {
        if let jsonObjects = json {
            let version = jsonObjects["version"] as? Int
            return version
        }
        return nil;
    }
    
    internal func getPermissions() -> [String]? {
        if let jsonObjects = json {
            let permissions = jsonObjects["permissions"] as? [String]
            return permissions
        }
        
        return nil;
    }

    internal func getArchiveControlUrls() -> [String]? {
        if let jsonObjects = json {
            if let archive = jsonObjects["archive"] as? [String:AnyObject] {
                if let control = archive["control"] as? [String] {
                    return control
                }
            }
        }
        return nil
    }

    internal func getArchiveShotControlUrls() -> [String]? {
        if let jsonObjects = json {
            if let archive = jsonObjects["archive"] as? [String:AnyObject] {
                if let android = archive["shot"] as? [String:AnyObject] {
                    if let urls = android["control"] as? [String] {
                        return urls
                    }
                }
            }
        }
        return nil
    }

    internal func getArchiveAndroidUrls() -> [String]? {
        if let jsonObjects = json {
            if let archive = jsonObjects["archive"] as? [String:AnyObject] {
                if let android = archive["android"] as? [String:AnyObject] {
                    if let urls = android["url"] as? [String] {
                        return urls
                    }
                }
            }
        }
        return nil
    }

    internal func getArchiveIosUrls() -> [String]? {
        if let jsonObjects = json {
            if let archive = jsonObjects["archive"] as? [String:AnyObject] {
                if let ios = archive["ios"] as? [String:AnyObject] {
                    if let urls = ios["url"] as? [String] {
                        return urls
                    }
                }
            }
        }
        return nil
    }

    internal func getArchiveUrls() -> [String]? {
        if let jsonObjects = json {
            if let archive = jsonObjects["archive"] as? [String:AnyObject] {
                if let url = archive["url"] as? [String] {
                        return url
                }
            }
        }
        return nil
    }

    internal func getArchiveShotUrls() -> [String]? {
        if let jsonObjects = json {
            if let archive = jsonObjects["archive"] as? [String:AnyObject] {
                if let shot = archive["shot"] as? [String:AnyObject] {
                    if let urls = shot["url"] as? [String] {
                        return urls
                    }
                }
            }
        }
        return nil
    }

    internal func getLiveAndroidUrls() -> [String]? {
        if let jsonObjects = json {
            if let live = jsonObjects["live"] as? [String:AnyObject] {
                if let shot = live["android"] as? [String:AnyObject] {
                    if let urls = shot["url"] as? [String] {
                        return urls
                    }
                }
            }
        }
        return nil
    }
    
    internal func getLiveIosUrls() -> [String]? {
        if let jsonObjects = json {
            if let live = jsonObjects["live"] as? [String:AnyObject] {
                if let shot = live["ios"] as? [String:AnyObject] {
                    if let urls = shot["url"] as? [String] {
                        return urls
                    }
                }
            }
        }
        return nil
    }
    
    internal func getLiveUrls() -> [String]? {
        if let jsonObjects = json {
            if let live = jsonObjects["live"] as? [String:AnyObject] {
                if let url = live["url"] as? [String] {
                    return url
                }
            }
        }
        return nil

    }
    
    internal func getLiveShotUrls() -> [String]? {
        if let jsonObjects = json {
            if let live = jsonObjects["live"] as? [String:AnyObject] {
                if let shot = live["shot"] as? [String:AnyObject] {
                    if let urls = shot["url"] as? [String] {
                        return urls
                    }
                }
            }
        }
        return nil
    }
    
    internal func getArchiveShotControl() -> [String]? {
        if let jsonObjects = json {
            if let live = jsonObjects["archive"] as? [String:AnyObject] {
                if let shot = live["shot"] as? [String:AnyObject] {
                    if let urls = shot["control"] as? [String] {
                        return urls
                    }
                }
            }
        }
        return nil
    }

}
