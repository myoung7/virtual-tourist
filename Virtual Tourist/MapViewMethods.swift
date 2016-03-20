//
//  MapViewMethods.swift
//  Virtual Tourist
//
//  Created by Matthew Young on 2/20/16.
//  Copyright © 2016 Matthew Young. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreData

extension MapViewController {
    
    func loadMapView(location: MapPosition) {
        //Copied from MemoryMap
            
            let longitude = location.longitude as CLLocationDegrees
            let latitude = location.latitude as CLLocationDegrees
            let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            let longitudeDelta = location.longitudeDelta as CLLocationDegrees
            let latitudeDelta = location.latitudeDelta as CLLocationDegrees
            let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            
            let savedRegion = MKCoordinateRegion(center: center, span: span)
            
            print("lat: \(latitude), lon: \(longitude), latD: \(latitudeDelta), lonD: \(longitudeDelta)")
            
            mapView.setRegion(savedRegion, animated: true)

    }
    
    func saveMapViewData() {
        //Copied from MemoryMap
        
        if let results = loadMapViewData() {
            for item in results {
                sharedContext.deleteObject(item)
            }
        }
        
        let dictionary = [
            "latitude" : mapView.region.center.latitude,
            "longitude" : mapView.region.center.longitude,
            "latitudeDelta" : mapView.region.span.latitudeDelta,
            "longitudeDelta" : mapView.region.span.longitudeDelta
        ]
        
        let _ = MapPosition(dictionary: dictionary, context: sharedContext)
        CoreDataStackManager.sharedInstance().saveContext()
        
    }
    
    func loadMapViewData() -> [MapPosition]? {
//        fetchedResultsController.fetchRequest
        let fetchRequest = NSFetchRequest(entityName: "MapPosition")
        
        var mapPositionArray = [MapPosition]()
        
        do {
            mapPositionArray = try sharedContext.executeFetchRequest(fetchRequest) as! [MapPosition]
        } catch {
            print("Error loading last saved data.")
            return nil
        }
        
        return mapPositionArray
    }
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        saveMapViewData()
    }
    
    func createNewPinFromTouchLocation(sender: UIGestureRecognizer) -> Pin {
        let locationPoint = sender.locationInView(mapView)
        let locationCoordinate = mapView.convertPoint(locationPoint, toCoordinateFromView: mapView)
        
        let dictionary = [
            Pin.Keys.Latitude: locationCoordinate.latitude,
            Pin.Keys.Longitude: locationCoordinate.longitude,
        ]
        
        print(dictionary)
        
        let newPin = Pin(dictionary: dictionary, context: sharedContext)
        
        return newPin
    }
    
    func createNewAnnotationFromPin(pin: Pin) -> MapViewAnnotation {
        let location = CLLocationCoordinate2D(latitude: pin.latitude as Double, longitude: pin.longitude as Double)
        let annotation = MapViewAnnotation()
        
        annotation.coordinate = location
        annotation.pin = pin
        
        return annotation
    }
    
    func loadMapViewPins(pins: [Pin]) {
        for item in pins {
            let annotation = createNewAnnotationFromPin(item)
            annotation.pin = item
            mapView.addAnnotation(annotation)
        }
    }
    
}
