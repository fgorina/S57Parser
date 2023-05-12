//
//  S57Package.swift
//  S57Test
//
//  Created by Francisco Gorina Vanrell on 24/4/23.
//

import Foundation
import MapKit

public class S57TileNode {
    var item : S57CatalogItem?
    var region : MKCoordinateRegion
    var children :[S57TileNode] = []
    
    init(item : S57CatalogItem? , region : MKCoordinateRegion, children: [S57TileNode] = []){
        self.item = item
        self.region = region
        self.children = children
    }
    
    func add(_ newItem : S57CatalogItem){
        
        if !region.mapRect.contains(newItem.region!.mapRect){   // Nothing to do. Probably an error or is outside the place
            return
        }
        
        var done = false
        
        for child in children{
            if child.region.mapRect.contains(newItem.region!.mapRect){
                child.add(newItem)
                done = true
                break
            }
        }
        
        if !done {
            let newNode = S57TileNode(item : newItem, region: newItem.region!)
            children.append(newNode)
        }
        
    }
    
    func firstTileThatContainsRegion(_ region : MKCoordinateRegion) -> S57TileNode?{
        if region.mapRect.contains(region.mapRect){
            for child in children {
                if let target = child.firstTileThatContainsRegion(region){
                    return target
                }
            }
            
            return self
            
        }else{
            return nil
        }
    }
}

public class S57Package {
    
    public var url : URL       // URL of the folder containint the package
    
    public var catalog : [S57CatalogItem] = []
    public var currentItem : [S57CatalogItem] = []
    public var currentFeatures : [UInt64 : S57Feature] = [:]
    public var currentFeatureClasses :  [(UInt16, String)] = []
    public var compilationScale : UInt32 = 0
    public var region : MKCoordinateRegion
    public var tree : S57TileNode = S57TileNode(item: nil, region: MKCoordinateRegion.world)
    
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
        
        tree = createTree()
        
    }
    
    func createTree() -> S57TileNode{
        var firstNode = S57TileNode(item: nil, region: MKCoordinateRegion.world)
        
        var orderedItems = catalog.sorted { item1, item2 in
            item1.region!.area > item2.region!.area
        }
        
        for item in orderedItems {
            firstNode.add(item)
         }
        
        return firstNode
    }
    
    // Bool returns true if some changes has been made
    
    public func selectForRegion(_ region : MKCoordinateRegion) throws -> Bool{
        
        var selectedItems : [S57CatalogItem] = []
        
        if let tile = tree.firstTileThatContainsRegion(region){
            if let topItem = tile.item{
                selectedItems.append(topItem)
            }
            for child in tile.children{
                if let item = child.item{
                    selectedItems.append(item)
                }
            }
        }
  
        
        // Now try tyop detect changes
        
        var changes = false
        
        for item in currentItem{
            if !selectedItems.contains(where: { i in
                i.id == item.id
            }){
                changes = true
            }
        }
        
        if !changes {
            for item in selectedItems{
                if !currentItem.contains(where: { i in
                    i.id ==  item.id
                }){
                    changes = true
                }
            }
        }
        
        if changes && !selectedItems.isEmpty{    // Rebuild Features
            
            try select(item: selectedItems[0])
            
            for i in 1..<selectedItems.count{
                try add(item: selectedItems[i])
            }
            
            return true
            
        }else{
            return false
        }
        
    }
    
    
    public func add(item: S57CatalogItem) throws {
        
        if self.currentItem.contains(where: { someItem in
            item.id == someItem.id
        }){
            return
        }
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
        
        self.currentItem.append(item)
    }
    
    public func select(item : S57CatalogItem) throws {
        self.currentItem = [item]
        
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
