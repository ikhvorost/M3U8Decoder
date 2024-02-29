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

fileprivate extension String {
  var isBase64: Bool {
    Data(base64Encoded: self) != nil
  }
}

fileprivate enum ParseResult {
  case object([String : Any])
  case other(Any)
  case none
}

class M3U8Parser {
  private static let regexExtTag = try! NSRegularExpression(pattern: "^#(EXT[^:]+):?(.*)$", options: [])
  private static let regexAttributes = try! NSRegularExpression(pattern: "([^=,\\s]+)=((\"([^\"]+)\")|([^,]+))")
  private static let regexExtInf = try! NSRegularExpression(pattern: "^([^,]+),?(.*)$")
  private static let regexByterange = try! NSRegularExpression(pattern: "(\\d+)@?(\\d*)")
  private static let regexResolution = try! NSRegularExpression(pattern: "(\\d+)x(\\d+)")
  
  private static let boolValues = ["YES", "NO"]
  private static let arrayTags = [
    "EXTINF", "EXT-X-BYTERANGE", // Playlist
    "EXT-X-MEDIA", "EXT-X-STREAM-INF", "EXT-X-I-FRAME-STREAM-INF" // Master playlist
  ]
  private static let charSetQuotes = CharacterSet(charactersIn: "\"")
  
  func parse(text: String) throws -> [String : Any] {
    var dict = [String : Any]()
    var comments = [String]()
    var uris = [String]()
    
    let items = text.components(separatedBy: .newlines)
    for i in 0..<items.count {
      let line = items[i].trimmingCharacters(in: .whitespaces)
      
      // Skip empty lines
      guard !line.isEmpty else {
        continue
      }
      
      // Check for the first line with #EXTM3U
      guard !dict.isEmpty || line == "#EXTM3U" else {
        throw "Not the Playlist."
      }
      
      // #EXT
      if line.hasPrefix("#EXT") {
        let range = NSRange(location: 0, length: line.utf16.count)
        Self.regexExtTag.matches(in: line, options: [], range: range).forEach {
          if let tagRange = Range($0.range(at: 1), in: text),
             let attributesRange = Range($0.range(at: 2), in: line)
          {
            let tag = String(line[tagRange])
            let attributes = String(line[attributesRange])
            
            let value = parse(tag: tag, attributes: attributes)
            
            if let item = dict[tag] {
              if var items = item as? [Any] {
                items.append(value)
                dict[tag] = items
              }
              else {
                dict[tag] = [item, value]
              }
            }
            else {
              if Self.arrayTags.contains(tag) {
                dict[tag] = [value]
              }
              else {
                dict[tag] = value
              }
            }
          }
        }
      }
      // Comments
      else if line.hasPrefix("#") {
        comments.append(line)
      }
      // URI
      else {
        uris.append(line)
      }
    }
    
    if comments.count > 0 {
      dict["comments"] = comments
    }
    
    if uris.count > 0 {
      dict["uris"] = uris
    }
    
    return dict
  }
  
  private func convertType(text: String) -> Any {
    // Skip quoted strings or hex
    guard text.hasPrefix("\"") == false, text.hasPrefix("0x") == false, text.hasPrefix("0X") == false else {
      return text.trimmingCharacters(in: Self.charSetQuotes)
    }
    
    if let number = Double(text) {
      return number
    }
    else if Self.boolValues.contains(text) {
      return text == "YES"
    }
    
    return text
  }
  
  private func parse(name: String, value: String) -> ParseResult {
    var keyValues = [String : Any]()
    let range = NSRange(location: 0, length: value.utf16.count)
    
    switch name {
      // #EXTINF:<duration>,[<title>]
      case "EXTINF":
        if let match = Self.regexExtInf.matches(in: value, options: [], range: range).first,
           match.numberOfRanges == 3,
           let durationRange = Range(match.range(at: 1), in: value),
           let titleRange = Range(match.range(at: 2), in: value)
        {
          let duration = String(value[durationRange])
          keyValues["duration"] = self.convertType(text: duration)
          
          let title = String(value[titleRange])
          if title.isEmpty == false {
            keyValues["title"] = title
          }
          
          return .object(keyValues)
        }
        
      // #EXT-X-BYTERANGE:<n>[@<o>]
      case "EXT-X-BYTERANGE":
        fallthrough
      case "BYTERANGE":
        if let match = Self.regexByterange.matches(in: value, options: [], range: range).first,
           match.numberOfRanges == 3,
           let lengthRange = Range(match.range(at: 1), in: value),
           let startRange = Range(match.range(at: 2), in: value)
        {
          let length = String(value[lengthRange])
          keyValues["length"] = self.convertType(text: length)
          
          let start = String(value[startRange])
          if start.isEmpty == false {
            keyValues["start"] = self.convertType(text:start)
          }
          
          return .object(keyValues)
        }
        
      // #RESOLUTION=<width>x<height>
      case "RESOLUTION":
        let matches = Self.regexResolution.matches(in: value, options: [], range: range)
        if let match = matches.first, match.numberOfRanges == 3,
           let widthRange = Range(match.range(at: 1), in: value),
           let heightRange = Range(match.range(at: 2), in: value)
        {
          let width = String(value[widthRange])
          keyValues["width"] = self.convertType(text: width)
          
          let height = String(value[heightRange])
          keyValues["height"] = self.convertType(text:height)
          
          return .object(keyValues)
        }
        
      // CODECS="codec1,codec2,..."
      case "CODECS":
        let array = value
          .trimmingCharacters(in: Self.charSetQuotes)
          .components(separatedBy: ",")
        return .other(array)
        
      default:
        return .none
    }
    
    return .none
  }
  
  private func parse(attributes: String, keyValues: inout [String : Any]) {
    let range = NSRange(location: 0, length: attributes.utf16.count)
    Self.regexAttributes.matches(in: attributes, options: [], range: range).forEach {
      guard $0.numberOfRanges >= 3 else { return }
      
      let keyRange = Range($0.range(at: 1), in: attributes)!
      let name = String(attributes[keyRange])
      
      let valueRange = Range($0.range(at: 2), in: attributes)!
      let value = String(attributes[valueRange])
      
      switch parse(name: name, value: value) {
        case let .object(object):
          keyValues[name] = object
        case let .other(item):
          keyValues[name] = item
        case .none:
          keyValues[name] = self.convertType(text: value)
      }
    }
  }
  
  private func parse(tag: String, attributes: String) -> Any {
    // Bool tag
    guard attributes.isEmpty == false else {
      return true
    }
    
    // Base64
    if (attributes.hasSuffix("=") || attributes.hasSuffix("==")) && attributes.isBase64 {
      return attributes
    }
    
    var keyValues = [String : Any]()
    if case let .object(dict) = parse(name: tag, value: attributes) {
      keyValues = dict
    }
    parse(attributes: attributes, keyValues: &keyValues)
    guard keyValues.count == 0 else {
      return keyValues
    }
    
    return convertType(text: attributes)
  }
}
