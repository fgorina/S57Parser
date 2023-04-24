//
//  S57CatalogItem.swift
//  S57Test
//
//  Created by Francisco Gorina Vanrell on 24/4/23.
//

import Foundation
import MapKit

public struct S57CatalogItem : Identifiable{
    
    public enum Implementation : String {
        case asc = "ASC"
        case bin = "BIN"
        case txt = "TXT"
    }
    public var id : UInt
    public var file : String
    public var longFile : String
    public var volume : String
    public var implementation : Implementation
    public var slat : Double?
    public var nlat : Double?
    public var wlon : Double?
    public var elon : Double?
    public var crc : String
    public var comment : String
    
    public var region : MKCoordinateRegion? {
        if let nlat = nlat, let slat = slat, let wlon = wlon, let elon = elon {
            let span = MKCoordinateSpan(latitudeDelta: nlat - slat, longitudeDelta: elon - wlon)
            let center = CLLocationCoordinate2D(latitude: (nlat + slat) / 2.0, longitude: (elon + wlon) / 2.0)
            
            return MKCoordinateRegion(center: center, span: span)
        }else{
            return nil
        }
    }
    
    public var descCoordinates : String {
        
        if let region = region {
            return "\(region.center.latitude) \(region.center.longitude) Size \(region.span.latitudeDelta)  \(region.span.longitudeDelta)"
        }else{
            return ""
        }
    }
    
    init(_ item : DataItem) throws{
        do{
            let field = try item.CATD ?!  SomeErrors.notACatalogEntry
            let rcid = (try field.RCID ?! SomeErrors.encodingError) as! String
            id = try UInt(rcid) ?! SomeErrors.encodingError
            
            file = (try field.FILE ?! SomeErrors.encodingError) as! String
            longFile = (try field.LFIL ?! SomeErrors.encodingError) as! String
            
            volume = (try field.VOLM ?! SomeErrors.encodingError) as! String
            
            let simp = (try field.IMPL ?! SomeErrors.encodingError) as! String
            implementation = try Implementation(rawValue: simp) ?! SomeErrors.encodingError
            
            var v = (try field.SLAT  ?! SomeErrors.encodingError) as! String
            slat =  Double(v)
            
            v = (try field.NLAT  ?! SomeErrors.encodingError) as! String
            nlat =  Double(v)
            
            v = (try field.WLON  ?! SomeErrors.encodingError) as! String
            wlon =  Double(v)
            
            v = (try field.ELON  ?! SomeErrors.encodingError) as! String
            elon =  Double(v)
            
            crc = (try field.CRCS ?! SomeErrors.encodingError) as! String
            comment = (try field.COMT ?! SomeErrors.encodingError) as! String
            
        }catch{
            print(error)
            throw(error)
        }
            
    }
}
