//
//  Double + Extensions.swift
//  
//
//  Created by Francisco Gorina Vanrell on 24/4/23.
//

import Foundation

extension Double {
    
    
    func asDDDmmm() -> String{
        let s = self.sign == .minus ? -1.0 : 1.0
        
        
        let v = abs(self)
        let degrees = NSNumber(value: floor(v) * s)
        let minutes = NSNumber(value:((v - floor(v)) * 60.0))
        
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        
        let sd = formatter.string(from: degrees)!
        
        formatter.maximumFractionDigits = 1
        formatter.minimumIntegerDigits = 2
        
        let sm = formatter.string(from: minutes)!
        
        
        //let seconds = Int(floor(self - Double(hours * 3600) - Double(minutes * 3600)))
        
        return "\(sd)º \(sm)'"
    }
    
    func formatted(decimals: Int, separator: Bool = true) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = decimals
        formatter.maximumFractionDigits = decimals
        formatter.usesGroupingSeparator = true

        return formatter.string(from: NSNumber(value:self))!
    }
 
}

