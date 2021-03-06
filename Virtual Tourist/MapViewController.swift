//
//  ViewController.swift
//  Virtual Tourist
//
//  Created by Matthew Young on 2/18/16.
//  Copyright © 2016 Matthew Young. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate, UIGestureRecognizerDelegate, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    
    @IBOutlet weak var deleteWarningLabel: UILabel!
    
    @IBAction func deleteButtonPressed(sender: UIBarButtonItem) {
        
        if deleteModeEnabled == false {
            deleteModeEnabled = true
            deleteWarningLabel.hidden = false
            deleteButton.tintColor = UIColor.whiteColor()
            deleteButton.title = "Cancel"
            
            navigationController?.navigationBar.barStyle = .BlackTranslucent
        } else {
            deleteModeEnabled = false
            deleteWarningLabel.hidden = true
            deleteButton.tintColor = nil
            deleteButton.title = "Delete"
            navigationController?.navigationBar.barStyle = .Default
        }
        
    }
    
    
    var isAbleToAddAnnotation = true
    var pinWasDragged = false
    var deleteModeEnabled = false
    
    var annotationToBeAdded: MapViewAnnotation?
    
    var selectedPin: Pin?
    
    var lastSavedLocation: MapPosition?
    
    var longPressGesture = UILongPressGestureRecognizer()
    
    var mapViewFilePath : String {
        let manager = NSFileManager.defaultManager()
        let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        return url.URLByAppendingPathComponent("mapRegionArchive").path!
    }
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchedResult = NSFetchRequest(entityName: "Pin")
        fetchedResult.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true)]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchedResult, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        return fetchedResultsController
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.longPressRecognized(_:)))
        longPressGesture.minimumPressDuration = 0.5
        view.addGestureRecognizer(longPressGesture)

        mapView.delegate = self
//        longPressGesture.delegate = self
        fetchedResultsController.delegate = self
        
        do {
           try fetchedResultsController.performFetch()
        } catch {
            
        }
        
        if let arrayOfPins = fetchedResultsController.fetchedObjects as? [Pin] {
            loadMapViewPins(arrayOfPins)
        }
        
        if let mapDataArray = loadMapViewData() {
            if mapDataArray.count > 0 {
                lastSavedLocation = mapDataArray[0]
                loadMapView(lastSavedLocation!)
            }
        }
    }
    
    func longPressRecognized(sender: UIGestureRecognizer) {
        if sender.state == .Began {
            let newPin = createNewPinFromTouchLocation(sender)
            let newAnnotation = createNewAnnotationFromPin(newPin)
            annotationToBeAdded = newAnnotation
            mapView.addAnnotation(newAnnotation)
            
            FlickrClient.sharedInstance().getNewPhotosFromPin(newPin, context: sharedContext) { success, errorString in
                guard errorString == nil else {
                    print(errorString!)
                    return
                }
                guard success else {
                    print("Error: FlickrClient failed to provide photos for current Pin.")
                    return
                }
                CoreDataStackManager.sharedInstance().saveContext()
            }
        }
        
        if sender.state == .Ended {
            CoreDataStackManager.sharedInstance().saveContext()
        }
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pinView")

        annotationView.draggable = true
        annotationView.annotation = annotation
        
        return annotationView
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        
        mapView.deselectAnnotation(view.annotation, animated: false)
        view.setSelected(true, animated: false)

        let annotation = view.annotation as! MapViewAnnotation
        
        if deleteModeEnabled {
            mapView.removeAnnotation(annotation)
            sharedContext.deleteObject(annotation.pin)
            CoreDataStackManager.sharedInstance().saveContext()
            return
        }
        
        if pinWasDragged {
            pinWasDragged = false
            sharedContext.deleteObject(annotation.pin)
            print("Deleted pin {\(annotation.pin.latitude), \(annotation.pin.longitude)}")
            
            let dictionary = [
                Pin.Keys.Latitude: annotation.coordinate.latitude,
                Pin.Keys.Longitude: annotation.coordinate.longitude
            ]
            
            annotation.pin = Pin(dictionary: dictionary, context: sharedContext)
            print("Added pin {\(annotation.pin.latitude), \(annotation.pin.longitude)}")
            CoreDataStackManager.sharedInstance().saveContext()
        } else {
            selectedPin = annotation.pin
            performSegueWithIdentifier("showPhotoAlbumSegue", sender: self)
        }
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        
        switch newState {
        case .Ending, .Canceling:
            pinWasDragged = true
        default: break
        }
        
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        print("Preparing for Segue")
        if segue.identifier == "showPhotoAlbumSegue" {
            let controller = segue.destinationViewController as! PhotoAlbumViewController
            controller.currentPin = selectedPin!
            print("Segue! \(segue.identifier)")
        }
    }
  
}

