//
//  Request Representable Result.swift
//  PlayerKit
//
//  Created by Anton2016 on 10.01.2023.
//


extension URLSessionRequestRepresentable {
 
 func requestJSON<Parameters: Encodable> (endPoint: String = "",
                                          urlSession: URLSession = .shared,
                                          queryParameters: [ URLQueryItem ] = [],
                                          bodyParameters: Parameters? = Optional<String>.none,
                                          httpMethod: HTTPMethods = .get,
                                          resultHandler: @escaping (Result<Any, Error>) -> () ) {
  
  request(endPoint: endPoint,
          urlSession: urlSession,
          queryParameters: queryParameters,
          bodyParameters: bodyParameters,
          httpMethod: httpMethod) { result in
   resultHandler(result.flatMap { data in
    Result { try JSONSerialization.jsonObject(with: data) }
   })
  }
  
 }
 
 func requestDecodable<RequestResult: Decodable,
                       Parameters   : Encodable>(endPoint: String = "",
                                                 urlSession: URLSession = .shared,
                                                 queryParameters: [ URLQueryItem ] = [],
                                                 bodyParameters: Parameters? = Optional<String>.none,
                                                 httpMethod: HTTPMethods = .get,
                                                 resultHandler: @escaping (Result<RequestResult, Error>) -> () ) {
  
  request(endPoint: endPoint,
          urlSession: urlSession,
          queryParameters: queryParameters,
          bodyParameters: bodyParameters,
          httpMethod: httpMethod) { result in
   resultHandler(result.flatMap { data in
    Result { try JSONDecoder().decode(RequestResult.self, from: data) }
   })
  }
  
 }
 
 func request<Parameters: Encodable>(endPoint: String = "",
                                     urlSession: URLSession = .shared,
                                     queryParameters: [ URLQueryItem ] = [],
                                     bodyParameters: Parameters? = Optional<String>.none,
                                     httpMethod: HTTPMethods = .get,
                                     maxRetries: Int = 10,
                                     resultHandler: @escaping (Result<Data, Error>) -> () ) {
  
  
  
  guard let requestUrl = getRequestURL(endPoint: endPoint, queryParameters: queryParameters) else {
   resultHandler(.failure(HTTPRequestError.invalidRequestURL))
   return
  }
  
//  debugPrint(#function, requestUrl.absoluteString, maxRetries)
  
  var request = URLRequest(url: requestUrl)
  request.httpMethod = httpMethod.rawValue
  request.allHTTPHeaderFields = requestHeaders
  
  if let bodyParameters = bodyParameters {
   request.httpBody = try? JSONEncoder().encode(bodyParameters)
  }
  
  let dataTask = urlSession.dataTask(with: request) { [ weak self ] data, response, error in
   
   if let error = error  {
    if maxRetries > 0 {
     self?.request(endPoint: endPoint,
                  urlSession: urlSession,
                  queryParameters: queryParameters,
                  bodyParameters: bodyParameters,
                  httpMethod: httpMethod,
                  maxRetries: maxRetries - 1,
                  resultHandler: resultHandler)
    } else {
     resultHandler(.failure(error))
    }
    return
   }
   
   guard let httpResponse = response as? HTTPURLResponse else {
    if maxRetries > 0 {
     self?.request(endPoint: endPoint,
                  urlSession: urlSession,
                  queryParameters: queryParameters,
                  bodyParameters: bodyParameters,
                  httpMethod: httpMethod,
                  maxRetries: maxRetries - 1,
                  resultHandler: resultHandler)
    } else {
     resultHandler(.failure(HTTPRequestError.badServerResponse))
    }
    return
   }
   
   guard (200...299).contains(httpResponse.statusCode) else {
    if maxRetries > 0 {
     self?.request(endPoint: endPoint,
                  urlSession: urlSession,
                  queryParameters: queryParameters,
                  bodyParameters: bodyParameters,
                  httpMethod: httpMethod,
                  maxRetries: maxRetries - 1,
                  resultHandler: resultHandler)
    } else {
     resultHandler(.failure(HTTPRequestError.requestError(statusCode: httpResponse.statusCode)))
    }
    return
   }
   
   guard let data = data else {
    if maxRetries > 0 {
     self?.request(endPoint: endPoint,
                  urlSession: urlSession,
                  queryParameters: queryParameters,
                  bodyParameters: bodyParameters,
                  httpMethod: httpMethod,
                  maxRetries: maxRetries - 1,
                  resultHandler: resultHandler)
    } else {
     resultHandler(.failure(HTTPRequestError.noResponseData))
    }
    return
   }
   
   resultHandler(.success(data))
   
  }
  
  self.dataTask = dataTask
  
  dataTask.resume()
  
 }
 
 
}
