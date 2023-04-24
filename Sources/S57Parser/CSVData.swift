//
//  CSVLoader.swift
//  S57Test
//
//  Created by Francisco Gorina Vanrell on 21/4/23.
//

import Foundation

struct CSVData{
    var url : URL
    var header : [String] = []
    var rows : [[String]] = []
    
    init(url : URL, header : Bool = true, separator : Character = ",", encoding: String.Encoding = .utf8) throws{
        self.url = url
        do {
            let contents = try String(contentsOf: url, encoding: encoding)
        
        var someRows = contents.split{$0.isNewline}
        
        guard  !someRows.isEmpty else { return }
        
        if header {
            self.header = someRows[0].tokenize(separator: ",")
            someRows.remove(at: 0)
        }
        
        for line in someRows {
            
//            let row : [String] = line.split(separator: separator).map({String($0)})
            let row = line.tokenize(separator: ",")
            self.rows.append(row)
        }
        } catch{
            print(error)
            
            throw(error)
        }

     }
    
    
    subscript(index: Int) -> [String]? {
        if index >= 0 && index < rows.count {
            return rows[index]
        }else{
            return nil
        }
    }
    
}
