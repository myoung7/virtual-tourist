//
//  FlickrClient.swift
//  Virtual Tourist
//
//  Created by Matthew Young on 2/20/16.
//  Copyright © 2016 Matthew Young. All rights reserved.
//

import Foundation
import MapKit
import CoreData

class FlickrClient {
    
    typealias CompletionHander = (result: AnyObject!, error: NSError?) -> Void
    
    var session: NSURLSession
    
    let photosPerPageLimit = 40
    let numberOfPagesLimit = 100
    
    init() {
        session = NSURLSession.sharedSession()
    }
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    func taskForGETMethod(method method: String, parameters: [String: AnyObject], completionHandler: CompletionHander) {
        var mutableParameters = parameters
        
        guard let apiKey = Constants.APIKey else {
            print("Error: Could not load API Key.")
            return
        }
        
        mutableParameters[ParameterKeys.APIKey] = apiKey
        mutableParameters[ParameterKeys.Method] = method
        mutableParameters[ParameterKeys.Format] = "json"
        mutableParameters[ParameterKeys.NoJSONCallback] = "1"
        
        let urlString = Constants.SecureBaseURL + FlickrClient.escapedParameters(mutableParameters)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            guard error == nil else {
                completionHandler(result: nil, error: error)
                return
            }
            
            guard let data = data else {
                completionHandler(result: nil, error: NSError(domain: "taskForGETMethod", code: -145, userInfo: [NSLocalizedDescriptionKey: "Could not retrieve data in taskForGETMethod."]))
                return
            }
            
            FlickrClient.parseJSONWithCompletionHandler(data, completionHandler: completionHandler)
            
            //TODO: Finish dataTask
            
        }
        
        task.resume()
    }
    
    func generateFlickrImageURL(dictionary: [String: AnyObject]) -> String {
        return "https://farm2.staticflickr.com/\(dictionary[ResponseKeys.ServerID]!)/\(dictionary[ResponseKeys.ID]!)_\(dictionary[ResponseKeys.Secret]!)_\(ImageURLModifiers.Medium).jpg"
        
        //https://farm{farm-id}.staticflickr.com/{server-id}/{id}_{secret}_[mstzb].jpg
    }
    
    class func createBBOXValue(latitude: CLLocationDegrees, longitude: CLLocationDegrees) -> String {
        let lat = latitude
        let lon = longitude
        
        let maxLat = lat + Constants.LocationAccuracy
        let minLat = lat - Constants.LocationAccuracy
        let maxLon = lon + Constants.LocationAccuracy
        let minLon = lon + Constants.LocationAccuracy
        
        return "\(minLon),\(minLat),\(maxLat),\(maxLon)"
    }
    
    class func parseJSONWithCompletionHandler(data: NSData, completionHandler: CompletionHander) {
        //Copied from FavoriteActors app.
        var parsingError: NSError? = nil
        
        let parsedResult: AnyObject?
        do {
            parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments)
        } catch let error as NSError {
            parsingError = error
            parsedResult = nil
        }
        
        if let error = parsingError {
            completionHandler(result: nil, error: error)
        } else {
            completionHandler(result: parsedResult, error: nil)
        }
    }
    
    class func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            // make sure that it is a string value
            let stringValue = "\(value)"
            
            // Escape it
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            // Append it
            
            if let unwrappedEscapedValue = escapedValue {
                urlVars += [key + "=" + "\(unwrappedEscapedValue)"]
            } else {
                print("Warning: trouble excaping string \"\(stringValue)\"")
            }
        }
        
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }
    
    class func sharedInstance() -> FlickrClient {
        
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        
        return Singleton.sharedInstance
    }
    
}
