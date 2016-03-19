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

//TODO: Images from every Pin appear within this controller. Need to fix.

class PhotoAlbumViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, NSFetchedResultsControllerDelegate, MKMapViewDelegate {
    
    @IBOutlet weak var imageCollectionView: UICollectionView!
    
    @IBOutlet weak var bottomActionButton: UIBarButtonItem!
    
    @IBOutlet weak var bottomToolbar: UIToolbar!
    
    @IBOutlet weak var mapView: MKMapView!
    
    var currentPin: Pin?
    
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
        let fetchedResult = NSFetchRequest(entityName: "Photo")
        fetchedResult.sortDescriptors = [NSSortDescriptor(key: "imageURL", ascending: true)]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchedResult, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        return fetchedResultsController
    }()
    
    @IBAction func bottomActionButtonPressed(sender: UIBarButtonItem) {
        
        if sender.title == "New Collection" {
            
        }
        
        if sender.title == "Delete Selected Photos" {
            for index in selectedPhotoIndexArray {
                let photo = fetchedResultsController.objectAtIndexPath(index) as! Photo
                sharedContext.deleteObject(photo)
            }
            CoreDataStackManager.sharedInstance().saveContext()
            selectedPhotoIndexArray.removeAll()
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("View Did Load")
        
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
        
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: 100, height: 100)
        
        try! fetchedResultsController.performFetch()
        
        imageCollectionView.delegate = self
        fetchedResultsController.delegate = self
        
        //Checks to see if there are already photo links fetched for the given pin. If there are none, it will go ahead and fetch the links to those photos.
        
        if fetchedResultsController.sections![0].numberOfObjects == 0 {
            FlickrClient.sharedInstance().getNewPhotosFromPin(currentPin!, context: sharedContext) { (success, errorString) -> Void in
                guard errorString != nil else {
                    print(errorString)
                    return
                }
                
                if success {
                    dispatch_async(dispatch_get_main_queue()) {
                        try! self.fetchedResultsController.performFetch()
                        self.imageCollectionView.reloadData()
                        print("Success!")
                        //TODO: Finish setting up Collection View with results
                    }
                } else {
                    print("No success.")
                }
                self.saveContext()
                self.imageCollectionView.reloadData()
                
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
        cell.backgroundColor = UIColor.orangeColor()
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! CollectionViewCell
        
        for item in selectedPhotoIndexArray {
            if item == indexPath {
                cell.imageView.alpha = 1.0
                cell.backgroundColor = UIColor.orangeColor()
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
    
    //TODO: Fix layout of Collection View Cells
    
    //
    
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
            }, completion: nil)
    }
    
    func configureCell(cell: CollectionViewCell, indexPath: NSIndexPath) {

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
            
            guard let image = resultImage else {
                print("Error: Could not load image for cell.")
                dispatch_async(dispatch_get_main_queue()) {
                    cell.activityIndicator.stopAnimating()
                }
                return
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                cell.activityIndicator.stopAnimating()
                cell.imageView.image = image
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
    
//  // Holding on to this code for future reference.
//    //http://stackoverflow.com/questions/20554137/nsfetchedresultscontollerdelegate-for-collectionview
//    
//    func controllerWillChangeContent(controller: NSFetchedResultsController) {
////        self.tableView.beginUpdates()
//        blockOperations.removeAll(keepCapacity: false)
//        
//    }
//    func controller(controller: NSFetchedResultsController,
//        didChangeSection sectionInfo: NSFetchedResultsSectionInfo,
//        atIndex sectionIndex: Int,
//        forChangeType type: NSFetchedResultsChangeType) {
//            
//            switch type {
//            case .Insert:
////                self.tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
//                blockOperations.append(
//                    NSBlockOperation(block: {
//                        self.imageCollectionView.insertSections(NSIndexSet(index: sectionIndex))
//                    })
//                )
//            
//            case .Delete:
////                self.tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
//                blockOperations.append(
//                    NSBlockOperation(block: {
//                        self.imageCollectionView.deleteSections(NSIndexSet(index: sectionIndex))
//                    })
//                )
//            
//            default:
//                return
//            }
//    }
//    
//    func controllerDidChangeContent(controller: NSFetchedResultsController) {
//        imageCollectionView.performBatchUpdates({ () -> Void in
//            for operation in self.blockOperations {
//                operation.start()
//            }
//            }) { (finished) -> Void in
//                self.blockOperations.removeAll(keepCapacity: false)
//                self.imageCollectionView.reloadData()
//        }
//    }
//    
//    func controller(controller: NSFetchedResultsController,
//        didChangeObject anObject: AnyObject,
//        atIndexPath indexPath: NSIndexPath?,
//        forChangeType type: NSFetchedResultsChangeType,
//        newIndexPath: NSIndexPath?) {
//            
//            switch type {
//            case .Insert:
////                tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
////                imageCollectionView.insertItemsAtIndexPaths([newIndexPath!])
//                blockOperations.append(
//                    NSBlockOperation(block: {
//                        self.imageCollectionView.insertItemsAtIndexPaths([newIndexPath!])
//                    })
//                )
//                
//            case .Delete:
////                tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
//                blockOperations.append(
//                    NSBlockOperation(block: {
//                        self.imageCollectionView.deleteItemsAtIndexPaths([indexPath!])
//                    })
//                )
//                
//            case .Update:
////                let cell = tableView.cellForRowAtIndexPath(indexPath!) as! ActorTableViewCell
////                let movie = controller.objectAtIndexPath(indexPath!) as! Movie
////                self.configureCell(cell, movie: movie)
//                blockOperations.append(
//                    NSBlockOperation(block: {
//                        self.imageCollectionView.reloadItemsAtIndexPaths([indexPath!])
//                    })
//                )
//                //TODO: Load image
//                
//            case .Move:
////                tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
////                tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
////                imageCollectionView.deleteItemsAtIndexPaths([indexPath!])
////                imageCollectionView.insertItemsAtIndexPaths([newIndexPath!])
//                blockOperations.append(
//                    NSBlockOperation(block: {
//                        self.imageCollectionView.moveItemAtIndexPath(indexPath!, toIndexPath: newIndexPath!)
//                    })
//                )
//                
//            }
//    }
}