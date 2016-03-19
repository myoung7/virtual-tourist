//
//  FlickrConstants.swift
//  Virtual Tourist
//
//  Created by Matthew Young on 2/20/16.
//  Copyright © 2016 Matthew Young. All rights reserved.
//

import Foundation

extension FlickrClient {
    struct Constants {
        static var APIKey: String? {
            //Loads the API Key located in the "Keys.plist"
            var key: NSDictionary?
            
            if let path = NSBundle.mainBundle().pathForResource("Keys", ofType: "plist") {
                key = NSDictionary(contentsOfFile: path)
            }
            
            if let dictionary = key {
                if let apiKey = dictionary["flickrAPIKey"] as? String {
                    return apiKey
                }
            }
            
            return nil
        }
        
        static let LocationAccuracy = 0.0002
        
        static let SecureBaseURL = "https://api.flickr.com/services/rest/"
    }
    
    struct Methods {
        static let PhotoSearch = "flickr.photos.search"
    }
    
    struct ParameterKeys {
        static let APIKey = "api_key"
        static let BBOX = "bbox"
        static let Latitude = "lat"
        static let Longitude = "lon"
        static let DistanceRadius = "radius"
        static let Method = "method"
        static let Format = "format"
        static let NoJSONCallback = "nojsoncallback"
        static let Extras = "extras"
        static let PerPage = "per_page"
    }
    
    struct ResponseKeys {
        static let PhotoDictionary = "photos"
        static let Photo = "photo"
        static let ID = "id"
        static let ServerID = "server"
        static let Secret = "secret"
    }
    
    struct ImageURLModifiers {
        static let SmallSquare = "s"
        static let LargeSquare = "q"
        static let Thumbnail = "t"
        static let Medium = "z"
    }
    
}