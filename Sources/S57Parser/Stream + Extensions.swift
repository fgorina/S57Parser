//
//  Stream + Extensions.swift
//  S57Test
//
//  Created by Francisco Gorina Vanrell on 19/4/23.
//

import Foundation

enum InputStreamError : Error {
    case encodingErrpor
    case errorCreatingStream
}
extension InputStream {
    func readData(maxLength length: Int) throws -> Data {
        var buffer = [UInt8](repeating: 0, count: length)
        let result = self.read(&buffer, maxLength: buffer.count)
        if result < 0 {
            throw self.streamError ?? POSIXError(.EIO)
        } else {
            return Data(buffer.prefix(result))
        }
    }
}

class BufferedInputStream  {
    var stream : InputStream
    
    var buffer : [Byte] = []
    
    var debugBuffer : [Byte] = []
    let debugBufferSize = 100
    
    var lastCodes : [String] {
        debugBuffer.map { byte in
            String(format: "%02X", byte)
        }
    }
    
    init(url : URL) throws {
        stream = try InputStream(url: url) ?! InputStreamError.errorCreatingStream
    }
    
    func open(){
        stream.open()
    }
    
    func close(){
        stream.close()
    }
    
    var hasBytesAvailable : Bool {
        return stream.hasBytesAvailable || !buffer.isEmpty
    }
    
    func readBytes(length: Int) throws -> [Byte] {
       
        let l = buffer.count
        
        if l >= length {
            let returned = Array<Byte>(buffer[..<length])
            buffer.removeFirst(length)
            return  returned
        }else{
            let diff = length - l
            
            var buf = [Byte](repeating: 0, count: diff)
            let result = stream.read(&buf, maxLength: buf.count)
            if result < 0 {
                throw stream.streamError ?? POSIXError(.EIO)
            } else if result == 0{
                throw SomeErrors.notEnoughBytes
            }else {
                debugBuffer.append(contentsOf: buf)
                if debugBuffer.count > debugBufferSize {
                    let l = debugBuffer.count - debugBufferSize
                    debugBuffer.removeFirst(l)
                }
                buffer.append(contentsOf: buf)
                let returned = buffer.map { b in
                    b
                }
                buffer = []
                return returned
            }
        }
    }
    
    func pushBack(_ b : Byte){
        buffer.insert(b, at: 0)
    }
    
    func readString(length : Int, encoding : String.Encoding = .isoLatin1) throws -> String{
        let bytes = try readBytes(length: length)
        if let str = try? bytes.stringValue(encoding: encoding){
            if stream.hasBytesAvailable{
                let sep = try readBytes(length: 1)[0]   // Jump eof
                if sep != eor {
                    pushBack(sep)
                }
            }
            
            return str
        }else {
            throw SomeErrors.encodingError
        }
        
    }
    
    func readStringInt(length : Int, encoding : String.Encoding = .isoLatin1) throws -> Int{
        let str = try readString(length: length, encoding: encoding)
        if let i = Int(str) {
            return i
        }else {
            throw SomeErrors.stringToIntConversionError
        }
    }
    
    func readBytes(until : [Byte]) throws -> [Byte]{
      
        var bytes : [Byte] = []
        while true {
            if !buffer.isEmpty{
                let c = buffer.removeFirst()
                if !until.contains(c) {
                    bytes.append(c)
                }else {
                    break
                }
                
            }else {
                let c = try readBytes(length: 1)[0]
                
                if !until.contains(c) {
                    bytes.append(c)
                    debugBuffer.append(c)
                }else {
                    debugBuffer.append(c)
                    break
                }
                
            }
        }
        
        return bytes
    }
    
    func readString(until : [Byte], encoding : String.Encoding = .isoLatin1) throws -> (String, Int){
        let bytes = try readBytes(until: until)
        var n = bytes.count
        if encoding != .isoLatin1{
            let _ = try readBytes(length: 1)    // There is a 0 after the 1F
            n += 1
        }

        
        if let str = try? bytes.stringValue(encoding: encoding){
            return (str, n)
        }else {
            throw  SomeErrors.encodingError
        }
    }
    
    func readUInt8() throws -> UInt8{
        let bytes = try readBytes(length: 1)
        return UInt8(littleEndianBytes:  bytes)
    }
    
    func readUInt16() throws -> UInt16{
        let bytes = try readBytes(length: 2)
        return UInt16(littleEndianBytes:  bytes)
    }
    
    func readUInt32() throws -> UInt32{
        let bytes = try readBytes(length: 4)
        return UInt32(littleEndianBytes:  bytes)
    }
    
    func readInt8() throws -> Int8{
        let bytes = try readBytes(length: 1)
        return Int8(littleEndianBytes:  bytes)
    }
    
    func readInt16() throws -> Int16{
        let bytes = try readBytes(length: 2)
        return Int16(littleEndianBytes:  bytes)
    }
    
    func readInt32() throws -> Int32{
        let bytes = try readBytes(length: 4)
        return Int32(littleEndianBytes:  bytes)
    }
}


extension OutputStream {
    func write<DataType: DataProtocol>(_ data: DataType) throws -> Int {
        var buffer = Array(data)
        let result = self.write(&buffer, maxLength: buffer.count)
        if result < 0 {
            throw self.streamError ?? POSIXError(.EIO)
        } else {
            return result
        }
    }
}
