//
//  S57CatalogItem.swift
//  S57Test
//
//  Created by Francisco Gorina Vanrell on 24/4/23.
//

import Foundation

struct S57CatalogItem{
    
    enum Implementation : String {
        case asc = "ASC"
        case bin = "BIN"
        case txt = "TXT"
    }
    var id : UInt
    var file : String
    var longFile : String
    var volume : String
    var implementation : Implementation
    var slat : Double?
    var nlat : Double?
    var wlon : Double?
    var elon : Double?
    var crc : String
    var comment : String
    
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
