//
//  Pin.swift
//  Virtual Tourist
//
//  Created by Matthew Young on 2/19/16.
//  Copyright © 2016 Matthew Young. All rights reserved.
//

import Foundation
import CoreData

class Pin: NSManagedObject {
    
    struct Keys {
        static let Latitude = "latitude"
        static let Longitude = "longitude"
    }
    
    @NSManaged var latitude: NSNumber
    @NSManaged var longitude: NSNumber
    @NSManaged var photos: [Photo]
    
    var alreadyDownloadedAllPhotos: Bool {
        for item in photos {
            if item.photoImage == nil {
                return false
            }
        }
        return true
    }
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String: AnyObject], context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        latitude = dictionary[Keys.Latitude] as! Double
        longitude = dictionary[Keys.Longitude] as! Double
    }
    
}
