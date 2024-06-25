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

fileprivate extension CharacterSet {
  static let quotes = CharacterSet(charactersIn: "\"")
  static let hashes = CharacterSet(charactersIn: "#")
}

fileprivate enum ParseResult {
  case object([String : Any])
  case other(Any)
  case none
}

fileprivate enum Line {
  case tag(String, Any)
  case comment(String)
  case uri(String)
  case none
}

class M3U8Parser {
  private static let regexExtTag = try! NSRegularExpression(pattern: "^#(EXT[^:]+):?(.*)$", options: [])
  private static let regexAttributes = try! NSRegularExpression(pattern: "([^=,\\s]+)=((\"([^\"]+)\")|([^,]+))")
  private static let regexExtInf = try! NSRegularExpression(pattern: "^([^,]+),?(.*)$")
  private static let regexByterange = try! NSRegularExpression(pattern: "(\\d+)@?(\\d*)")
  private static let regexResolution = try! NSRegularExpression(pattern: "(\\d+)x(\\d+)")
  
  private static let boolValues = ["YES", "NO"]
  
  private static let arrayTags = ["EXT-X-MEDIA", "EXT-X-I-FRAME-STREAM-INF"]
  private static let variantStreamTag = "EXT-X-STREAM-INF"
  private static let mediaSegmentTags: [String] = [
    "EXTINF",
    "EXT-X-BYTERANGE",
    "EXT-X-DISCONTINUITY",
    "EXT-X-KEY",
    "EXT-X-MAP",
    "EXT-X-PROGRAM-DATE-TIME",
    "EXT-X-DATERANGE",
  ]
  
  private static func json(lines: [Line]) throws -> [String : Any] {
    var dict = [String : Any]()
    var comments = [String]()
    
    // Master Playlist
    var streams = [[String : Any]]()
    var stream = [String : Any]()
    
    // Media Playlist
    var segments = [[String : Any]]()
    var segment = [String : Any]()
    
    lines.forEach { line in
      switch line {
        case .tag(let tag, let value):
          if tag == variantStreamTag {
            stream[tag] = value
          }
          else if mediaSegmentTags.contains(tag) {
            segment[tag] = value
          }
          else {
            if let item = dict[tag] {
              if let items = item as? NSMutableArray {
                items.add(value)
              }
              else {
                dict[tag] = NSMutableArray(objects: item, value)
              }
            }
            else {
              if Self.arrayTags.contains(tag) {
                dict[tag] = NSMutableArray(object: value)
              }
              else {
                dict[tag] = value
              }
            }
          }
          break
          
        case .comment(let comment):
          comments.append(comment)
          break
          
        case .uri(let uri):
          // Variant streams
          if !stream.isEmpty {
            stream["uri"] = uri
            streams.append(stream)
            stream.removeAll()
          }
          
          // Media segments
          if !segment.isEmpty {
            segment["uri"] = uri
            segments.append(segment)
            segment.removeAll()
          }
          break
          
        case .none:
          break
      }
    }
    
    if streams.count > 0 {
      dict["streams"] = streams
    }
    
    if segments.count > 0 {
      dict["segments"] = segments
    }
    
    if comments.count > 0 {
      dict["comments"] = comments
    }
    
    return dict
  }
  
  static func parse(string: String) throws -> [String : Any] {
    var lines = [String]()
    string.enumerateLines { line, stop in
      guard !line.isEmpty else {
        return
      }
      let trimmed = line.trimmingCharacters(in: .whitespaces)
      lines.append(trimmed)
      stop = trimmed == "#EXT-X-ENDLIST"
    }
    
    // Validate: #EXTM3U
    guard lines.first == "#EXTM3U" else {
      throw M3U8Decoder.Error.notPlaylist
    }
    
    var items = [Line](repeating: .none, count: lines.count)
    
    let group = DispatchGroup()
    
    lines
      .enumerated()
      .forEach { i, line in
        group.enter()
        DispatchQueue.global().async {
          items[i] = parse(line: line)
          group.leave()
        }
      }
    
    group.wait()
    
    return try json(lines: items)
  }
  
  private static func parse(line: String) -> Line {
    // #EXT
    if line.hasPrefix("#EXT") {
      let range = NSRange(location: 0, length: line.utf16.count)
      if let match = Self.regexExtTag.matches(in: line, options: [], range: range).first,
         let tagRange = Range(match.range(at: 1), in: line),
         let attributesRange = Range(match.range(at: 2), in: line)
      {
        let tag = String(line[tagRange])
        let attributes = String(line[attributesRange])
        
        let value = parse(tag: tag, attributes: attributes)
        return .tag(tag, value)
      }
    }
    // Comments
    else if line.hasPrefix("#") {
      let text = line
        .trimmingCharacters(in: .hashes)
        .trimmingCharacters(in: .whitespaces)
      return .comment(text)
    }
    // URI
    return .uri(line)
  }
  
  private static func convertType(text: String) -> Any {
    // Skip quoted strings or hex
    guard text.hasPrefix("\"") == false, text.hasPrefix("0x") == false, text.hasPrefix("0X") == false else {
      return text.trimmingCharacters(in: .quotes)
    }
    
    if let number = Double(text) {
      return number
    }
    else if Self.boolValues.contains(text) {
      return text == "YES"
    }
    
    return text
  }
  
  private static func parse(name: String, value: String) -> ParseResult {
    var keyValues = [String : Any]()
    let range = NSRange(location: 0, length: value.utf16.count)
    
    // #EXTINF:<duration>,[<title>]
    if name == "EXTINF" {
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
    }
    // #EXT-X-BYTERANGE:<n>[@<o>]
    else if name == "EXT-X-BYTERANGE" || name == "BYTERANGE" {
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
    }
    // #RESOLUTION=<width>x<height>
    else if name == "RESOLUTION" {
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
    }
    // CODECS="codec1,codec2,..."
    else if name == "CODECS" {
      let array = value
        .trimmingCharacters(in: .quotes)
        .components(separatedBy: ",")
      return .other(array)
    }
    return .none
  }
  
  private static func parse(attributes: String, keyValues: inout [String : Any]) {
    let text = attributes.contains(#"\""#)
      ? attributes.replacingOccurrences(of: #"\""#, with: "'")
      : attributes
    
    let range = NSRange(location: 0, length: text.utf16.count)
    Self.regexAttributes.matches(in: text, options: [], range: range).forEach {
      guard $0.numberOfRanges >= 3 else { return }
      
      let keyRange = Range($0.range(at: 1), in: text)!
      let name = String(text[keyRange])
      
      let valueRange = Range($0.range(at: 2), in: text)!
      let value = String(text[valueRange])
      
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
  
  private static func parse(tag: String, attributes: String) -> Any {
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
