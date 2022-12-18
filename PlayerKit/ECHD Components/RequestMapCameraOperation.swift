//
//  RequestMapCameraOperation.swift
//  AreaSight
//
//  Created by Artem Lytkin on 01/03/2019.
//  Copyright © 2019 Netris. All rights reserved.
//

//import Foundation
//import MapKit
////import YandexMapKit
//

protocol GetCameraListResponseReceiver {
    func getCameraListRequest(_ request: GetCameraListRequest, x:Int?, y:Int?, with response: [String:AnyObject]?, error:Error?)
}
//
//
//class RequestMapCameraOperation: AsyncOperation {
//    
//    private var requests: [GetCameraListRequest]
//    
//    private var accessQueue: DispatchQueue = DispatchQueue(label: "com.netris.requestMapCameraOperation-access-queue", attributes: .concurrent)
//    
//    weak var cameraColorSource: CameraColorSource?
//    
//    var callbackAnnotations: ( ( _ zoom: Int, _ tile: Tile?, _ annotation: YMKPoint) -> Void )?
//    
//    var tile: Tile?
//    var left: Double?
//    var top: Double?
//    var right: Double?
//    var bottom: Double?
//    var zoom: Int
//    
//    private var allAnnotations: [YMKPoint] = []
//    
//    // MARK: - Lificycle
//    
//    init(tile: Tile? = nil,
//         left: Double = 0,
//         top: Double = 0,
//         right: Double = 0,
//         bottom: Double = 0,
//         zoom: Int,
//         colorSource: CameraColorSource?,
//         callbackAnnotations: @escaping ( _ zoom: Int, _ tile: Tile?, _ annotation: YMKPoint) -> Void
//        ) {
//        
//        self.tile = tile
//        self.left = left
//        self.top = top
//        self.right = right
//        self.bottom = bottom
//        self.zoom = zoom
//        self.cameraColorSource = colorSource
//        self.callbackAnnotations = callbackAnnotations
//        self.requests = []
//        super.init()
//    }
//
//    // MARK: - Overridden methods
//    
//    override func main() {
//        
//        guard !isCancelled else
//        {
//            self.cancelAllRequests()
//            return
//        }
//        
//        if let left = left,
//            let top = top,
//            let right = right,
//            let bottom = bottom
//        {
//            makeRequestForCameras(tile: tile, left: left, top: top, right: right, bottom: bottom, zoom: zoom)
//        }
//    }
//    
//    override func cancel() {
//        super.cancel()
//        cancelAllRequests()
//    }
//    
//    // MARK: - Public
//    
//    private func makeRequestForCameras(tile: Tile?, left: Double, top: Double, right: Double, bottom: Double, zoom: Int) {
//        
//        let area = AreaOfGetCameraList(x: tile?.x ?? 0,
//                                       y: tile?.y ?? 0,
//                                       zoom: zoom,
//                                       left: left,
//                                       top: top,
//                                       right: right,
//                                       bottom: bottom)
//        
//        let newRequests = EchdConnectionManager.sharedInstance.requestCameraMapList(area: area,
//                                                                                 responseReceiver: self)
//        appendRequests(newRequests)
//    }
//    
//    // MARK: - Private
//    
//    private func performBlockOnMainQueueWithZoomCondition(operation: RequestMapCameraOperation?, block: @escaping () -> ()) {
//        
//        guard let unwrappedOperation = operation else {
//            return
//        }
//        
//        if unwrappedOperation.isCancelled || unwrappedOperation.isFinished {
//            unwrappedOperation.state = .finished
//            return
//        }
//        
//        DispatchQueue.main.async {
//            if unwrappedOperation.isCancelled || unwrappedOperation.isFinished {
//                unwrappedOperation.state = .finished
//                return
//            }
//            block()
//        }
//    }
//    
//    private func checkOperationCancellation() {
//        if self.isCancelled || self.isFinished {
//            DispatchQueue.main.async {
//                self.state = .finished
//                return
//            }
//        }
//    }
//    
//    private func finish() {
//        DispatchQueue.main.async {
//            self.state = .finished
//            return
//        }
//    }
//    
//    private func makeGroups(_ allGroups: [[String:AnyObject]]) {
//        
//        for group in allGroups {
//            
//            checkOperationCancellation()
//            
//            var groupAnnotation: GroupAnnotation?
//            
//            // Zoom: 9,10
//            if 9...10 ~= zoom {
//                if let latitude = group["lat"] as? Double,
//                    let longitude = group["lng"] as? Double,
//                    let camerasCount = group["count"] as? Int {
//                    
//                    groupAnnotation = GroupAnnotation(latitude: latitude,
//                                                      longitude: longitude,
//                                                      count: camerasCount,
//                                                      zoom: zoom)
//                }
//                
//            // Other zooms:
//            } else if let cellX = group["x"] as? Int,
//                let cellY = group["y"] as? Int,
//                let camerasCount = group["count"] as? Int,
//                let longitude = EchdAgregationSettings.sharedInstance.getCellCenterLongitude(x: cellX, zoom: zoom),
//                let latitude = EchdAgregationSettings.sharedInstance.getCellCenterLatitude(y: cellY, zoom: zoom) {
//                
//                groupAnnotation = GroupAnnotation(latitude: latitude,
//                                                  longitude: longitude,
//                                                  count: camerasCount,
//                                                  zoom: zoom)
//                
//            }
//            
//            checkOperationCancellation()
//            
//            guard let unwrappedGroupAnnotation = groupAnnotation else { return }
//            
//            callbackAnnotations?(zoom, tile, unwrappedGroupAnnotation)
//        }
//    }
//    
//    private func makeClusterAnnotation(from cluster: (key: Cell, value: [EchdSearchCamera])) {
//        
//        let settingsService = EchdAgregationSettings.sharedInstance
//        
//        if let microCellLng = settingsService.getMicroCellCenterLongitude(x: cluster.key.x, zoom: zoom),
//            let microCellLat = settingsService.getMicroCellCenterLatitude(y: cluster.key.y, zoom: zoom) {
//            checkOperationCancellation()
//            
//            let clusterAnnotation = ClusterAnnotation(latitude: microCellLat,
//                                                       longitude: microCellLng,
//                                                       list: cluster.value,
//                                                       zoom: zoom)
//            
//            checkOperationCancellation()
//            
//            callbackAnnotations?(zoom, tile, clusterAnnotation)
//        }
//    }
//    
//    private func makeCameraAnnotation(from camera: EchdSearchCamera) {
//        guard let lat = camera.lat,
//            let lng = camera.lng else { return }
//        
//        checkOperationCancellation()
//        
//        let cameraAnnotation = CameraAnnotation(latitude: lat,
//                                                longitude: lng,
//                                                zoom: zoom)
//        
//        checkOperationCancellation()
//        
//        cameraAnnotation.camera = camera
//        
//        guard let camera = cameraAnnotation.camera,
//            let cameraType = camera.cameraType,
//            let colorString = self.cameraColorSource?.getColor(for: cameraType),
//            let cameraStatus = camera.status,
//            let cameraStatusString = self.cameraColorSource?.getStatusColor(for: cameraStatus) else { return }
//        
//        cameraAnnotation.color = colorString
//        cameraAnnotation.statusColor = cameraStatusString
//        
//        callbackAnnotations?(zoom, tile, cameraAnnotation)
//    }
//    
//    private func makeCells(cameras: [EchdSearchCamera]) -> [Cell: [EchdSearchCamera]]? {
//        
//        let settingsService = EchdAgregationSettings.sharedInstance
//        
//        var cellsWithCameras: [Cell: [EchdSearchCamera]] = [:]
//        
//        for camera in cameras {
//            if let cameraLatitude = camera.lat,
//                let cameraLongitude = camera.lng,
//                let cellX = settingsService.getMicroCellX(fromPointLng: cameraLongitude, zoom: zoom),
//                let cellY = settingsService.getMicroCellY(fromPointLat: cameraLatitude, zoom: zoom) {
//                
//                let cell = Cell(x: cellX, y: cellY)
//                
//                if var camerasOfCell = cellsWithCameras[cell] {
//                    camerasOfCell.append(camera)
//                    cellsWithCameras[cell] = camerasOfCell
//                } else {
//                    cellsWithCameras[cell] = [camera]
//                }
//            }
//        }
//        
//        return cellsWithCameras
//    }
//}
//
//// MARK: - GetCameraListResponseReceiver
//
//extension RequestMapCameraOperation: GetCameraListResponseReceiver {
//
//    func getCameraListRequest(_ request: GetCameraListRequest, x:Int?, y:Int?, with response: [String:AnyObject]?, error:Error?) {
//        guard error == nil else {
//            debugPrint("RequestMapCameraOperation::getCameraListRequest: \(error!)")
//            
//            removeAllRequests()
//            finish()
//            return
//        }
//        
//        defer {
//            state = .finished
//        }
//        
//        // Take groups,cameras from result:
//        guard let allGroups = response?["groups"] as? [[String: AnyObject]] else {
//            debugPrint("RequestMapCameraOperation::getCameraListRequest: Not groups")
//            
//            removeAllRequests()
//            finish()
//            return
//        }
//        guard let allCameraModels = response?["cameras"] as? [[String: AnyObject]] else {
//            debugPrint("RequestMapCameraOperation::getCameraListRequest: Not cameras")
//            
//            removeAllRequests()
//            finish()
//            return
//        }
//        
//        checkOperationCancellation()
//        makeGroups(allGroups)
//        
//        var cameras: [EchdSearchCamera] = []
//        
//        for cameraModel in allCameraModels {
//            let camera = EchdSearchCamera(data: cameraModel as [String: AnyObject])
//            cameras.append(camera)
//        }
//        
//        if zoom <= 18,
//            let cellsWithCameras = self.makeCells(cameras: cameras) {
//            
//            cellsWithCameras.forEach {
//                checkOperationCancellation()
//                
//                if $0.value.count == 1,
//                    let camera = $0.value.first {
//                    
//                    makeCameraAnnotation(from: camera)
//                } else {
//                    makeClusterAnnotation(from: $0)
//                }
//            }
//        
//        } else {
//            // zoom >= 18. To see camera real position without aggregation.
//            // TODO: Make cameras showing without clusters for zoom
//            cameras.forEach {
//                makeCameraAnnotation(from: $0)
//            }
//        }
//
//        //-----------------------------------------------------------------------------------------------------------------------------
//        
//        if allAnnotations.count > 0 {
//            if requests.isEmpty {
//                finish()
//            }
//        }
//        
//        if !requests.isEmpty {
//            removeRequest(request)
//        }
//    }
//}
//
//// Operations with requests array:
//
//extension RequestMapCameraOperation {
//    
//    private func cancelAllRequests() {
//        accessQueue.async(flags: .barrier) {
//            self.requests.forEach {
//                $0.cancel()
//            }
//        }
//    }
//    
//    private func appendRequests(_ requests: [GetCameraListRequest]) {
//        accessQueue.async(flags: .barrier) {
//            self.requests = requests
//        }
//    }
//    
//    private func removeAllRequests() {
//        accessQueue.async(flags: .barrier) {
//            self.requests.forEach {
//                $0.cancel()
//            }
//            self.requests.removeAll()
//        }
//    }
//    
//    private func removeRequest(_ request: GetCameraListRequest) {
//        accessQueue.async(flags: .barrier) {
//            request.cancel()
//            self.requests.removeAll { (getCameraListRequest) -> Bool in
//                return getCameraListRequest === request
//            }
//            
//            if self.requests.isEmpty {
//                self.finish()
//            }
//        }
//    }
//}
