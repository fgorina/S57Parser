//
//  S57Attribute.swift
//  S57Test
//
//  Created by Francisco Gorina Vanrell on 22/4/23.
//

import Foundation

public struct S57Attribute : Identifiable {
    
    public var attribute : UInt16
    public var decodedAttribute : String?
    
    public var value : String
    public var decodedValue : String?
    
    public var id : UInt16 { attribute}
    
    init(attribute : UInt16, value : String, attributeCatalog : AttributeCatalog?, expectedInputCatalog : ExpectedInputCatalog?){
        
        self.attribute = attribute
        if let attCat = attributeCatalog{
            self.decodedAttribute = attCat.attributeForCode(attribute)?.attribute ?? "*** \(attribute) ***"
        }else{
            self.decodedAttribute = "*** \(attribute) ***"
        }
        
        self.value = value
        
        let someValues = value.split(separator: ",")
        
        if someValues.count > 1{
            print ("Hola")
        }
        
        if let expCatalog = expectedInputCatalog{
            var decoded = ""
            for aValue in someValues {
                decoded = decoded + (!decoded.isEmpty ? ", " : "") + (expCatalog.valueForAttribute(attribute, value: value)?.meaning ?? String(aValue))
                
            }
            self.decodedValue = decoded
        }else{
            self.decodedValue = value
        }
        
        
        
    }
}
