//
//  Request Representable Async.swift
//  PlayerKit
//
//  Created by Anton2016 on 10.01.2023.
//

@available(iOS 15.0, *)
extension URLSessionRequestRepresentable {

 func requestJSON<Parameters : Encodable>(endPoint: String = "",
                                          urlSession: URLSession = .shared,
                                          queryParameters: [URLQueryItem] = [],
                                          bodyParameters: Parameters? = Optional<String>.none,
                                          httpMethod: HTTPMethods = .get) async throws -> Any {
  
  let data = try await request(endPoint: endPoint,
                               urlSession: urlSession,
                               queryParameters: queryParameters,
                               bodyParameters: bodyParameters,
                               httpMethod: httpMethod)
  
  return try JSONSerialization.jsonObject(with: data)
 }
 
 

 func requestDecodable<Result     : Decodable,
                       Parameters : Encodable>(endPoint: String = "",
                                               urlSession: URLSession = .shared,
                                               queryParameters: [URLQueryItem] = [],
                                               bodyParameters: Parameters? = Optional<String>.none,
                                               httpMethod: HTTPMethods = .get) async throws -> Result {
  
  let data = try await request(endPoint: endPoint,
                               urlSession: urlSession,
                               queryParameters: queryParameters,
                               bodyParameters: bodyParameters,
                               httpMethod: httpMethod)
  
  return try JSONDecoder().decode(Result.self, from: data)
 }
 

 func request<Parameters: Encodable>(endPoint: String = "",
                                     urlSession: URLSession = .shared,
                                     queryParameters: [ URLQueryItem ] = [],
                                     bodyParameters: Parameters? = Optional<String>.none,
                                     httpMethod: HTTPMethods = .get,
                                     maxRetries: Int = 10) async throws -> Data {
  
  guard let requestUrl = getRequestURL(endPoint: endPoint, queryParameters: queryParameters) else {
   throw HTTPRequestError.invalidRequestURL
  }
  
  var request = URLRequest(url: requestUrl)
  request.httpMethod = httpMethod.rawValue
  request.allHTTPHeaderFields = requestHeaders
  
  if let bodyParameters = bodyParameters {
   request.httpBody = try JSONEncoder().encode(bodyParameters)
  }
  
  do {
   
   let (data, response) = try await urlSession.data(for: request)
   
   guard let httpResponse = response as? HTTPURLResponse else {
    throw HTTPRequestError.badServerResponse
   }
   
   
   guard (200...299).contains(httpResponse.statusCode) else {
    throw HTTPRequestError.requestError(statusCode: httpResponse.statusCode)
   }
   
   return data
   
  } catch {
   
   guard maxRetries > 0 else { throw error }
   
   return try await self.request(endPoint: endPoint,
                                 urlSession: urlSession,
                                 queryParameters: queryParameters,
                                 bodyParameters: bodyParameters,
                                 httpMethod: httpMethod,
                                 maxRetries: maxRetries - 1)
  }
  
 }
 
}
