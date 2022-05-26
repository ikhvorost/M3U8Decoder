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
}

class M3U8Parser {
    private static let regexTag = try! NSRegularExpression(pattern: "^#(EXT[^:]+):?(.*)$", options: [])
    private static let regexAttr = try! NSRegularExpression(pattern: "([^=,]+)=((\"([^\"]+)\")|([^,]+))")
    
    private static let boolValues = ["YES", "NO"]
    
    private static let uriKey = "uri"
    private static let arrayTags = ["EXTINF", "EXT-X-BYTERANGE", "EXT-X-MEDIA", "EXT-X-STREAM-INF", "EXT-X-I-FRAME-STREAM-INF"]
    
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
            
            guard line.isEmpty == false else {
                continue
            }
            
            // URI
            guard line.hasPrefix("#EXT") else {
                if var items = dict[Self.uriKey] as? [Any] {
                    items.append(line)
                    dict[Self.uriKey] = items
                }
                else {
                    dict[Self.uriKey] = [line]
                }
                continue
            }
            
            let range = NSRange(location: 0, length: line.utf16.count)
            Self.regexTag.matches(in: line, options: [], range: range).forEach {
                if let tagRange = Range($0.range(at: 1), in: text), let attrRange = Range($0.range(at: 2), in: line) {
                    let tag = String(line[tagRange])
                    let attr = String(line[attrRange])
                    
                    let key = key(text: tag)
                    let value = parseAttributes(tag: tag, text: attr)
                    
                    if let item = dict[key] {
                        if var items = item as? [Any] {
                            items.append(value)
                            dict[key] = items
                        }
                        else {
                            dict[key] = [item, value]
                        }
                    }
                    else {
                        if Self.arrayTags.contains(tag) {
                            dict[key] = [value]
                        }
                        else {
                            dict[key] = value
                        }
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
    
    // TODO: regex for types
    private func value(text: String) -> Any {
        guard autoDetectValueType  else {
            return text
        }
        
        if text.count < 10 {
            if let number = Double(text) {
                return number
            }
            else if Self.boolValues.contains(text) {
                return text == "YES"
            }
        }
        
        return text
    }
    
    private func parseAttributes(tag: String, text: String) -> Any {
        guard text.isEmpty == false else {
            return true
        }
        
        var keyValues = [String : Any]()
        
        // #EXTINF
        // TODO: regex for EXTINF
        if tag == "EXTINF" {
            let items = text.components(separatedBy: ",")
            if let first = items.first {
                keyValues["duration"] = self.value(text: first)
            }
            
            if items.count == 2, let last = items.last, last.isEmpty == false, last.contains("=") == false {
                keyValues["title"] = self.value(text: last)
            }
        }
        else if tag == "EXT-X-BYTERANGE" {
            let items = text.components(separatedBy: "@")
            if let first = items.first {
                keyValues["length"] = self.value(text: first)
            }
            
            if items.count == 2, let last = items.last, last.isEmpty == false, last.contains("=") == false {
                keyValues["start"] = self.value(text: last)
            }
        }
        
        let range = NSRange(location: 0, length: text.utf16.count)
        Self.regexAttr.matches(in: text, options: [], range: range).forEach {
            guard let keyRange = Range($0.range(at: 1), in: text),
                  let valueRange = Range($0.range(at: 2), in: text)
            else {
                return
            }
            
            let key = key(text: String(text[keyRange]))
            let value = String(text[valueRange]).trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            keyValues[key] = self.value(text: value)
        }
        
        return keyValues.count > 0
            ? keyValues
            : value(text: text)
    }
}
