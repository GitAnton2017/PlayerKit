//
//  EchdServerTimeService.swift
//  NetrisSVSM
//
//  Created by netris on 18.05.16.
//  Copyright © 2016 netris. All rights reserved.
//

import UIKit


enum EchdServerTimeServiceStatus{
    case none
    case running
    case stopped(error: NSError?) //если error = nil то остановлено пользователем
}

protocol EchdServerTimeServiceDelegate : AnyObject{
    func echdServerTimeService(_ sender: EchdServerTimeService, time:Int)
    func echdServerTimeService(_ sender: EchdServerTimeService, status:EchdServerTimeServiceStatus)
}

class EchdServerTimeService: NSObject {
    
    var status:EchdServerTimeServiceStatus = .none
    
    var host:String?
    
    let interval = 30.0
    
    weak var delegate : EchdServerTimeServiceDelegate?
    var serverTimeRequest: EchdServerTimeRequest?
    private var repeatingTimer: RepeatingTimer?
    
    lazy var serialQueue: DispatchQueue = {
        let queue = DispatchQueue(label: "com.netris.areasight.EchdServerTimeService", qos: DispatchQoS.default)
        return queue
    }()
    
    var isRun:Bool = false
    
    init(host: String, delegate:EchdServerTimeServiceDelegate) {
        self.host = host
        self.delegate = delegate
    }
    
    func start() {
        serialQueue.async {
            // Stop and deinit RepeatingTimer
            self.repeatingTimer?.cancel()
            self.repeatingTimer = nil
            self.isRun = true
            self.run()
            self.status = .running
            self.delegate?.echdServerTimeService(self, status: self.status)
        }
    }
    
    func stop() {
        serialQueue.async {
            // Stop and deinit RepeatingTimer
            self.repeatingTimer?.cancel()
            self.repeatingTimer = nil
            self.isRun = false
            self.serverTimeRequest?.cancel()
            self.status = .stopped(error: nil)
            self.delegate?.echdServerTimeService(self, status: self.status)
        }
    }

    func run() {
        // First keep alive request we send manually
        keepAlive()
        
        // Instantiate the repeating timer:
        repeatingTimer = RepeatingTimer(timeInterval: TimeInterval(self.interval))
        
        // Set an action to the repeating timer:
        repeatingTimer?.eventHandler = { [weak self] in
            self?.keepAlive()
        }
        
        // Activate the repeating timer:
        repeatingTimer?.resume()
    }
    
    func keepAlive() {
        serialQueue.async { [weak self] in
            guard let self = self else { return }
            
            if !self.isRun {
                return
            }

            self.serverTimeRequest = nil
            self.serverTimeRequest = EchdServerTimeRequest()
            self.serverTimeRequest?.request(fail: { error in
                self.isRun = false
                self.status = .stopped(error: error as NSError)
                DispatchQueue.main.async {
                    self.delegate?.echdServerTimeService(self, status: self.status)
                }
            }, success: { (code, response) in
                if let time = response["time"] as? String {
                    var serverTime: Int?
                    do {
                        if time.lengthOfBytes(using: String.Encoding.utf8) > 0 {
                            let regex = try NSRegularExpression(pattern: "\\[\\'time\\':(.*)\\]",
                                                                options: .caseInsensitive)
                            
                            // @FIXME: - this line causes a crash:
                            let string = time as NSString
                            let matches = regex.matches(in: time,
                                                        options: [],
                                                        range: NSRange(location: 0,
                                                                       length: string.length))
                            
                            if let match = matches.first {
                                let range = match.range(at: 1)
                                let name = (time as NSString).substring(with: range)
                                serverTime = Int(name)
                            }
                        }
                        
                    } catch {
                        debugPrint("EchdServerTimeService::keepAlive: \(error)")
                    }
                    
                    if let serverTime = serverTime {
                        self.delegate?.echdServerTimeService(self, time: serverTime)
                    }
                }
            })
        }
    }
}
