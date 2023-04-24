//
//  ObjectCatalog.swift
//  S57Test
//
//  Created by Francisco Gorina Vanrell on 21/4/23.
//

import Foundation

struct AttributeCatalog{
    
    struct AttributeDescription {
        
        var code : UInt16
        var attribute : String
        var acronym : String
        var attributeType : String
        var classType : String

        init(row : [String]) throws{
            code = try UInt16(row[0]) ?! SomeErrors.encodingError
            attribute = row[1]
            acronym = row[2]
            attributeType = row[3]
            classType = row[4]
        }
    }
    
    private var attributes : [UInt16 : AttributeDescription] = [:]
    
    init(rows : [[String]]){
        
        for row in rows{
            if row.count == 5 {
                if let att = try? AttributeDescription(row: row){
                    attributes[att.code] = att
                }
            }
        }
    }
    
    init (url : URL) throws{
        let csv = try CSVData(url: url, separator: ",")
        self.init(rows : csv.rows)
    }
    
    func attributeForCode(_ i : UInt16) -> AttributeDescription?{
        return attributes[i]
    }
    
    func attributeForAcronym(_ acr : String)  -> AttributeDescription?{
        return attributes.first { (key: UInt16, value: AttributeDescription) in
            value.acronym == acr
        }?.value
    }
}
