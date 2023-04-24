//
//  S55Parser.swift
//  S55Parser
//
//  Created by Francisco Gorina Vanrell on 18/4/23.
//

import Foundation
import MapKit

let eof : Byte = 0x1f
let eor : Byte = 0x1e

//MARK: - S57 Parser

public struct S57Parser{
    
    public enum S57Errors : Error {
        
        case DataStructureCodeInvalid
        case DataTypeCodeInvalid
        case NotANumber
        case InexistentTag
        case UnableToCreateStream
        
    }
    
    
    
    public enum FieldTypes {
        case UInt8
        case UInt16
        case UInt32
        case Int8
        case Int16
        case Int32
        case String
        case Array
    }
    
    public enum DataStructureCode : String {
        case noStructure = "0"
        case linearStructure = "1"
        case multiDimensionalStructure = "2"
    }
    
    public enum DataTypeCode : String {
        case string = "0"
        case integer = "1"
        case binary = "5"
        case mixed = "6"
    }
    
    public struct FieldControl {
        var parent : String
        var child : String
        
        var description : String {
            "Field Control Parent : \(parent) Child: \(child)"
        }
    }
    
    public struct DirEntry {
        public var tag : String
        public var length : Int
        public var position : Int
        
        public var description : String {
            
            "Dir Entry Tag : \(tag) Length: \(length) Position : \(position)"
        }
        
        init(_ s : [Byte] , sot : Int, sol : Int, sop : Int){
            
            tag = String(bytes: s[0..<sot], encoding: .isoLatin1) ?? ""
            length = Int( String(bytes: s[sot..<(sot + sol)], encoding: .isoLatin1) ?? "") ?? 0
            position = Int(String(bytes: s[(sot + sol)..<(sot + sol + sop)], encoding: .isoLatin1) ?? "") ?? 0
            
        }
    }
    
    public struct SubFieldType {
        public var kind : FieldTypes
        public var size : Int
        public var tag : String
        
        public var description : String {
            "Tag: \(tag) Type : \(kind) Size: \(size)"
        }
    }
    
    public  struct FieldType {
        public var tag : String
        public var length : Int
        public var position : Int
        public var dataStructure : DataStructureCode
        public var dataType : DataTypeCode
        public var auxiliaryControls : String
        public var printableFt : String
        public var printableUt : String
        public var escapeSeq : String
        public var name : String
        public var arrayDescriptor : String
        public var formatControls : String = ""
        public var repeatSubfields : Bool = false
        public var subfields : [SubFieldType] = []
        
        init?(tag: String, length : Int, position : Int , bytes : [Byte]) throws{
            
            self.tag = tag
            self.length = length
            self.position = position
            
            dataStructure = try DataStructureCode(rawValue: bytes[0..<1].stringValue()) ?!  S57Errors.DataStructureCodeInvalid
            dataType = try DataTypeCode(rawValue: bytes[1..<2].stringValue()) ?! S57Errors.DataTypeCodeInvalid
            auxiliaryControls = bytes[2..<4].stringValue()
            printableFt = bytes[4..<5].stringValue()
            printableUt = bytes[5..<6].stringValue()
            escapeSeq = bytes[6..<9].stringValue()
            
            let fdata = Array<Byte>(bytes[9..<length])
            
            let desc = fdata.splits(eof)
            
            name = try desc[0].stringValue()
            arrayDescriptor = try desc[1].stringValue().replacingOccurrences(of: "\u{1e}", with: "")
            if desc.count > 2 {
                formatControls = try desc[2].stringValue().replacingOccurrences(of: "\u{1e}", with: "")
            }
            
            try buildSubFields()
        }
        
        var description : String {
            var s = "Field Type \(tag) Name \(name) Array Descriptor \(arrayDescriptor)  dataStructure: \(dataStructure) dataType: \(dataType) formatControls \(formatControls) \n Sub Fields\(repeatSubfields ?  " *" : "")\n"
            
            for sf in subfields{
                s += "\(sf.description) \n"
            }
            
            return s
        }
        
