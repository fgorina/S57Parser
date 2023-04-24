///
//  String + Extensions.swift
//  Conta_00
//
//  Created by Francisco Gorina Vanrell on 14/03/2020.
//  Copyright © 2020 Francisco Gorina Vanrell. All rights reserved.
//

import Foundation

extension String {
    
    var localized : String { return NSLocalizedString(self, comment: "Auto")}
    
        subscript (i: Int) -> String {
            return String(self[index(startIndex, offsetBy: i)])
        }
        subscript (bounds: CountableRange<Int>) -> Substring {
            let start = index(startIndex, offsetBy: bounds.lowerBound)
            let end = index(startIndex, offsetBy: bounds.upperBound)
            return self[start ..< end]
        }
        subscript (bounds: CountableClosedRange<Int>) -> Substring {
            let start = index(startIndex, offsetBy: bounds.lowerBound)
            let end = index(startIndex, offsetBy: bounds.upperBound)
            return self[start ... end]
        }
        subscript (bounds: CountablePartialRangeFrom<Int>) -> Substring {
            let start = index(startIndex, offsetBy: bounds.lowerBound)
            let end = index(endIndex, offsetBy: -1)
            return self[start ... end]
        }
        subscript (bounds: PartialRangeThrough<Int>) -> Substring {
            let end = index(startIndex, offsetBy: bounds.upperBound)
            return self[startIndex ... end]
        }
        subscript (bounds: PartialRangeUpTo<Int>) -> Substring {
            let end = index(startIndex, offsetBy: bounds.upperBound)
            return self[startIndex ..< end]
        }
    }
    extension Substring {
        subscript (i: Int) -> String {
            return String(self[index(startIndex, offsetBy: i)])
        }
        subscript (bounds: CountableRange<Int>) -> Substring {
            let start = index(startIndex, offsetBy: bounds.lowerBound)
            let end = index(startIndex, offsetBy: bounds.upperBound)
            return self[start ..< end]
        }
        subscript (bounds: CountableClosedRange<Int>) -> Substring {
            let start = index(startIndex, offsetBy: bounds.lowerBound)
            let end = index(startIndex, offsetBy: bounds.upperBound)
            return self[start ... end]
        }
        subscript (bounds: CountablePartialRangeFrom<Int>) -> Substring {
            let start = index(startIndex, offsetBy: bounds.lowerBound)
            let end = index(endIndex, offsetBy: -1)
            return self[start ... end]
        }
        subscript (bounds: PartialRangeThrough<Int>) -> Substring {
            let end = index(startIndex, offsetBy: bounds.upperBound)
            return self[startIndex ... end]
        }
        subscript (bounds: PartialRangeUpTo<Int>) -> Substring {
            let end = index(startIndex, offsetBy: bounds.upperBound)
            return self[startIndex ..< end]
        }

}


extension String {
    func camelCased(with separator: Character) -> String {
        return self.lowercased()
            .split(separator: separator)
            .enumerated()
            .map { $0.offset > 0 ? $0.element.capitalized : $0.element.lowercased() }
            .joined()
    }
    
    static func spaces(_ n : Int) -> String{
        return String(repeating:" ", count: n)
    }
    
    var isNumber: Bool {
        return !isEmpty && rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
    }
    
    static func ~= (lhs: String, rhs: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: rhs) else { return false }
        let range = NSRange(location: 0, length: lhs.utf16.count)
        return regex.firstMatch(in: lhs, options: [], range: range) != nil
    }
 
}

extension String {
    
    func splitEvery(_ n : Int ) -> [String] {
        var out : [String] = []
        
        stride (from: 0, to:self.count, by:n).forEach{
            out.append(String(self[$0..<$0+n]))
        }
        return out
    }
}


extension String {
    func allMatchesForRegex(_ regex : String) throws  -> [[String]] {
        
        let re = try NSRegularExpression(pattern: regex)
        let range = NSRange(location: 0, length: self.count)
        
        var out : [[String]] = []
        
        for match in re.matches(in: self, range: range){
            var oneMatch : [String] = []
            let n = match.numberOfRanges
            for i in 0..<n{
                let matchRange = match.range(at: i)
                let range = Range(matchRange, in: self)
                if let range = range {
                    let a = String(self[range])
                    oneMatch.append(a)
                }
                
            }
            out.append(oneMatch)
             }
        
        return out
    }
}

extension String {
    func tokenize(quote: Character  = "\"", separator : Character) -> [String]{
        var tokens : [String] = []
        var token : String = ""
        var inLiteral = false
        
        for c in self{
            
            if c == quote{
                inLiteral.toggle()
            } else if inLiteral {
                token += [c]
            }else if  c != separator {
                token += [c]
            } else {
                tokens.append(token)
                token = ""
            }
        }
        
        if !token.isEmpty{
            tokens.append(token)
        }
        return tokens
        
    }
 
}

extension Substring {
    func tokenize(quote: Character  = "\"", separator : Character) -> [String]{
        var tokens : [String] = []
        var token : String = ""
        var inLiteral = false
        
        for c in self{
            
            if c == quote{
                inLiteral.toggle()
            } else if inLiteral {
                token += [c]
            }else if  c != separator {
                token += [c]
            } else {
                tokens.append(token)
                token = ""
            }
        }
        
        if !token.isEmpty{
            tokens.append(token)
        }
        return tokens
        
    }
 

}
