//
//  FFTP.swift
//  S57Test
//
//  Created by Francisco Gorina Vanrell on 21/4/23.
//

import Foundation

public enum S57Relationship : UInt8 {
    case master = 1
    case slave = 2
    case peer = 3
    case null = 255
    
    public var description : String {
        switch self {
        case .master :
            return "Master"

        case .slave:
            return "Slave"

        case .peer:
            return "Peer"

        case .null:
            return "Null"

        }
        
    }
    
}


public struct S57FFPT : Identifiable{
    public var longName : [UInt8]
    public var relationshipIndicator : S57Relationship
    public var comment : String
    
    public var id : UInt64 {
        return UInt64(littleEndianBytes: longName)
    }
    
    public var feature : S57Feature?
    
    init(longName : [UInt8], relationshipIndicator : S57Relationship, comment: String, feature : S57Feature?){
        self.longName = longName
        self.relationshipIndicator = relationshipIndicator
        self.comment = comment
        self.feature = feature
    }

    init(_ item : Values ){
        
        longName = item.LNAM as! [Byte]
        comment = item.COMT as! String
        
        relationshipIndicator = S57Relationship(rawValue: (item.RIND as! UInt8?) ?? 255) ?? S57Relationship.null
        
    }
}
    
