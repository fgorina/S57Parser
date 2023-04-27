//
//  File.swift
//  
//
//  Created by Francisco Gorina Vanrell on 27/4/23.
//

import Foundation
import MapKit

public protocol S57Displayable {
    
    var id : UInt64 {get}
    var prim : S57GeometricPrimitive {get}
    var region : MKCoordinateRegion? {get}
    var coordinates : [S57Coordinate] {get}
    
}
