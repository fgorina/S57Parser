//
//  S57Package.swift
//  S57Test
//
//  Created by Francisco Gorina Vanrell on 24/4/23.
//

import Foundation


class S57Package {
    
    var url : URL       // URL of the folder containint the package
    
    var catalog : [S57CatalogItem] = []
    var currentItem : S57CatalogItem?
    var currentFeatures : [UInt64 : S57Feature] = [:]
    var currentFeatureClasses :  [(UInt16, String)] = []
    
    init(url : URL) throws{
        
        self.url = url
        let catalogURL = url.appendingPathComponent("CATALOG.031")
        var parsedData = S57Parser(url: catalogURL)
        try parsedData.parse()
        catalog = parsedData.catalog
        
    }
    
    func select(item : S57CatalogItem) throws {
        self.currentItem = item
        let url = url.appendingPathComponent(item.file)
        var parsedData = S57Parser(url: url)
        try parsedData.parse()
        currentFeatures = parsedData.features
        currentFeatureClasses = parsedData.featureClasses
    }
    
    
}
