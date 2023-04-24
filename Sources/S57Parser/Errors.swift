//
//  Errors.swift
//  S57Test
//
//  Created by Francisco Gorina Vanrell on 19/4/23.
//

import Foundation

public enum SomeErrors : Error {
    case encodingError
    case stringToIntConversionError
    case notEnoughBytes
    case pringueError
    case notACatalogEntry
}
