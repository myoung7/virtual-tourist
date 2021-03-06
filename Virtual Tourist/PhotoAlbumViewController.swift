//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Matthew Young on 2/18/16.
//  Copyright © 2016 Matthew Young. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, NSFetchedResultsControllerDelegate, MKMapViewDelegate {
    
    @IBOutlet weak var imageCollectionView: UICollectionView!
    
    @IBOutlet weak var bottomActionButton: UIBarButtonItem!
    
    @IBOutlet weak var bottomToolbar: UIToolbar!
    
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var mainActivityIndicator: UIActivityIndicatorView!
    
    var currentPin: Pin?
    
    var gettingNewImages = false
    
    var blockOperations = [NSBlockOperation]()
    
    var selectedPhotoIndexArray = [NSIndexPath]()
    
    var insertedPaths: [NSIndexPath]!
    var deletedPaths: [NSIndexPath]!
    var updatedPaths: [NSIndexPath]!
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    func saveContext() {
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "imageURL", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.currentPin!)
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        return fetchedResultsController
    }()
    
    @IBAction func bottomActionButtonPressed(sender: UIBarButtonItem) {
        
        if sender.title == "New Collection" {
            gettingNewImages = true
            bottomActionButton.enabled = false
            mainActivityIndicator.hidden = false
            mainActivityIndicator.startAnimating()
            if let objects = fetchedResultsController.fetchedObjects {
                for item in objects {
                    sharedContext.deleteObject(item as! Photo)
                }
                self.saveContext()
            }
            getNewImages()
        }
        
        if sender.title == "Delete Selected Photos" {
            for index in selectedPhotoIndexArray {
                let photo = fetchedResultsController.objectAtIndexPath(index) as! Photo
                sharedContext.deleteObject(photo)
            }
            self.saveContext()
            selectedPhotoIndexArray.removeAll()
            
            bottomToolbar.barTintColor = UIColor.whiteColor()
            bottomActionButton.tintColor = nil
            bottomActionButton.title = "New Collection"
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        mapView.zoomEnabled = false
        mapView.scrollEnabled = false
        mapView.userInteractionEnabled = false
        
        if let pin = currentPin {
            loadMapViewFromPin(pin)
            let mapAnnotation = MKPointAnnotation()
            mapAnnotation.coordinate = CLLocationCoordinate2D(latitude: pin.latitude as CLLocationDegrees, longitude: pin.longitude as CLLocationDegrees)
            mapView.addAnnotation(mapAnnotation)
        }
        
        try! fetchedResultsController.performFetch()
        
        imageCollectionView.delegate = self
        fetchedResultsController.delegate = self
        
        //Checks to see if there are already photo links fetched for the given pin. If there are none, it will go ahead and fetch the links to those photos.
        
        if currentPin!.photos.isEmpty {
            FlickrClient.sharedInstance().getNewPhotosFromPin(currentPin!, context: sharedContext) { (success, errorString) -> Void in
                guard errorString == nil else {
                    print(errorString)
                    return
                }
                
                if success {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.saveContext()
                        try! self.fetchedResultsController.performFetch()
                        print("Success!")
                        //TODO: Finish setting up Collection View with results
                    }
                } else {
                    print("No success.")
                }
            }
        }
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("CollectionViewCell", forIndexPath: indexPath) as! CollectionViewCell
        
        cell.activityIndicator.startAnimating()
        
        configureCell(cell, indexPath: indexPath)
        
        for item in selectedPhotoIndexArray {
            if item == indexPath {
                cell.imageView.alpha = 0.5
                cell.backgroundColor = UIColor.redColor()
                return cell
            }
        }
        
        cell.imageView.alpha = 1.0
        cell.backgroundColor = UIColor.lightGrayColor()
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! CollectionViewCell
        
        for item in selectedPhotoIndexArray {
            if item == indexPath {
                cell.imageView.alpha = 1.0
                cell.backgroundColor = UIColor.lightGrayColor()
                selectedPhotoIndexArray.removeAtIndex(selectedPhotoIndexArray.indexOf(item)!)
                if selectedPhotoIndexArray.count == 0 {
                    bottomToolbar.barTintColor = UIColor.whiteColor()
                    bottomActionButton.tintColor = UIColor.blueColor()
                    bottomActionButton.title = "New Collection"
                }
                return
            }
        }
        
        cell.imageView.alpha = 0.5
        cell.backgroundColor = UIColor.redColor()
        selectedPhotoIndexArray.append(indexPath)
        bottomToolbar.barTintColor = UIColor.redColor()
        bottomActionButton.tintColor = UIColor.whiteColor()
        bottomActionButton.title = "Delete Selected Photos"
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let width = (view.frame.width / 3) - 1
        let height = width
        
        return CGSize(width: width, height: height)
    }
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        insertedPaths = []
        deletedPaths = []
        updatedPaths = []
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            insertedPaths.append(newIndexPath!)
        case .Delete:
            deletedPaths.append(indexPath!)
        case .Update:
            updatedPaths.append(indexPath!)
        default:
            break
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        imageCollectionView.performBatchUpdates({

            self.imageCollectionView.insertItemsAtIndexPaths(self.insertedPaths)
            
            self.imageCollectionView.deleteItemsAtIndexPaths(self.deletedPaths)
            
            self.imageCollectionView.reloadItemsAtIndexPaths(self.updatedPaths)
            
            }, completion: { _ in
                self.saveContext()
                self.imageCollectionView.reloadData() //Reloading to correct any cells that are still shown as selected (i.e. highlighted in red)
                print("All done!")
            }
        )
    }
    
    func configureCell(cell: CollectionViewCell, indexPath: NSIndexPath) {
        
        if gettingNewImages == true {
            cell.imageView.image = nil
        }

        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        guard photo.photoImage == nil else {
            cell.imageView.image = photo.photoImage
            cell.activityIndicator.stopAnimating()
            return
        }
        
        FlickrClient.sharedInstance().getImageForPhoto(photo) { (resultImage, errorString) -> Void in
            guard errorString == nil else {
                print(errorString!)
                dispatch_async(dispatch_get_main_queue()) {
                    cell.activityIndicator.stopAnimating()
                }
                return
            }

            dispatch_async(dispatch_get_main_queue()) {
                cell.activityIndicator.stopAnimating()
                cell.imageView.image = photo.photoImage
            }
            
        }
    }
    
    func loadMapViewFromPin(pin: Pin) {
        //Copied from MemoryMap

            let longitude = pin.longitude as CLLocationDegrees
            let latitude = pin.latitude as CLLocationDegrees
            let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            let longitudeDelta = 0.02 as CLLocationDegrees
            let latitudeDelta = 0.02 as CLLocationDegrees
            let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            
            let savedRegion = MKCoordinateRegion(center: center, span: span)
            
            print("PhotoAlbum lat: \(latitude), lon: \(longitude), latD: \(latitudeDelta), lonD: \(longitudeDelta)")
            
            mapView.setRegion(savedRegion, animated: true)
        }
    
    func getNewImages() {
        FlickrClient.sharedInstance().getNewPhotosFromPin(currentPin!, context: sharedContext){ (success, errorString) in
            guard errorString == nil else {
                if errorString == FlickrClient.ErrorMessages.NoImagesReturned {
                    print(errorString!)
                    self.getNewImages()
                    return
                }
                print(errorString)
                dispatch_async(dispatch_get_main_queue(), {
                    self.mainActivityIndicator.stopAnimating()
                    self.mainActivityIndicator.hidden = true
                    self.bottomActionButton.enabled = true
                })
                return
            }
            
            if success {
                dispatch_async(dispatch_get_main_queue()) {
                    self.saveContext()
                    self.gettingNewImages = false
                    try! self.fetchedResultsController.performFetch()
                    self.imageCollectionView.reloadData()
                    print("Success!")
                    //TODO: Finish setting up Collection View with results
                }
            } else {
                print("No success.")
            }
            dispatch_async(dispatch_get_main_queue(), {
                self.gettingNewImages = false
                self.mainActivityIndicator.stopAnimating()
                self.mainActivityIndicator.hidden = true
                self.bottomActionButton.enabled = true
            })
        }

    }
}