        mutating func buildSubFields() throws{
            
            if arrayDescriptor.isEmpty {
                arrayDescriptor = "    "
            }
            
            if formatControls.count > 2 {
                if arrayDescriptor[0] == "*"{
                    repeatSubfields = true
                    
                }
                var tags : [String]
                if repeatSubfields {
                    tags = arrayDescriptor[1...].split(separator: "!").map({ s in
                        String(s)
                    })
                }else{
                    tags = arrayDescriptor.split(separator: "!").map({ s in
                        String(s)
                    })
                }
                
                var tagidx = 0
                
                var types : [SubFieldType] = []
                
                let all = try formatControls.allMatchesForRegex(#"(\d*)(\w+)\(*(\d*)\)*"#)
                
                for a in  all{
                    
                    var i = 1
                    
                    if !a[1].isEmpty {
                        i = try Int(a[1]) ?! S57Errors.NotANumber
                    }
                    
                    var size = 0
                    if !a[3].isEmpty {
                        size = try Int(a[3]) ?! S57Errors.NotANumber
                    }
                    
                    for _ in stride( from: i,  to:0, by: -1) {
                        switch a[2][0]{
                        case "A":
                            types.append(SubFieldType(kind: .String, size: size, tag: String(tags[tagidx])))
                            
                        case "I":
                            types.append(SubFieldType(kind: .String, size: size, tag: String(tags[tagidx])))
                            
                        case "R":
                            types.append(SubFieldType(kind: .String, size: size, tag: String(tags[tagidx])))
                            
                            
                        case "B":
                            types.append(SubFieldType(kind: .Array, size: size / 8, tag: String(tags[tagidx])))
                            
                        case "b":
                            
                            switch String(a[2][1...]){
                                
                            case "11":
                                types.append(SubFieldType(kind: .UInt8, size: 1, tag: String(tags[tagidx])))
                                
                            case "12":
                                types.append(SubFieldType(kind: .UInt16, size: 2, tag: String(tags[tagidx])))
                                
                            case "14":
                                types.append(SubFieldType(kind: .UInt32, size: 4, tag: String(tags[tagidx])))
                                
                            case "21":
                                types.append(SubFieldType(kind: .Int8, size: 1, tag: String(tags[tagidx])))
                                
                            case "22":
                                types.append(SubFieldType(kind: .Int16, size: 2, tag: String(tags[tagidx])))
                                
                            case "24":
                                types.append(SubFieldType(kind: .Int32, size: 4, tag: String(tags[tagidx])))
                                
                            default:
                                break
                                
                            }
                        default:
                            break
                        }
                        tagidx += 1
                    }
                }
                
                subfields = types
            }
        }
        
        func decode(_ stream : BufferedInputStream, length: Int, encoding : String.Encoding) throws -> [Any] {
            var values : [Any] = []
            
            // Copy buffer
            if subfields.count == 0{
                return []
            }
            
            var n = length
            
            
            while stream.hasBytesAvailable && n > 1{        // Check if it is OK. I don't see it
                for ftype in subfields {
                    switch ftype.kind{
                        
                    case .UInt8:
                        let v : UInt8 = try stream.readUInt8()
                        values.append(v)
                        n -= 1
                    case .UInt16:
                        let v : UInt16 = try stream.readUInt16()
                        values.append(v)
                        n -= 2
                        
                    case .UInt32:
                        let v : UInt32 = try stream.readUInt32()
                        values.append(v)
                        n -= 4
                        
                    case .Int8:
                        let v : Int8 = try stream.readInt8()
                        values.append(v)
                        n -= 1
                        
                    case .Int16:
                        let v : Int16 = try stream.readInt16()
                        values.append(v)
                        n -= 2
                        
                    case .Int32:
                        let v : Int32 = try stream.readInt32()
                        values.append(v)
                        n -= 4
                                
                    case .Array:
                        if ftype.size == 0{
                            print("Hello")
                        }
                        let v : [Byte] = try stream.readBytes(length: ftype.size)
                        values.append(v)
                        n -= ftype.size
                        
                        
                    default:
                        if ftype.size == 0{
                            let (v, l) = try stream.readString(until: [eor, eof], encoding: encoding)
                            values.append(v)
                            n -= (l+1)
                        }else{
                            let  v = try stream.readString(length: ftype.size, encoding: encoding)

                            values.append(v)
                            n -= ftype.size
                        }
                    }
                }
                
            }
            return values
        }
    }
    
