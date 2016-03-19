//
//  Photo.swift
//  Virtual Tourist
//
//  Created by Matthew Young on 2/20/16.
//  Copyright © 2016 Matthew Young. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class Photo: NSManagedObject {
    
    struct Keys {
        static let ImageURL = "imageURL"
        static let Identifier = "identifierString"
    }
    
    @NSManaged var imageURL: String
    @NSManaged var identifierString: String
    @NSManaged var pin: Pin?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String: AnyObject], context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        imageURL = dictionary[Keys.ImageURL] as! String
        identifierString = dictionary[Keys.Identifier] as! String
    }
    
    var photoImage: UIImage? {
        
        get {
            return FlickrClient.Caches.imageCache.imageWithIdentifier(identifierString)
        }
        
        set {
            FlickrClient.Caches.imageCache.storeImage(newValue, withIdentifier: identifierString)
        }
    }
}
