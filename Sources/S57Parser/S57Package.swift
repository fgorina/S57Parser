//
//  S57Package.swift
//  S57Test
//
//  Created by Francisco Gorina Vanrell on 24/4/23.
//

import Foundation


public class S57Package {
    
    public var url : URL       // URL of the folder containint the package
    
    public var catalog : [S57CatalogItem] = []
    public var currentItem : S57CatalogItem?
    public var currentFeatures : [UInt64 : S57Feature] = [:]
    public var currentFeatureClasses :  [(UInt16, String)] = []
    
    public init(url : URL) throws{
        
        self.url = url
        let catalogURL = url.appendingPathComponent("CATALOG.031")
        var parsedData = S57Parser(url: catalogURL)
        try parsedData.parse()
        catalog = parsedData.catalog
        
    }
    
    public func select(item : S57CatalogItem) throws {
        self.currentItem = item
        let url = url.appendingPathComponent(item.file)
        var parsedData = S57Parser(url: url)
        try parsedData.parse()
        currentFeatures = parsedData.features
        currentFeatureClasses = parsedData.featureClasses
    }
    
    
}
