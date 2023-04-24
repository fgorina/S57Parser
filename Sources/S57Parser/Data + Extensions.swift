//
//  Data + Extensions.swift
//  S57Test
//
//  Created by Francisco Gorina Vanrell on 18/4/23.
//

import Foundation
typealias Byte = UInt8
enum Bit: Int {
    case zero, one
}

extension Data {
    var bytes: [Byte] {
        var byteArray = [UInt8](repeating: 0, count: self.count)
        self.copyBytes(to: &byteArray, count: self.count)
        return byteArray
    }
}

extension Byte {
    var bits: [Bit] {
        let bitsOfAbyte = 8
        var bitsArray = [Bit](repeating: Bit.zero, count: bitsOfAbyte)
        for (index, _) in bitsArray.enumerated() {
            // Bitwise shift to clear unrelevant bits
            let bitVal: UInt8 = 1 << UInt8(bitsOfAbyte - 1 - index)
            let check = self & bitVal
            
            if check != 0 {
                bitsArray[index] = Bit.one
            }
        }
        return bitsArray
    }
}

extension Array<Byte> {
    
    func splits(_ sep : Byte) -> [[Byte]]{
        
        var output : [[Byte]] = []
        var partial : [Byte] = []
        
        for byte in self{
            
            if byte == sep {
                output.append(partial)
                partial = []
            }else{
                partial.append(byte)
            }
        }
        
        if !partial.isEmpty {
            output.append(partial)
        }
        
        return output
    }
    
    func stringValue(encoding enc : String.Encoding = .utf8) throws -> String {
        return try String(bytes: self, encoding: enc) ?! SomeErrors.encodingError
    }
}

extension ArraySlice<Byte>{
    func stringValue(encoding enc : String.Encoding = .utf8) -> String {
        
        return String(bytes: self, encoding: enc) ?? ""
    }

}


