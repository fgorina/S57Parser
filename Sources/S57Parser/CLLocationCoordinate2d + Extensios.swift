//
//  File.swift
//  
//
//  Created by Francisco Gorina Vanrell on 24/4/23.
//

import Foundation
import MapKit

extension CLLocationCoordinate2D {
    
    func formatted() -> String {
        let lS = latitude >= 0 ? "N" : "S"
        let LS =  longitude >= 0 ? "E" : "W"
        return "\(abs(latitude).asDDDmmm())\(lS)  \(abs(longitude).asDDDmmm())\(LS)"
    }

}
