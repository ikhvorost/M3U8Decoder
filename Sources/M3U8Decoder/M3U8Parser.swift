//  M3U8Parser.swift
//
//  Created by Iurii Khvorost <iurii.khvorost@gmail.com> on 2022/05/22.
//  Copyright © 2022 Iurii Khvorost. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

extension String : LocalizedError {
    public var errorDescription: String? { return self }
    
    func trimmingQuotes() -> String {
        trimmingCharacters(in: CharacterSet(charactersIn: "\""))
    }
}

// TODO: RESOLUTION width height, EXTINF
class M3U8Parser {
    private static let regexTag = try! NSRegularExpression(pattern: "^#(EXT[^:]+):?(.*)$", options: [])
    private static let regexAttr = try! NSRegularExpression(pattern: "([^=,]+)=((\"([^\"]+)\")|([^,]+))")
    
    private static let boolValues = ["YES", "NO"]
    
    var autoDetectValueType = true
    var keyDecodingStrategy: M3U8Decoder.KeyDecodingStrategy = .snakeCase
    
    func parse(text: String) -> [String : Any]? {
        guard text.isEmpty == false else {
            return nil
        }
        
        var dict = [String : Any]()
        
        let items = text.components(separatedBy: .newlines)
        for i in 0..<items.count {
            let line = items[i]
            
            guard line.hasPrefix("#") else {
                continue
            }
            
            let range = NSRange(location: 0, length: line.utf16.count)
            Self.regexTag.matches(in: line, options: [], range: range).forEach {
                if let tagRange = Range($0.range(at: 1), in: text), let attrRange = Range($0.range(at: 2), in: line) {
                    let tagKey = key(text: String(line[tagRange]))
                    let attr = String(line[attrRange])
                    
                    let nextLine = i < (items.count - 1) ? items[i + 1] : nil
                    let value = attr == "" ? true : tagAttributes(text: attr, nextLine: nextLine)
                    
                    if let item = dict[tagKey] {
                        if var array = item as? [Any] {
                            array.append(value)
                            dict[tagKey] = array
                        }
                        else {
                            dict[tagKey] = [value]
                        }
                    }
                    else {
                        dict[tagKey] = value
                    }
                }
            }
        }
        return dict
    }
    
    private func key(text: String) -> String {
        switch keyDecodingStrategy {
        case .snakeCase:
            fallthrough
        case .camelCase:
            return text.lowercased().replacingOccurrences(of: "-", with: "_")
            
        case let .custom(f):
            return f(text)
        }
    }
    
    private func value(text: String) -> Any {
        guard autoDetectValueType else {
            return text
        }
        
        if let i = Int(text) {
            return i
        }
        else if let d = Double(text) {
            return d
        }
        else if Self.boolValues.contains(text) {
            return text == "YES"
        }
        return text
    }
    
    private func tagAttributes(text: String, nextLine: String?) -> Any {
        let range = NSRange(location: 0, length: text.utf16.count)
        var keyValues: [(String, Any)] = Self.regexAttr.matches(in: text, options: [], range: range).compactMap {
            guard let keyRange = Range($0.range(at: 1), in: text), let valueRange = Range($0.range(at: 2), in: text) else {
                return nil
            }
            
            let key = key(text: String(text[keyRange]))
            let value = String(text[valueRange]).trimmingQuotes()
            return (key, self.value(text: value))
        }
        
        if let line = nextLine, line.isEmpty == false, line.hasPrefix("#") == false {
            keyValues.append(("URI", line))
        }
        
        // TODO: verify unique keys
        return keyValues.count > 0
            ? Dictionary(uniqueKeysWithValues: keyValues)
            : value(text: text)
    }
}
