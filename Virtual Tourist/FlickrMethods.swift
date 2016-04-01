//
//  FlickrMethods.swift
//  Virtual Tourist
//
//  Created by Matthew Young on 2/21/16.
//  Copyright © 2016 Matthew Young. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreData

extension FlickrClient {
    
    typealias successErrorStringCompletionHandler = (success: Bool, errorString: String?) -> Void
    typealias resultImageErrorStringCompletionHandler = (resultImage: UIImage?, errorString: String?) -> Void
    
    func getNewPhotosFromPin(pin: Pin, context: NSManagedObjectContext, completionHandler: successErrorStringCompletionHandler) {
        
        let parameters = [
            ParameterKeys.Latitude: pin.latitude,
            ParameterKeys.Longitude: pin.longitude,
            ParameterKeys.DistanceRadius: 20,
            ParameterKeys.PerPage: photosPerPageLimit
        ]
        
        taskForGETMethod(method: Methods.PhotoSearch, parameters: parameters) { (result, error) -> Void in
            guard error == nil else {
                completionHandler(success: false, errorString: "Error in getNewPhotosFromPin")
                return
            }
            
            let photoDictionary = result[ResponseKeys.PhotoDictionary] as! NSDictionary
            
            let photoArray = photoDictionary[ResponseKeys.Photo] as! [[String: AnyObject]]
            
            for item in photoArray {
                let imageURLParameters: Dictionary<String, AnyObject> = [
                    ResponseKeys.ID: item[ResponseKeys.ID]!,
                    ResponseKeys.ServerID: item[ResponseKeys.ServerID]!,
                    ResponseKeys.Secret: item[ResponseKeys.Secret]!,
                ]
                
                let imageURL = self.generateFlickrImageURL(imageURLParameters)
                
                let dictionary: [String: AnyObject] = [
                    Photo.Keys.ImageURL: imageURL,
                    Photo.Keys.Identifier: NSURL(fileURLWithPath: imageURL).lastPathComponent!
                ]

                let photo = Photo(dictionary: dictionary, context: context)
                photo.pin = pin
                CoreDataStackManager.sharedInstance().saveContext()
                
                self.getImageForPhoto(photo) { (_, errorString) in
                    guard errorString == nil else {
                        print(errorString)
                        return
                    }
                    print("Successfully loaded photo.")
                    CoreDataStackManager.sharedInstance().saveContext()
                }
            }
            completionHandler(success: true, errorString: nil)
        }
    }
    
    func getImageForPhoto(photo: Photo, completionHandler: resultImageErrorStringCompletionHandler) {
        
        let url = NSURL(string: photo.imageURL)!
        
        let request = NSURLRequest(URL: url)
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, response, error) -> Void in
            guard error == nil else {
                completionHandler(resultImage: nil, errorString: "Error getting image data: \(error!)")
                return
            }

            let image = UIImage(data: data!)
            ImageHandler.sharedInstance.storeImageWithIdentifier(url.lastPathComponent!, image: image!)
            CoreDataStackManager.sharedInstance().saveContext()
            
            completionHandler(resultImage: image, errorString: nil)
        }
        
        task.resume()

    }
    
}
