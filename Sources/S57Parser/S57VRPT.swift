//
//  S57VRPT.swift
//  S57Test
//
//  Created by Francisco Gorina Vanrell on 21/4/23.
//

import Foundation
enum S57Orientation : UInt8 {
    case forward = 1
    case reverse = 2
    case null = 255
}

enum S57Usage : UInt8 {
    case exterior = 1
    case interior = 2
    case exteriorTruncated = 3
    case null = 255
    
    var description : String {
        switch self {
        case .exterior:
            return "Exterior"
        case .interior:
            return "Interior"
        case .exteriorTruncated:
            return "Exterior Truncated"
        case .null:
            return "Null"
        }
    }
}

enum S57TopologyIndicator : UInt8 {
    case beginningNode = 1
    case endNode = 2
    case leftFace = 3
    case rightFace = 4
    case containingFace = 5
    case null = 255
}

enum S57MaskingIndicator : UInt8 {
    case mask = 1
    case show = 2
    case null = 255
}

struct S57VRPT : Identifiable{
    var name : [Byte]
    var orientation : S57Orientation
    var usageIndicator : S57Usage
    var topologyIndicator : S57TopologyIndicator
    var maskingIndicator : S57MaskingIndicator
    
    var vector : S57Vector?
    
    
    var id : UInt64 {
        
        var buf = name
        buf.append(contentsOf: [0, 0, 0])
        return UInt64(littleEndianBytes: buf)
    }

    init(name: [Byte], orientation: S57Orientation, usageIndicator: S57Usage,
         topologyIndicator: S57TopologyIndicator,
         maskingIndicator: S57MaskingIndicator,
         vector: S57Vector?) {
        self.name = name
        self.orientation = orientation
        self.usageIndicator = usageIndicator
        self.topologyIndicator = topologyIndicator
        self.maskingIndicator = maskingIndicator
        self.vector = vector
    }

    init(_ item : Values ){        
        name = item.NAME as! [Byte]
        orientation = S57Orientation(rawValue: (item.ORNT as! UInt8?) ?? 255) ?? S57Orientation.null
        usageIndicator = S57Usage(rawValue: (item.USAG as! UInt8?) ?? 255) ?? S57Usage.null
        topologyIndicator = S57TopologyIndicator(rawValue: (item.TOPI as! UInt8?) ?? 255) ?? S57TopologyIndicator.null
        maskingIndicator = S57MaskingIndicator(rawValue: (item.MASK as! UInt8?) ?? 255) ?? S57MaskingIndicator.null
    }
}