    public struct Field {
        public var tag : String
        public var length : Int
        public var position : Int
        public var fieldType : FieldType
        public var subfields : [Any] = []
        
        init(tag: String, length: Int, position: Int, fieldType: FieldType, stream: BufferedInputStream, encoding: String.Encoding) throws{
            self.tag = tag
            self.length = length
            self.position = position
            self.fieldType = fieldType
            

            subfields = try fieldType.decode(stream, length : length-1, encoding: encoding)
        }
        
        var description : String {
            var out = "Field \(tag) length \(length) position \(position) field type \(fieldType.name) \n"
            for i in  0..<subfields.count{
                if i % fieldType.subfields.count == 0{
                    out = out + "    --------------------------\n"
                }
                let someTag = fieldType.subfields[i % fieldType.subfields.count].tag
                out = out + "    \(someTag) : \(subfields[i]) \n"
                
            }
            
            return out
        }
    }
    
    public struct Header {
        public var recordLength : Int
        public var interchangeLevel : String
        public var leaderIdentifier : String
        public var inLineCodeExtensionIndicator : String
        public var versionNumber : String
        public var applicationIndicator: String
        public var fieldControlLength : String
        public var baseAddressOfFieldArea : Int
        public var extendedCharacterIndicator : String
        public var sizeOfFieldLength : Int
        public var sizeOfFieldPosition : Int
        public var reserved : String
        public var sizeOfFieldTag : Int
        public var entries : [DirEntry] = []
        
        
        
        init(_ stream : BufferedInputStream) throws {
            
            recordLength = try stream.readStringInt(length: 5)
            interchangeLevel = try stream.readString(length: 1)
            leaderIdentifier = try stream.readString(length: 1)
            inLineCodeExtensionIndicator = try stream.readString(length: 1)
            versionNumber = try stream.readString(length: 1)
            applicationIndicator = try stream.readString(length: 1)
            fieldControlLength = try stream.readString(length: 2)
            baseAddressOfFieldArea = try stream.readStringInt(length: 5)
            extendedCharacterIndicator = try stream.readString(length: 3)
            
            sizeOfFieldLength = try stream.readStringInt(length: 1)
            sizeOfFieldPosition = try stream.readStringInt(length: 1)
            reserved =  try stream.readString(length: 1)
            sizeOfFieldTag = try stream.readStringInt(length: 1)
            
            // Count number of entries :
            
            let entrySize = sizeOfFieldLength + sizeOfFieldPosition + sizeOfFieldTag
            let n = (baseAddressOfFieldArea - 1 - 24) / entrySize
            
            for _ in 0..<n {
                let entry = DirEntry(try stream.readBytes(length: entrySize),
                                     sot: sizeOfFieldTag ,
                                     sol: sizeOfFieldLength,
                                     sop: sizeOfFieldPosition)
                
                entries.append(entry)
            }
            
            let sep = try stream.readBytes(length: 1)[0]   // Jump eof
            if sep != eor {
                stream.pushBack(sep)
            }else {
                //print("Killing eor for header")
            }

            
        }
        
        
        public var description : String {
            var output = (
            """
Header :

         recordLength : \(recordLength)
         interchangeLevel : \(interchangeLevel)
         leaderIdentifier : \(leaderIdentifier)
         inLineCodeExtensionIndicator : \(inLineCodeExtensionIndicator)
         versionNumber : \(versionNumber)
         applicationIndicator: \(applicationIndicator)
         fieldConrolLength : \(fieldControlLength)
         baseAddressOfFieldArea : \(baseAddressOfFieldArea)
         extendedCharacterIndicator : \(extendedCharacterIndicator)
         sizeOfFieldLength : \(sizeOfFieldLength)
         sizeOfFieldPosition : \(sizeOfFieldPosition)
         reserved : \(reserved)
         sizeOfFieldtag : \(sizeOfFieldTag)

    Directory Entries

""")
            
            for entry in entries {
                output = output + "\(entry.description)\n"
            }
            
            return output
            
        }
        
    }
    
