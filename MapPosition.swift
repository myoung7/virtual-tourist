//
//  MapPosition.swift
//  Virtual Tourist
//
//  Created by Matthew Young on 2/29/16.
//  Copyright © 2016 Matthew Young. All rights reserved.
//

import Foundation
import MapKit
import CoreData

class MapPosition: NSManagedObject {
    @NSManaged var latitude: NSNumber
    @NSManaged var longitude: NSNumber
    @NSManaged var latitudeDelta: NSNumber
    @NSManaged var longitudeDelta: NSNumber

    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }

    init(dictionary: [String: AnyObject], context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("MapPosition", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)

        self.latitude = dictionary["latitude"] as! CLLocationDegrees
        self.longitude = dictionary["longitude"] as! CLLocationDegrees
        self.latitudeDelta = dictionary["latitudeDelta"] as! CLLocationDegrees
        self.longitudeDelta = dictionary["longitudeDelta"] as! CLLocationDegrees
    }
}
