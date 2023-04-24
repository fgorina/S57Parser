//
//  ObjectCatalog.swift
//  S57Test
//
//  Created by Francisco Gorina Vanrell on 21/4/23.
//

import Foundation

public struct ObjectCatalog{
    
    public struct ObjectDescription {
        
        var code : UInt16
        var objectClass : String
        var acronym : String
        var attributeA : [String]
        var attributeB : [String]
        var attributeC : [String]
        var classType : String
        var primitives : [String]

        init(row : [String]) throws{
            
            code = try UInt16(row[0]) ?! SomeErrors.encodingError
            objectClass = row[1]
            acronym = row[2]
            attributeA = row[3].split(separator: ";").map({String($0)})
            attributeB = row[4].split(separator: ";").map({String($0)})
            attributeC = row[5].split(separator: ";").map({String($0)})
            classType = row[6]
            if row.count > 7{
                primitives = row[7].split(separator: ";").map({String($0)})
            } else {
                primitives = []
            }
        }
    }
    
    private var objects : [UInt16 : ObjectDescription] = [:]
    
    init(rows : [[String]]){
        
        for row in rows{
            if row.count >= 7 {
                if let obj = try? ObjectDescription(row: row){
                    objects[obj.code] = obj
                }
            }else {
                print("Not correct count \(row.count)")
            }
        }
    }
    
    init (url : URL) throws{
        let csv = try CSVData(url: url, separator: ",")
        self.init(rows : csv.rows)
    }
    
    func objectForCode(_ i : UInt16) -> ObjectDescription?{
        return objects[i]
    }
    
    func objectForAcronym(_ acr : String)  -> ObjectDescription?{
        return objects.first { (key: UInt16, value: ObjectDescription) in
            value.acronym == acr
        }?.value
    }
}
