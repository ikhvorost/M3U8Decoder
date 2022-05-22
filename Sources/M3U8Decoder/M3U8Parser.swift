//
//  File.swift
//  
//
//  Created by Iurii Khvorost on 21.05.2022.
//

import Foundation

extension String : LocalizedError {
    public var errorDescription: String? { return self }
    
    func replacingHypen() -> String {
        replacingOccurrences(of: "-", with: "_")
    }
    
    func trimmingQuotes() -> String {
        trimmingCharacters(in: CharacterSet(charactersIn: "\""))
    }
}

public enum KeyDecodingStrategy {
    case useDefaultKeys
    case convertFromSnakeCase
    //case custom((_ codingPath: [CodingKey]) -> CodingKey)
}

// TODO: parse URL, file URL, combine
// RESOLUTION width height
public class M3U8Parser {
    public var autoDetectValueType = true

    private static let regexTag = try! NSRegularExpression(pattern: "^#(EXT[^:]+):?(.*)$", options: [])
    private static let regexAttr = try! NSRegularExpression(pattern: "([^=,]+)=((\"([^\"]+)\")|([^,]+))")
    
    private static let boolValues = ["YES", "NO"]
    
    public func parse(data: Data) -> [String : Any]? {
        guard let text = String(data: data, encoding: .utf8) else {
            return nil
        }
        return parse(text: text)
    }
    
    public func parse(text: String) -> [String : Any]? {
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
                    let tag = String(line[tagRange]).replacingHypen()
                    let attr = String(line[attrRange])
                    
                    let nextLine = i < (items.count - 1) ? items[i + 1] : nil
                    let value = attr == "" ? true : tagAttributes(text: attr, nextLine: nextLine)
                    
                    if let item = dict[tag] {
                        if var array = item as? [Any] {
                            array.append(value)
                            dict[tag] = array
                        }
                        else {
                            dict[tag] = [value]
                        }
                    }
                    else {
                        dict[tag] = value
                    }
                }
            }
        }
        //print(dict)
        return dict
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
            
            let key = String(text[keyRange]).replacingHypen()
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
