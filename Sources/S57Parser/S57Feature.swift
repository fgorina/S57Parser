//
//  S57Feature.swift
//  S57Test
//
//  Created by Francisco Gorina Vanrell on 21/4/23.
//

import Foundation
import MapKit

public enum S57UpdateInstruction : UInt8 {
    case insert = 1
    case delete = 2
    case modify = 3
    case null = 255
    
    public var description : String {
        
        switch self {
        case .insert:
            return "insert"
            
        case .delete:
            return "delete"
            
        case .modify:
            return "modify"
            
        case .null:
            return "null"
            
        }
    }
    
}

public enum S57GeometricPrimitive : UInt8 {
    case point = 1
    case line = 2
    case area = 3
    case null = 255
    
    public var description : String {
        switch self {
        case .point:
            return "Point"
        case .line:
            return "Line"
        case .area:
            return "Area"
        case .null:
            return "Null"

        }
    }
}

public struct S57Path {
    public var exterior : [S57Coordinate]
    public var interior : [S57Coordinate]
}

public struct S57Feature : Identifiable, S57Displayable {    
    
    // FRID
    public var rcnm : UInt8
    public var rcid : UInt32
    public var prim : S57GeometricPrimitive
    public var grup : UInt8
    public var objl : UInt16
    public var decodedObjl : String?
    public var ruin : S57UpdateInstruction
    public var rver : UInt16

    // Foid
    
    public var agen : UInt16
    public var fidn : UInt32
    public var fids : UInt16
    
    public var attributes : [UInt16 : S57Attribute] = [:]
    public var nationalAttributes : [UInt16 : S57Attribute] = [:]
    
    // FFPT - >Feature Record to Feature Object pointer

    public var ffpt : [S57FFPT] = []
    public var fspt : [S57FSPT] = []
    
    public var lnam : [Byte] {
        var bytes : [UInt8] = []
        
        bytes.append(contentsOf: agen.toBytes)
        bytes.append(contentsOf: fidn.toBytes)
        bytes.append(contentsOf: fids.toBytes)
        
        return bytes
    }
    
    public  var id : UInt64 { UInt64(littleEndianBytes: lnam) }
    
    public var name : [Byte] {
        var bytes : [UInt8] = []
        
        bytes.append(rcnm)
        bytes.append(contentsOf: rcid.toBytes)
        
        return  bytes
    }
    
    public var coordinates : S57Path {
         
        var exterior : [S57Coordinate] = []
        var interior : [S57Coordinate] = []
        
        for pt in fspt {
            
            if let vector = pt.vector{
                if pt.orientation == .reverse{
                    if pt.usageIndicator == .interior{
                        interior.append(contentsOf: vector.expandedCoordinates.reversed())
                    }else{
                        exterior.append(contentsOf: vector.expandedCoordinates.reversed())
                    }
                }else {
                    if pt.usageIndicator == .interior{
                        interior.append(contentsOf: vector.expandedCoordinates)
                    }else{
                        exterior.append(contentsOf: vector.expandedCoordinates)
                    }
                    
                }
            }
        }
        
        return S57Path(exterior: exterior, interior: interior)
    }

    public var region : MKCoordinateRegion?
    
    public var minScale : Double = 0.0
    
    func computeRegion() -> MKCoordinateRegion?{
        
        if coordinates.exterior.count == 0 {
            return nil
        } else if coordinates.exterior.count == 1 {
            return  MKCoordinateRegion(center: coordinates.exterior[0].coordinates, latitudinalMeters: 0.0, longitudinalMeters: 0.0)
        }else {
            var minLat : Double = coordinates.exterior[0].latitude
            var maxLat : Double = coordinates.exterior[0].latitude
            var minLon : Double = coordinates.exterior[0].longitude
            var maxLon : Double = coordinates.exterior[0].longitude
            
            for coordinate in coordinates.exterior {
                minLat = min(minLat, coordinate.latitude)
                minLon = min(minLon, coordinate.longitude)
                maxLat = max(maxLat, coordinate.latitude)
                maxLon = max(maxLon, coordinate.longitude)
            }
            
            let center = CLLocationCoordinate2D(latitude: (minLat + maxLat)/2.0, longitude: (minLon + maxLon)/2.0)
            let span = MKCoordinateSpan(latitudeDelta: maxLat - minLat, longitudeDelta: maxLon - minLon)
            
            return  MKCoordinateRegion(center: center, span: span)
        }
        
    }
    init(_ item : DataItem, objectCatalog: ObjectCatalog?, attributeCatalog: AttributeCatalog?, expectedInputCatalog : ExpectedInputCatalog?)  throws {
        
        let frid = item.FRID!
        rcnm = try frid.RCNM as? UInt8 ?! SomeErrors.encodingError
        rcid = try frid.RCID as? UInt32 ?! SomeErrors.encodingError
        let vruin = try frid.RUIN as? UInt8 ?! SomeErrors.encodingError
        ruin = S57UpdateInstruction(rawValue: vruin) ?? S57UpdateInstruction.null
        rver = try frid.RVER as? UInt16 ?! SomeErrors.encodingError
        objl = try frid.OBJL as? UInt16 ?! SomeErrors.encodingError
        let vprim = try frid.PRIM as? UInt8 ?! SomeErrors.encodingError
        prim = S57GeometricPrimitive(rawValue: vprim) ?? S57GeometricPrimitive.null
        grup = try frid.GRUP as? UInt8 ?! SomeErrors.encodingError
        
        if let objCat = objectCatalog{
            if let oc = objCat.objectForCode(objl){
                decodedObjl = oc.objectClass
            }else{
                decodedObjl =  "*** \(objl) ***"
            }
            
        }else{
            decodedObjl = "*** \(objl) ***"
        }
        
        if decodedObjl!.hasPrefix("***"){
            print("Not Found")
        }

        if let foid = item.FOID{
            agen = try foid.AGEN as? UInt16 ?! SomeErrors.encodingError
            fidn = try foid.FIDN as? UInt32 ?! SomeErrors.encodingError
            fids = try foid.FIDS as? UInt16 ?! SomeErrors.encodingError
        }else {
            agen = 0
            fidn = 0
            fids = 0
        }

        if  let attributes = item.ATTF?.properties {
            for someAttr in attributes {
                if let id = someAttr.ATTL as? UInt16{
                    if let value = someAttr.ATVL as? String{

                        self.attributes[id] = S57Attribute(attribute: id, value: value, attributeCatalog: attributeCatalog, expectedInputCatalog: expectedInputCatalog)
                    }
                }
                
            }
        }
        
        if let  xscale = self.attributes[133]?.value{   // Precompute  minScale
            minScale = Double(xscale) ?? 0.0
        }
        
        if  let nattributes = item.NATF?.properties {
            for someAttr in nattributes {
                if let id = someAttr.ATTL as? UInt16{
                    if let value = someAttr.ATVL as? String{
                        self.nationalAttributes[id] = S57Attribute(attribute: id, value: value, attributeCatalog: attributeCatalog, expectedInputCatalog: expectedInputCatalog)
                    }
                }
                
            }
        }

        
        if let pointers = item.FFPT?.properties {
            for point in pointers {
                let pt = S57FFPT(point)
                ffpt.append(pt)
            }
        }
        
        if let pointers = item.FSPT?.properties {
            for point in pointers {
                let pt = S57FSPT(point)
                fspt.append(pt)
            }
        }
    }
}
