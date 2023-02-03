//
//  Request Representable Combine.swift
//  PlayerKit
//
//  Created by Anton2016 on 10.01.2023.
//

import Combine

@available(iOS 13.0, *)
extension URLSessionRequestRepresentable {
 
 typealias JSONPublisher = Publisher<Any>
 
 func requestJSONPublisher<Parameters: Encodable> (endPoint: String = "",
                                                   urlSession: URLSession = .shared,
                                                   queryParameters: [ URLQueryItem ] = [],
                                                   bodyParameters: Parameters? = Optional<String>.none,
                                                   httpMethod: HTTPMethods = .get,
                                                   maxRetries: Int = 10 ) -> JSONPublisher {
  
  requestPublisher(endPoint: endPoint,
                   urlSession: urlSession,
                   queryParameters: queryParameters,
                   bodyParameters: bodyParameters,
                   httpMethod: httpMethod,
                   maxRetries: maxRetries)
  .tryMap{ try JSONSerialization.jsonObject(with: $0) }
  .eraseToAnyPublisher()
  
 }
 
 typealias Publisher<T> = AnyPublisher<T, Error>
 
 func requestDecodablePublisher<RequestResult: Decodable,
                                Parameters   : Encodable>(endPoint: String = "",
                                                          urlSession: URLSession = .shared,
                                                          queryParameters: [ URLQueryItem ] = [],
                                                          bodyParameters: Parameters? = Optional<String>.none,
                                                          httpMethod: HTTPMethods = .get,
                                                          maxRetries: Int = 10) -> Publisher<RequestResult> {
  
  requestPublisher(endPoint: endPoint,
                   urlSession: urlSession,
                   queryParameters: queryParameters,
                   bodyParameters: bodyParameters,
                   httpMethod: httpMethod,
                   maxRetries: maxRetries)
  .decode(type: RequestResult.self, decoder: JSONDecoder())
  .eraseToAnyPublisher()
  
  
 }
 
 typealias DataPublisher = Publisher<Data>
 
 func requestPublisher<Parameters: Encodable>(endPoint: String = "",
                                              urlSession: URLSession = .shared,
                                              queryParameters: [ URLQueryItem ] = [],
                                              bodyParameters: Parameters? = Optional<String>.none,
                                              httpMethod: HTTPMethods = .get,
                                              maxRetries: Int = 10) -> DataPublisher {
  
  
  
  guard let requestUrl = getRequestURL(endPoint: endPoint, queryParameters: queryParameters) else {
   return Fail<Data, Error>(error: HTTPRequestError.invalidRequestURL).eraseToAnyPublisher()
  }
  
//  debugPrint(#function, requestUrl.absoluteString)
  
  var request = URLRequest(url: requestUrl)
  request.httpMethod = httpMethod.rawValue
  request.allHTTPHeaderFields = requestHeaders
  
  if let bodyParameters = bodyParameters {
   request.httpBody = try? JSONEncoder().encode(bodyParameters)
  }
  
  
  return urlSession
   .dataTaskPublisher(for: request)
   .tryMap{ (data, response) -> Data in
    
    guard let httpResponse = response as? HTTPURLResponse else {
     throw HTTPRequestError.badServerResponse
    }
    
    guard (200...299).contains(httpResponse.statusCode) else {
     throw HTTPRequestError.requestError(statusCode: httpResponse.statusCode)
    }
     
    return data
    
   }.retry(maxRetries)
    .eraseToAnyPublisher()
  

 }
 
 
}
