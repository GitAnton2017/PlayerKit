


final class ECHDArchiveControl: NSObject, NTXVSSArchiveControlContext{

    var data: [ String : AnyObject ]?
    var success = false
 
    internal var depth : Int?
    internal var start : Int?
    internal var end   : Int?
 
    var state : String?
    
    init(data:[String : AnyObject]) {  // array
     
        self.data = data
        
        if (data["success"] as? Bool) != nil {
            if let recording = data["recording"] as? [String : AnyObject] {
                self.depth = recording["depth"]  as? Int
                self.start = recording["start"]  as? Int
                self.end   = recording["end"]    as? Int
                self.state = recording["state"]  as? String
            }
        }
    }
}
