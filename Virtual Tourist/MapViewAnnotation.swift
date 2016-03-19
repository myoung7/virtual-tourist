//
//  MapViewAnnotation.swift
//  Virtual Tourist
//
//  Created by Matthew Young on 2/21/16.
//  Copyright © 2016 Matthew Young. All rights reserved.
//

import Foundation
import MapKit

class MapViewAnnotation: MKPointAnnotation {
    //Copied pieces from http://stackoverflow.com/questions/29300565/unable-to-conform-mkannotation-protocol-in-swift
    var pin: Pin!
}