//
//  MKCoordinateRegion + utils.swift
//  ChartCalculator
//
//  Created by Francisco Gorina Vanrell on 23/3/23.
//

import Foundation
import MapKit

extension MKCoordinateRegion {
    
    static var world = MKCoordinateRegion(top: 50, left: -20, bottom: -50, right: 20)
    static var emptyRegion = MKCoordinateRegion(top: 0, left: 0, bottom: 0, right: 0)
    

    var topLeft : CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: center.latitude - span.latitudeDelta / 2.0,
                          longitude: center.longitude - span.longitudeDelta / 2.0)
    }
    
    var bottomRight : CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: center.latitude + span.latitudeDelta / 2.0,
                          longitude: center.longitude + span.longitudeDelta / 2.0)
    }

    var bbox : [[Double]] {
        [[topLeft.latitude, topLeft.longitude],[bottomRight.latitude, bottomRight.longitude]]
    }
    
    var mapRect : MKMapRect {
        let a = MKMapPoint(CLLocationCoordinate2DMake(
                self.center.latitude + self.span.latitudeDelta / 2,
                self.center.longitude - self.span.longitudeDelta / 2));
        let  b = MKMapPoint(CLLocationCoordinate2DMake(
            self.center.latitude - self.span.latitudeDelta / 2,
            self.center.longitude + self.span.longitudeDelta / 2));
        return MKMapRect(x: min(a.x,b.x), y: min(a.y,b.y), width: abs(a.x-b.x), height: abs(a.y-b.y));
    }
    
    var radius: CLLocationDistance {
            let loc1 = CLLocation(latitude: center.latitude - span.latitudeDelta * 0.5, longitude: center.longitude)
            let loc2 = CLLocation(latitude: center.latitude + span.latitudeDelta * 0.5, longitude: center.longitude)
            let loc3 = CLLocation(latitude: center.latitude, longitude: center.longitude - span.longitudeDelta * 0.5)
            let loc4 = CLLocation(latitude: center.latitude, longitude: center.longitude + span.longitudeDelta * 0.5)
        
            let metersInLatitude = loc1.distance(from: loc2)
            let metersInLongitude = loc3.distance(from: loc4)
            let radius = max(metersInLatitude, metersInLongitude) / 2.0
            return radius
        }
    
    
    var boundary : MKPolygon {
        
        let coords = [CLLocationCoordinate2D(latitude: center.latitude - span.latitudeDelta, longitude: center.longitude - span.longitudeDelta),
                      CLLocationCoordinate2D(latitude: center.latitude + span.latitudeDelta, longitude: center.longitude - span.longitudeDelta),
                      CLLocationCoordinate2D(latitude: center.latitude + span.latitudeDelta, longitude: center.longitude + span.longitudeDelta),
                      CLLocationCoordinate2D(latitude: center.latitude - span.latitudeDelta, longitude: center.longitude + span.longitudeDelta)
               ]
        
        return MKPolygon(coordinates: coords, count: 4)
  
        
    }
    
    //Mark : - Initializer
    
    init(top : Double, left: Double, bottom : Double, right: Double){
        let center = CLLocationCoordinate2D(latitude: (top + bottom) / 2, longitude: (left + right) / 2)
        let span = MKCoordinateSpan(latitudeDelta: right - left, longitudeDelta: top - bottom)
        
        self.init(center: center, span: span)
    }
    
    
    //Mark : - Operations
    
    func intersects(_ region : MKCoordinateRegion) -> Bool {
        
        let r1 = self.mapRect
        let r2 = region.mapRect
        
        return r1.intersects(r2)
    }
    
    func intersection(_ region: MKCoordinateRegion) -> MKCoordinateRegion {
        return MKCoordinateRegion(mapRect.intersection(region.mapRect))
    }
    
    func union(_ region : MKCoordinateRegion) -> MKCoordinateRegion {
        return MKCoordinateRegion(mapRect.union(region.mapRect))
    }
    
    func resizedByFactor(_ factor: Double) -> MKCoordinateRegion{
        let newSpan = MKCoordinateSpan(latitudeDelta: self.span.latitudeDelta * factor, longitudeDelta: self.span.longitudeDelta * factor)
        
        return MKCoordinateRegion(center: center, span: newSpan)
    }

}

