//
//  ImageHandler.swift
//  Virtual Tourist
//
//  Created by Matthew Young on 3/28/16.
//  Copyright © 2016 Matthew Young. All rights reserved.
//

import Foundation
import UIKit

//Got help from http://stackoverflow.com/questions/26285808/how-to-save-a-remote-image-with-swift

class ImageHandler {
    
    static let sharedInstance = ImageHandler()
    
    /** Generates an image path URL to the specified file associated with the given identifier.
    */
    
    func generateImagePathURL(identifier: String) -> NSURL {
        let directory = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first
        let pathArray = [directory!.path!, identifier]
        return NSURL.fileURLWithPathComponents(pathArray)!
    }
    
    /** Stores image with a specified Identifier string. If successful, returns the file path URL as an NSURL.
    */
    
    func storeImageWithIdentifier(identifier: String, image: UIImage) -> NSURL? {
        
        let fileURL = generateImagePathURL(identifier)
        
        if let data = UIImageJPEGRepresentation(image, 1) {
            let _ = data.writeToFile(fileURL.path!, atomically: true)
            return fileURL
        }
        return nil
    }
    
}
