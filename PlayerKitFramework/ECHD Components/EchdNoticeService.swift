//
//  EchdNoticeService.swift
//  NetrisSVSM
//
//  Created by netris on 18.05.16.
//  Copyright © 2016 netris. All rights reserved.
//

import UIKit

enum EchdNoticeServiceStatus{
    case none
    case running
    case stopped(error: NSError?) //если error = nil то остановлено пользователем
}

protocol EchdNoticeServiceDelegate : AnyObject {
    func echdNoticeServiceRequest(_ sender: EchdNoticeService, status:EchdKeepAliveServiceStatus)
    func echdNoticeServiceRequest(_ sender: EchdNoticeService, notice:AnyObject)
}

class EchdNoticeService: NSObject {

    var status: EchdKeepAliveServiceStatus = .none
    weak var delegate : EchdNoticeServiceDelegate?
    var noticeRequest: EchdNoticeListRequest?
    var host: String?
    var isRun: Bool = false
    private var repeatingTimer: RepeatingTimer?
    
    lazy var serialQueue: DispatchQueue = {
        let queue = DispatchQueue(label: "com.netris.areasight.EchdNoticeService", qos: DispatchQoS.default)
        return queue
    }()

    init(host: String, delegate:EchdNoticeServiceDelegate) {
        self.host = host
        self.delegate = delegate
    }

    func start() {
        serialQueue.async {
            self.repeatingTimer?.cancel()
            self.repeatingTimer = nil
            
            self.isRun = true
            self.run()
            self.status = .running
            self.delegate?.echdNoticeServiceRequest(self, status: self.status)
        }
    }

    func stop() {
        serialQueue.async {
            self.repeatingTimer?.cancel()
            self.repeatingTimer = nil
            self.isRun = false
            self.noticeRequest?.cancel()
            self.status = .stopped(error: nil)
            self.delegate?.echdNoticeServiceRequest(self, status: self.status)
        }
    }

    func run() {
        
        guard let noticeInterval = EchdConnectionManager.sharedInstance.noticeInterval else { return }
        
        // First keep alive request we send manually
        keepAlive()
        
        // Instantiate the repeating timer:
        repeatingTimer = RepeatingTimer(timeInterval: noticeInterval)
        
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
            
            self.noticeRequest = EchdNoticeListRequest()
            self.noticeRequest?.request(parameters: [:], fail: { (error) in
                self.isRun = false
                self.status = .stopped(error: (error as NSError))
                self.delegate?.echdNoticeServiceRequest(self, status: self.status)
            }, success: { (code, result) in
                self.delegate?.echdNoticeServiceRequest(self, notice: result as AnyObject)
            })
        }
    }
}