    public class LeadRecord {
        public var header : Header
        public var fieldTypes : [String : FieldType] = [:]
        public var fieldControlField : [FieldControl] = []
        var baseAddressOfData : Int {
            header.baseAddressOfFieldArea + header.entries.reduce(0, { acum, dirEntry in
                acum + dirEntry.length
            })
        }
        
        init(_ stream : BufferedInputStream) throws{
            header = try Header(stream)
            
            for entry in header.entries{
               
                let bytes = try stream.readBytes(length: entry.length)
                let field = try FieldType(tag: entry.tag, length: entry.length, position: entry.position, bytes:  bytes)
                fieldTypes[entry.tag] = field
            }
            
            // Parse FieldControls
            
            if let type = fieldTypes["0000"] {
                let data = type.arrayDescriptor.splitEvery(4)
                fieldControlField = stride(from: 0, to: data.count, by:2).map{
                    FieldControl(parent: data[$0], child: data[$0+1])
                }
            }
        }
        
        var description : String {
            
            var out = header.description
            out = out + "    Control Fields\n"
            for cf in fieldControlField {
                
                out += "\(cf.description)\n"
                
            }
            out = out + "    Field Types\n"
            for (_, field) in fieldTypes {
                
                out = out + "\(field.description)\n"
            }
            
            return out
        }
        
    }
    
    public struct DataRecord {
        public var header : Header
        public var lead: LeadRecord
        public var fields : [Field] = []
        
        public var length : Int {
            header.baseAddressOfFieldArea + fields.reduce(0, { acum, field in
                acum + field.length
            })
        }
        
        
        init(leadRecord : LeadRecord, stream: BufferedInputStream, aall : UInt8 = 1, nall : UInt8 = 1) throws{
            self.lead = leadRecord

            header = try Header(stream)
            
            for d in header.entries {
                let fieldType = try lead.fieldTypes[d.tag] ?! S57Errors.InexistentTag
                
                var encoding = String.Encoding.isoLatin1
                
                if d.tag == "ATTF"{
                    encoding = aall == 2 ? .utf16LittleEndian : .isoLatin1
                }
                
                if d.tag == "NATF"{
                    encoding = nall == 2 ? .utf16LittleEndian : .isoLatin1
                }

                let field = try Field(tag: d.tag, length: d.length, position: d.position, fieldType: fieldType, stream: stream, encoding: encoding)
                fields.append(field)
                
                // Sempre hi ha un eor (0x1E) al final del registre
                var sep = try stream.readBytes(length: 1)
                if sep[0] != eor{
                    stream.pushBack(sep[0])
                }
                // Quan està actiu el nivell 2 (chars de 16 bits) també hi ha un 0 adicional
                if encoding == .utf16LittleEndian{
                    sep = try stream.readBytes(length: 1)
                    if sep[0] != 0{
                        stream.pushBack(sep[0])
                    }

                }
                
            }
            // There should be a eor
            
            let sep = try stream.readBytes(length: 1)
            
            if sep[0] != eor {
                stream.pushBack(sep[0])
            }else {
               // print("Too many?")
            }
        }
        
        var description : String {
            
            var out : String = "============================================\nData Record : \n "
            
            out = out + header.description + "\n Fields \n"
            for field in fields{
                out = out + "\(field.description) \n"
            }
            
            return out
        }
    }
    
    func recordsWithTag(_ tag : String) -> [DataItem] {
        
        return items.filter { di in
            di.fields[tag] != nil
        }
    }
    
    public var url : URL?
    var stream : BufferedInputStream?
    
    public var leadRecord : LeadRecord?
    public var dataRecords : [DataRecord] = []
    public var items : [DataItem] = []

    public var parameters : DataItemField?
    public var structure : DataItemField?
    
    public var catalog : [S57CatalogItem] = []
    
    public var objectClasses : ObjectCatalog?
    public var attributeCatalog : AttributeCatalog?
    public var expectedInputCatalog : ExpectedInputCatalog?

    public var vectors : [UInt64 : S57Vector] = [:]
    public var features : [UInt64 : S57Feature] = [:]
    
