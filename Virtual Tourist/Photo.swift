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
        static let ImageFilePath = "imageFilePath"
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

            let imagePath = ImageHandler.sharedInstance.generateImagePathURL(identifierString)
            print(NSFileManager.defaultManager().fileExistsAtPath(imagePath.path!))
            if let image = UIImage(contentsOfFile: imagePath.path!) {
                return image
            } else {
                return nil
            }
    }
    
    // MARK: Delete the associated image file when the Photo managed object is deleted.
    
    override func prepareForDeletion() {

        do {
            try NSFileManager.defaultManager().removeItemAtURL(ImageHandler.sharedInstance.generateImagePathURL(identifierString))
            print("Image deleted!")
        } catch {
            print("Whoops...")
        }
        
    }
}
