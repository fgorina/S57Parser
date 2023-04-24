//
//  S57Feature.swift
//  S57Test
//
//  Created by Francisco Gorina Vanrell on 21/4/23.
//

import Foundation
import MapKit

enum S57GeometricPrimitive : UInt8 {
    case point = 1
    case line = 2
    case area = 3
    case null = 255
    
    var description : String {
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

struct S57Feature : Identifiable {
    
    // FRID
    var rcnm : UInt8
    var rcid : UInt32
    var prim : S57GeometricPrimitive
    var grup : UInt8
    var objl : UInt16
    var decodedObjl : String?
    var ruin : UInt8
    var rver : UInt16

    // Foid
    
    var agen : UInt16
    var fidn : UInt32
    var fids : UInt16
    
    var attributes : [UInt16 : S57Attribute] = [:]
    var nationalAttributes : [UInt16 : S57Attribute] = [:]
    
    // FFPT - >Feature Record to Feature Object pointer

    var ffpt : [S57FFPT] = []
    var fspt : [S57FSPT] = []
    
    var lnam : [Byte] {
        var bytes : [UInt8] = []
        
        bytes.append(contentsOf: agen.toBytes)
        bytes.append(contentsOf: fidn.toBytes)
        bytes.append(contentsOf: fids.toBytes)
        
        return bytes
    }
    
    var id : UInt64 { UInt64(littleEndianBytes: lnam) }
    
    var name : [Byte] {
        var bytes : [UInt8] = []
        
        bytes.append(rcnm)
        bytes.append(contentsOf: rcid.toBytes)
        
        return  bytes
    }
    
    var coordinates : [S57Coordinate]  {
        var out : [S57Coordinate] = []
        
        for pt in fspt {
            if let vector = pt.vector{
                out.append(contentsOf: vector.expandedCoordinates)
            }
        }
        
        return out
    }

    init(_ item : DataItem, objectCatalog: ObjectCatalog?, attributeCatalog: AttributeCatalog?, expectedInputCatalog : ExpectedInputCatalog?)  throws {
        
        let frid = item.FRID!
        rcnm = try frid.RCNM as? UInt8 ?! SomeErrors.encodingError
        rcid = try frid.RCID as? UInt32 ?! SomeErrors.encodingError
        ruin = try frid.RUIN as? UInt8 ?! SomeErrors.encodingError
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

        let foid = item.FOID!
        agen = try foid.AGEN as? UInt16 ?! SomeErrors.encodingError
        fidn = try foid.FIDN as? UInt32 ?! SomeErrors.encodingError
        fids = try foid.FIDS as? UInt16 ?! SomeErrors.encodingError

        if  let attributes = item.ATTF?.properties {
            for someAttr in attributes {
                if let id = someAttr.ATTL as? UInt16{
                    if let value = someAttr.ATVL as? String{

                        self.attributes[id] = S57Attribute(attribute: id, value: value, attributeCatalog: attributeCatalog, expectedInputCatalog: expectedInputCatalog)
                    }
                }
                
            }
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
