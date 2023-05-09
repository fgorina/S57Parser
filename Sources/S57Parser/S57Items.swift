//
//  S57Items.swift
//  S57Test
//
//  Created by Francisco Gorina Vanrell on 24/4/23.
//

import Foundation

//MARK: - Intermediate Structures

@dynamicMemberLookup
public struct Values : Identifiable{
    public var id : UUID = UUID()
    
    public var properties : [String : Any]
    subscript(dynamicMember member: String) -> Any?{
        return properties[member]
    }
    
    public var description : String {
        
        properties.map { (key: String, value: Any) in
            "\(key) : \(value)"
        }.joined(separator: "\n")
    }
    
}

@dynamicMemberLookup
public struct DataItemField : Identifiable {
    
    public  var id : String {"\(tag)\(name)"}
    public var tag : String
    public var name : String
    public var properties : [Values] = []      // En cas de No repeatSubfields aleshores te un sols element
    public subscript(dynamicMember member: String) -> Any?{
        if properties.count == 1{
            return properties[0].properties[member]
        }else{
            return nil
        }
    }
    
    public subscript(index: Int) -> Values? {
        if index >= 0 && index < properties.count {
            return properties[index]
        }else{
            return nil
        }
    }

}

public struct RecordId : Equatable, Comparable{
    public static func < (lhs: RecordId, rhs: RecordId) -> Bool {
        if lhs.rcnm != rhs.rcnm{
            return lhs.rcnm < rhs.rcnm
        }else{
            return lhs.rcid < rhs.rcid
        }
    }
    
    public var rcnm : UInt8
    public var rcid : UInt32
    
    static let rcnmConversion : [String : UInt8] =
    [
        "DS" : 10,
        "DP" : 20,
        "DH" : 30,
        "DA" : 40,
        "CD" : 0,
        "CR" : 60,
        "ID" : 70,
        "IO" : 80,
        "IS" : 90,
        "FE" : 100,
        "VI" : 110,
        "VC" : 120,
        "VE" : 130,
        "VF" : 140
    ]
    
    init(rcnm : UInt8, rcid: UInt32){
        self.rcnm = rcnm
        self.rcid = rcid
    }
    
    init(rcnm : String, rcid: String){
        // Convrsion table from 2.2.1 in S-57 document
        
        if let ircnm = RecordId.rcnmConversion[rcnm]{
            self.rcnm = ircnm
        }else{
            self.rcnm = 0
        }
        self.rcid = UInt32(rcid) ?? 0
    }


    static var empty : RecordId {RecordId(rcnm: 0, rcid: 0)}
}

@dynamicMemberLookup
public struct DataItem : Identifiable{
    
    public var recordId : Int = 0
    public var isLeader : Bool = false
    public var fields : [String : DataItemField] = [:]
    public var id : Int {recordId}
    public var keyField : String = "0001"
    
    public var uniqueId : RecordId

    subscript(dynamicMember member: String) -> DataItemField?{
        return fields[member]
    }

    public var name : UInt64{
        
        let rcnm = fields[keyField]!.RCNM as! UInt8
        let rcid = fields[keyField]!.RCID as! UInt32
        
        var bytes = [rcnm]
        bytes.append(contentsOf: rcid.toBytes)
        bytes.append(0)
        bytes.append(0)
        
        return UInt64(Byte(littleEndianBytes: bytes))
    }
    
    
    //var names : String {fields.lazy.map{$0.0}.joined(separator: ",")}
    public var names : String { "\(keyField) : \(uniqueId)" }
    init(_ record : S57Parser.DataRecord){
        isLeader = record.header.leaderIdentifier == "L"
        let srecordId = (record.fields.first(where: { field in
            field.tag == "0001"
        })?.subfields[0] ?? "" )
        
        if let ssrecordId = srecordId as? String {
            recordId = Int(ssrecordId) ?? -1
        }else if let irecordId = srecordId as? UInt16 {
            recordId = Int(irecordId)
        }else if let irecordId = srecordId as? Int16 {
            recordId = Int(irecordId)
        }else{
            recordId = -1
        }
        
        
        for f in record.fields {
            
            let tag = f.tag
            let name = record.lead.fieldTypes[tag]?.name ?? ""
            var someSubfields: [Values] = []
            
            for i in stride(from: 0, to: f.subfields.count, by: f.fieldType.subfields.count) {
                var subfieldValues : Values = Values(properties: [:])
                
                for j in 0..<f.fieldType.subfields.count {
                    let value = f.subfields[i+j]
                    let tag = f.fieldType.subfields[j].tag
                    let s = value
                    subfieldValues.properties[tag] = s
                }
                someSubfields.append(subfieldValues)
            }
            let f = DataItemField(tag: tag, name: name, properties: someSubfields)
            fields[tag] = f
        }
        
        uniqueId = RecordId.empty
        for (tag, field) in fields{
            if tag.hasSuffix("ID") || tag == "CATD"{
                
                if let rcnm = field.RCNM as? UInt8{
                    if let rcid = field.RCID as? UInt32{
                        keyField = tag
                        uniqueId = RecordId(rcnm: rcnm, rcid: rcid)
                     }
                }else if let rcnm = field.RCNM as? String{
                    if let rcid = field.RCID as? String{
                        keyField = tag
                        uniqueId = RecordId(rcnm: rcnm, rcid: rcid)
                     }
                }
            }
        }
        
    }
}
