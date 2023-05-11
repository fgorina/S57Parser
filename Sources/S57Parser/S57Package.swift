//
//  S57Package.swift
//  S57Test
//
//  Created by Francisco Gorina Vanrell on 24/4/23.
//

import Foundation
import MapKit


public class S57Package {
    
    public var url : URL       // URL of the folder containint the package
    
    public var catalog : [S57CatalogItem] = []
    public var currentItem : S57CatalogItem?
    public var currentFeatures : [UInt64 : S57Feature] = [:]
    public var currentFeatureClasses :  [(UInt16, String)] = []
    public var compilationScale : UInt32 = 0
    public var region : MKCoordinateRegion
    
    public init(url : URL) throws{
        
        self.url = url
        let catalogURL = url.appendingPathComponent("CATALOG.031")
        var parsedData = S57Parser(url: catalogURL)
        try parsedData.parse()
        catalog = parsedData.catalog.filter({ it in
            it.file.hasSuffix(".000")
        })
        if catalog.isEmpty{
            region = .world
        }else {
            let someRegion = catalog.first { item in
                item.region != nil
            }?.region! ?? MKCoordinateRegion.emptyRegion
            
            region = catalog.reduce(someRegion, { partialResult, item in
                if let reg = item.region {
                    return reg.union(partialResult)
                }else{
                    return partialResult
                }
            })
        }
        
    }
    public func add(item: S57CatalogItem) throws {
        // Split file into items
        var separator = "/"
        if item.file.contains("/"){
            separator = "/"
        }else if item.file.contains("\\"){
            separator = "\\"
        }
        
        let components = item.file.components(separatedBy: separator)
        var url = url
        for component in components{
            url = url.appendingPathComponent(component)
        }
        var parsedData = S57Parser(url: url)
        try parsedData.parse(false) // Just to not use a securityScopedURL

        for (key, feature) in parsedData.features {
            if currentFeatures[key] == nil {
                currentFeatures[key] = feature
            }
            
        }
        
        for item in parsedData.featureClasses {
            if !currentFeatureClasses.contains(where: { someItem in
                someItem.0 == item.0
            }){
                currentFeatureClasses.append(item)
            }
        }
        
        if parsedData.compilationScale < compilationScale{
            compilationScale = parsedData.compilationScale
        }
    }
    public func select(item : S57CatalogItem) throws {
        self.currentItem = item
        
        // Split file into items
        var separator = "/"
        if item.file.contains("/"){
            separator = "/"
        }else if item.file.contains("\\"){
            separator = "\\"
        }
        
        let components = item.file.components(separatedBy: separator)
        var url = url
        for component in components{
            url = url.appendingPathComponent(component)
        }
        var parsedData = S57Parser(url: url)
        try parsedData.parse(false) // Just to not use a securityScopedURL
        currentFeatures = parsedData.features
        currentFeatureClasses = parsedData.featureClasses
        compilationScale = parsedData.compilationScale
    }
    
    public func featuresIntersect(_ rect : MKMapRect) -> [S57Feature]{
        return currentFeatures.filter { (key: UInt64, value: S57Feature) in
            if let region = value.region{
                if value.prim == .point{
                    return rect.contains(MKMapPoint(region.center))
                 }else{
                    return region.mapRect.intersects(rect)
                }
            }
            return false
        }.map { (key: UInt64, value: S57Feature) in
            return value
        }
    }
}
