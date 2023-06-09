//
//  S57FSPT.swift
//  S57Test
//
//  Created by Francisco Gorina Vanrell on 21/4/23.
//

import Foundation

public struct S57FSPT : Identifiable {
    public var name : [Byte]
    public var orientation : S57Orientation
    public var usageIndicator : S57Usage
    public var maskingIndicator : S57MaskingIndicator
    
    public var vector: S57Vector?
    
    public var id : UInt64 {
        
        var buf = name
        buf.append(contentsOf: [0, 0, 0])
        return UInt64(littleEndianBytes: buf)
   
    }

    init(name: [Byte], orientation: S57Orientation, usageIndicator: S57Usage,
         maskingIndicator: S57MaskingIndicator,
         vector: S57Vector?) {
        self.name = name
        self.orientation = orientation
        self.usageIndicator = usageIndicator
        self.maskingIndicator = maskingIndicator
        self.vector = vector
    }

    
    init(_ item : Values ){
        
        name = item.NAME as! [Byte]
        orientation = S57Orientation(rawValue: (item.ORNT as! UInt8?) ?? 255) ?? S57Orientation.null
        usageIndicator = S57Usage(rawValue: (item.USAG as! UInt8?) ?? 255) ?? S57Usage.null
        maskingIndicator = S57MaskingIndicator(rawValue: (item.MASK as! UInt8?) ?? 255) ?? S57MaskingIndicator.null
    }
}

