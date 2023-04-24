//
//  AttributeValues.swift
//  S57Test
//
//  Created by Francisco Gorina Vanrell on 22/4/23.
//

import Foundation

struct ExpectedInputCatalog {
    
    struct AttributeInput {
        var attribute : UInt16
        var value : UInt16
        var meaning : String
        
        var id : UInt32 {
            return (UInt32(attribute) << 16) | UInt32(value)
        }
        
        init(row : [String]) throws{
            do {
                attribute = try UInt16(row[0]) ?! SomeErrors.encodingError
                value = try UInt16(row[1]) ?! SomeErrors.encodingError
                meaning = row[2]
            }catch{
                print(error)
                throw(error)
            }
        }
    }
    
    var values : [UInt32: AttributeInput] = [:]

       
        init(rows : [[String]]){
            
            values = [:]
            
            for row in rows{
                if row.count == 3 {
                    if let att = try? AttributeInput(row: row){
                        values[att.id] = att
                    }
                }
            }
        }
        
        init (url : URL) throws{
            let csv = try CSVData(url: url, separator: ",", encoding: .isoLatin1)
            self.init(rows : csv.rows)
        }

    func valueForAttribute(_ att : UInt16, code : UInt16) -> AttributeInput?{
        let id = (UInt32(att) << 16) | UInt32(code)
        
        return values[id]
    }
    
    func valueForAttribute(_ att : UInt16, value : String) -> AttributeInput?{
        if let someCode = UInt16(value){
            let id = (UInt32(att) << 16) | UInt32(someCode)
            return values[id]
        }else{
            return nil
        }
    }
    
    func valuesForAtribute(_ att : UInt16) -> [AttributeInput]{
        
        return Array<AttributeInput>(values.filter{ (key, value) in value.attribute == att}
            .map { (key, value) in
                value
            })
        .sorted {( a1 : AttributeInput, a2 : AttributeInput) in
            a1.value < a2.value
        }
            
    }

}
