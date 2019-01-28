//
//  GoogleTranslate.swift
//  TextDetect
//
//  Created by Sayalee Pote on 25/01/19.
//  Copyright © 2019 Assignment. All rights reserved.
//

import Foundation

class GoogleTranslate : NSObject {
    
    static let sharedInstance: GoogleTranslate = {
        let instance = GoogleTranslate()
        return instance
    }()
    
    let scheme  = "https"
    private var urlSession: URLSession!
    
    func translateTextTask(text: String, sourceLanguage: String = "en", targetLanguage: String, completionHandler: @escaping (String?, Error? ) -> Swift.Void) throws -> URLSessionDataTask {
        
        urlSession  = URLSession(configuration: URLSessionConfiguration.ephemeral)
        
        //  URL
        var urlComponents           = URLComponents()
        urlComponents.scheme        = scheme
        urlComponents.host          = "translation.googleapis.com"
        urlComponents.path          = "/language/translate/v2"
        
        urlComponents.queryItems    = [
            URLQueryItem(name: "key"  , value: "YOUR_GOOGLE_TRANSLATE_API_KEY")
        ]
        
        //  Headers
        let headers: [String: String]   = [
            "Content-Type" : "application/json"
        ]
        
        //  Parameters
        let parameters  = [ "q": text,
                            "source": sourceLanguage,
                            "target": targetLanguage,
                            "format": "text"
        ]
        
        let body  = try JSONSerialization.data(withJSONObject: parameters)
        
        let url   = urlComponents.url ?? URL(fileURLWithPath: "")
        
        // Create request
        var request     = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: urlSession.configuration.timeoutIntervalForRequest)
        
        request.httpMethod  = "POST"
        request.httpBody    = body
        
        for(headerField, headerValue) in headers {
            request.setValue(headerValue, forHTTPHeaderField: headerField)
        }
        
        // Create task
        let task = urlSession.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) in
            // Check error
            if  let err = error {
                completionHandler(nil, err)
                return
            }
            
            // Handle response data
            guard let data = data else {
                completionHandler(nil, nil)
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! Dictionary<String,AnyObject>
                
                // Check HTTP status code
                if  let response    = response as? HTTPURLResponse {
                    let statusCode  = response.statusCode
                    if  statusCode != 200 && statusCode != 201 {
                        let googleError = NSError(domain: "Google translation", code: statusCode, userInfo: nil)
                        completionHandler(nil, googleError)
                        return
                    }
                }
                
                if  let response = json as? [String:[String: [ [String:String] ] ]] {
                    let translatedText = response["data"]?["translations"]?[0]["translatedText"]
                    completionHandler(translatedText, nil)
                }
            }
            catch let error as NSError {
                completionHandler(nil, error)
            }
        })
        
        return  task
    }
    
}

