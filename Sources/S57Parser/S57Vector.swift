//
//  S57Vector.swift
//  S57Test
//
// Versió type safe de VRID.
//
//  Created by Francisco Gorina Vanrell on 21/4/23.
//

import Foundation
import MapKit

struct S57Coordinate : Identifiable {
    var longitude : Double
    var latitude : Double
    var depth : Double?
    
    var id : Double {
        latitude * 1000.0 + longitude
    }
    var coordinates : CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
}

struct S57Vector {
    
    var rcnm : UInt8
    var rcid : UInt32
    var ruin : UInt8
    var rver : UInt16
    
    var sounding : Bool    = false  // If true coordinates.ve3d has a value, if not i is nil
    var coordinates : [S57Coordinate] = []
    
    var attributes : [UInt16 : S57Attribute] = [:]
    
    var recordPointers : [S57VRPT] = []
        
    var name : [Byte] {
        var bytes : [UInt8] = []
        
        bytes.append(rcnm)
        bytes.append(contentsOf: rcid.toBytes)
        
        bytes.append(contentsOf: [0, 0, 0])
        
        return  bytes
    }
    var id : UInt64 {
     
        return UInt64(littleEndianBytes: name)
    }

    
    var rcnmDescription : String {
        switch rcnm {
        case 110 :
            return "Isolated Node"

        case 120 :
            return "Connected Node"

        case 130 :
            return "Edge"

        case 140 :
            return "Face"
            
        default:
            return "Not a vector rcnm \(rcnm)"

        }
    }
    
    var expandedCoordinates : [S57Coordinate]{
        var out : [S57Coordinate] = []
         
        // If Isolated no
        
        if  recordPointers.count > 0 {
            // Lookup referenced vector
            let vrpt = recordPointers[0]
            out.append(contentsOf: vrpt.vector?.expandedCoordinates ?? [])
        }
        
        out.append(contentsOf: coordinates)
        
        if recordPointers.count > 1 {
            let vrpt = recordPointers[1]
            out.append(contentsOf: vrpt.vector?.expandedCoordinates ?? [])
        }
        
        return out

    }
    
    init(_ item : DataItem, coordinateFactor : Double = 1.0, soundingFactor : Double = 1.0,
         attributeCatalog : AttributeCatalog?, expectedInputCatalog : ExpectedInputCatalog?)  throws {
        
        let vrid = item.VRID!
        rcnm = try vrid.RCNM as? UInt8 ?! SomeErrors.encodingError
        rcid = try vrid.RCID as? UInt32 ?! SomeErrors.encodingError
        ruin = try vrid.RUIN as? UInt8 ?! SomeErrors.encodingError
        rver = try vrid.RVER as? UInt16 ?! SomeErrors.encodingError
        
        if let points = item.SG2D?.properties{
            sounding = false
            for point in points  {
                let x : Int32? = point.XCOO as? Int32
                let y : Int32? = point.YCOO as? Int32
                let lon = Double(x ?? 0) / coordinateFactor
                let lat = Double(y ?? 0) / coordinateFactor
                
                let c = S57Coordinate(longitude: lon, latitude: lat)
                coordinates.append(c)
            }
            
        }else if let points = item.SG3D?.properties{
            sounding = true
            for point in points  {
                let x : Int32? = point.XCOO as? Int32
                let y : Int32? = point.YCOO as? Int32
                let d : Int32? = point.VE3D as? Int32
                let lon = Double(x ?? 0) / coordinateFactor
                let lat = Double(y ?? 0) / coordinateFactor
                let depth = Double(d ?? 0) / soundingFactor
                
                let c = S57Coordinate(longitude: lon, latitude: lat, depth : depth)
                coordinates.append(c)
            }
        }
        
        if let pointers = item.VRPT?.properties {
            for point in pointers {
                let pt = S57VRPT(point)
                recordPointers.append(pt)
            }
            
        }
        
        if  let attributes = item.ATTV?.properties {
            for someAttr in attributes {
                if let id = someAttr.ATTL as? UInt16{
                    if let value = someAttr.ATVL as? String{
                        self.attributes[id] = S57Attribute(attribute: id, value: value, attributeCatalog: attributeCatalog, expectedInputCatalog: expectedInputCatalog)
                    }
                }
                
            }
        }
          
    }

}