    public var coordinateFactor : Double = 1.0        // COMF
    public var soundingFactor : Double = 1.0       // SOMF
    
    public var featureClasses : [(UInt16, String)] = []
    
    func vectorForVRPT(_ vrpt : S57VRPT) -> S57Vector?{
        return vectors[vrpt.id]
        
    }
    
    func vectorForFSPT(_ fspt : S57FSPT) -> S57Vector?{
        return vectors[fspt.id]
   }

    func coordinatesForVector(_ vector : S57Vector) -> [S57Coordinate]{
        
        var out : [S57Coordinate] = []
         
        // If Isolated no
        
        if  vector.recordPointers.count > 0 {
            // Lookup referenced vector
            if let referencedVector = vectorForVRPT(vector.recordPointers[0]) {
                if referencedVector.id != vector.id{    // Just to stop loops
                    out.append(contentsOf: coordinatesForVector(referencedVector))
                }
            }
        }
        
        for c in vector.coordinates{
            out.append(c)
        }
        
        if vector.recordPointers.count > 1 {
            if let referencedVector = vectorForVRPT(vector.recordPointers[1]){
                out.append(contentsOf: coordinatesForVector(referencedVector))
            }

        }
        
        return out
    }
    
    func coordinatesForFeature(_ feature : S57Feature) -> [S57Coordinate]{
        
        var out : [S57Coordinate] = []
         
        // If Isolated no
        
        for pt in feature.fspt {
            if pt.id != feature.id {    // Just to stop loops
                if let vector = vectorForFSPT(pt){
                    out.append(contentsOf: coordinatesForVector(vector))
                }
            }
        }
        
        return out
    }
    
    
    func dereferencedVRPT(_ vrpt  : S57VRPT, inProcessVector : [UInt64] = []) -> S57VRPT{
        
        if vrpt.vector != nil {
            return  vrpt
        }else{
            if !inProcessVector.contains(vrpt.id){
                var vector = vectors[vrpt.id]

                if vector != nil {
                    for i in 0..<vector!.recordPointers.count{
                        vector!.recordPointers[i] = dereferencedVRPT(vector!.recordPointers[i], inProcessVector: inProcessVector + [vector!.id])
                        
                    }
                }
                return S57VRPT(name: vrpt.name, orientation: vrpt.orientation, usageIndicator: vrpt.usageIndicator,
                               topologyIndicator: vrpt.topologyIndicator, maskingIndicator: vrpt.maskingIndicator, vector: vector)
            } else {
                return vrpt
            }
        }
    }
    
    func dereferenceFSPT(_ fspt  : S57FSPT, inProcessVector : [UInt64] = []) -> S57FSPT{
        
        if fspt.vector != nil {
            return  fspt
        }else{
            if !inProcessVector.contains(fspt.id){
                var vector = vectors[fspt.id]

                if vector != nil {
                    for i in 0..<vector!.recordPointers.count{
                        vector!.recordPointers[i] = dereferencedVRPT(vector!.recordPointers[i], inProcessVector: inProcessVector + [vector!.id])
                        
                    }
                }
                return S57FSPT(name: fspt.name, orientation: fspt.orientation, usageIndicator: fspt.usageIndicator,
                                maskingIndicator: fspt.maskingIndicator, vector: vector)
            } else {
                return fspt
            }
        }
    }

    func dereferenceFFPT(_ ffpt  : S57FFPT, inProcessVector : [UInt64] = []) -> S57FFPT{
        
        if ffpt.feature != nil {
            return  ffpt
        }else{
            if !inProcessVector.contains(ffpt.id){
                var feature = features[ffpt.id]

                if feature != nil {
                    for i in 0..<feature!.ffpt.count{
                        feature!.ffpt[i] = dereferenceFFPT(feature!.ffpt[i], inProcessVector: inProcessVector + [feature!.id])
                    }
                }
                return S57FFPT(longName: ffpt.longName, relationshipIndicator: ffpt.relationshipIndicator, comment: ffpt.comment, feature: feature)
            } else {
                return ffpt
            }
        }
    }

    

