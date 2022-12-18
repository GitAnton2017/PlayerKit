//
//  EchdKeepAliveRequest.swift
//  NetrisSVSM
//
//  Created by netris on 28.04.16.
//  Copyright © 2016 netris. All rights reserved.
//

import Alamofire

class EchdKeepAliveRequest: AbstractRequest {
    
    var dataRequest: DataRequest?
    
    private var payload: Payload
    private var sessionInstanceId: Int = 0
    
    init(payload: Payload, sessionInstanceId: Int) {
        self.payload = payload
        self.sessionInstanceId = sessionInstanceId
    }
    
    func request(parameters: [String : Any] = [:],
                 fail: @escaping (Error) -> Void,
                 success: @escaping (Int?, [String : Any?]) -> Void) {
        
        let queue = DispatchQueue(label: "com.netris.response-echdKeepAliveRequest-queue", qos: .userInitiated, attributes: [.concurrent])
        
        let url = URL(string: getHost() + "/beat")!
        
        let parametersPayload: [String: Any] = [
            "id": Array(payload.id),
            "instance": self.sessionInstanceId,
            "active": payload.active,
            "players": payload.getPlayersParams()
        ]
        
        dataRequest = EchdConnectionManager.sharedInstance.alamofireManager
            .request(url,
                     method: .post,
                     parameters: parametersPayload,
                     encoding: JSONEncoding.default,
                     headers: getHeaders())
            .responseJSON(queue: queue) { [weak self] response in
                if let allHeaders = response.response?.allHeaderFields {
                  self?.processHeaders(allHeaders)
                }
                
                switch response.result {
                case .success:
                    let code = response.response?.statusCode
                    
                    if code == 401 {
                      debugPrint("EchdKeepAliveRequest::request:success: \(String(describing: response.response))")

                     fail(NSError(domain: "EchdKeepAliveRequest::request",
                                  code: 401, userInfo: [NSLocalizedDescriptionKey: response.value]))
                        
                        return
                    }
                                        
                    if let result = try? response.result.get() as? [String: Any] {
                        success(code, result)
                    }
                case .failure(let error as NSError):                    
                    if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
                        debugPrint("EchdKeepAliveRequest::request:failure:(1): \(utf8Text)")
                    }

                    debugPrint("EchdKeepAliveRequest::request:failure:(2): \(error.localizedDescription)")
                    
                    if error.code != 1001 {
                        fail(error)
                    }
                }
        }
    }
    
    private func processHeaders(_ allHeaders: [AnyHashable: Any]) {
        if let headers = allHeaders as? [String: Any],
            let setCookie = headers["Set-Cookie"] as? String,
            let jSessionIdKeyRange = setCookie.range(of: "JSESSIONID=") {

            let stringWithjSessionIdValue = setCookie[jSessionIdKeyRange.upperBound...]

            if let indexOfSemicolon = stringWithjSessionIdValue.firstIndex(of: ";") {
                let jSessionIdValue = String(stringWithjSessionIdValue[..<indexOfSemicolon])
                EchdConnectionManager.sharedInstance.setSessionId(jSessionIdValue)
            }
        }
    }

}
