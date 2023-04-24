//
//  S57Attribute.swift
//  S57Test
//
//  Created by Francisco Gorina Vanrell on 22/4/23.
//

import Foundation

struct S57Attribute : Identifiable {
    
    var attribute : UInt16
    var decodedAttribute : String?
    
    var value : String
    var decodedValue : String?
    
    var id : UInt16 { attribute}
    
    init(attribute : UInt16, value : String, attributeCatalog : AttributeCatalog?, expectedInputCatalog : ExpectedInputCatalog?){
        
        self.attribute = attribute
        if let attCat = attributeCatalog{
            self.decodedAttribute = attCat.attributeForCode(attribute)?.attribute ?? "*** \(attribute) ***"
        }else{
            self.decodedAttribute = "*** \(attribute) ***"
        }
        
        self.value = value
        
        if let expCatalog = expectedInputCatalog{
            self.decodedValue = expCatalog.valueForAttribute(attribute, value: value)?.meaning ?? value
        }else{
            self.decodedValue = value
        }
        
        
        
    }
}