    mutating func dereferenceVectors(){
        for key in vectors.keys{
            var v = vectors[key]!
            v.recordPointers = v.recordPointers.map({ vrpt in
                dereferencedVRPT(vrpt, inProcessVector: [v.id])
            })
            vectors[key] = v
        }
    }
      
    mutating func dereferenceFeatures(){
        for key in features.keys{
            var f = features[key]!
            
             f.fspt = f.fspt.map({ fspt in
                dereferenceFSPT(fspt, inProcessVector: [])
            })
            features[key] = f
        }
        
        for key in features.keys{
            var f = features[key]!
   
            f.ffpt = f.ffpt.map({ ffpt in
                dereferenceFFPT(ffpt, inProcessVector: [f.id])
            })
            
            features[key] = f
        }
    }

    mutating func buildFeaturetClasses() {
        featureClasses = []
        
        for f in features.values {
            
            let item = (f.objl, f.decodedObjl ?? "")
            
            if !featureClasses.contains(where: {
                $0.0 == item.0 &&  $0.1 == item.1
            }) {
                featureClasses.append(item)
            }
        }
        featureClasses.sort { t1, t2 in
            t1.1 < t2.1
        }
        
        
    }
    
    public mutating func parse() throws{
        if let objectClassesUrl = Bundle.module.url(forResource: "s57objectclasses", withExtension: "csv") {
            objectClasses = try? ObjectCatalog(url: objectClassesUrl)
        }
        if let attributesUrl = Bundle.module.url(forResource: "s57attributes", withExtension: "csv") {
            attributeCatalog = try? AttributeCatalog(url: attributesUrl)
        }
        if let expectedUrl = Bundle.module.url(forResource: "s57expectedinput", withExtension: "csv") {
            expectedInputCatalog = try? ExpectedInputCatalog(url: expectedUrl)
        }

        dataRecords = []
        items = []
        vectors = [:]
        features = [:]

        leadRecord = nil
        parameters = nil
        structure = nil
        catalog = [] // No esta clar. Ptser el catàleg hauria de viure independentment
                        // i Llegir-se automàticament a partir de un directori
        
        do {
            if let url = url {
                stream = try BufferedInputStream(url: url) ?! S57Errors.UnableToCreateStream
                
                stream!.open()
                
                defer {
                    stream!.close()
                }
                
                leadRecord = try LeadRecord(stream!)
                
                //print(leadRecord!.description)
                do {
                    while stream!.hasBytesAvailable{
                        let dataRecord = try DataRecord(leadRecord: leadRecord!, stream: stream!, aall: (structure?.AALL ?? UInt8(1))  as! UInt8, nall: (structure?.NALL ?? UInt8(1)) as! UInt8)
                        dataRecords.append(dataRecord)
                        //print(dataRecord.description)
                        let item = DataItem(dataRecord)
                        if parameters == nil, let p = item.DSPM{
                            parameters = p
                            coordinateFactor = Double((p.COMF as? UInt32) ?? 0)
                            soundingFactor =  Double((p.SOMF as? UInt32) ?? 0)
                        }
                        
                        if structure == nil, let s = item.DSSI {
                            structure = s
                        }
                        items.append(item)
                        
                        if item.keyField == "CATD" {
                            let catItem = try S57CatalogItem(item)
                            catalog.append(catItem)
                        } else if item.keyField == "VRID"{
                            let v = try S57Vector(item, coordinateFactor: coordinateFactor, soundingFactor: soundingFactor,
                            attributeCatalog: attributeCatalog, expectedInputCatalog: expectedInputCatalog)
                            vectors[UInt64(littleEndianBytes: v.name)] = v
                        }else if item.keyField == "FRID" {
                            let f = try S57Feature(item, objectCatalog: objectClasses, attributeCatalog: attributeCatalog, expectedInputCatalog: expectedInputCatalog)
                            features[f.id] = f
                         }
                    }
                }catch(e : SomeErrors.notEnoughBytes){
                    // EOF.
                    
                }
                buildFeaturetClasses()
                dereferenceVectors()        // So we may send only a vector and don't need related ones
                dereferenceFeatures()// Difficult to see if we link
                
                print("Done")
                // Only for catalog
            }
          }catch {
             print("Error : \(error)")
        }
    }
}
