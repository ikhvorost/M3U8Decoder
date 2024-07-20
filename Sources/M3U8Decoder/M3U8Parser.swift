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
  
  private static let yes: [String] = ["YES", "yes", "TRUE", "true"]
  private static let no: [String] = ["NO", "no", "FALSE", "false"]
  private static let quotes: [String] = ["\"", "\\\"", "'", "\\'"]
  
  var isBase64: Bool {
    (hasSuffix("=") || hasSuffix("==")) && Data(base64Encoded: self) != nil
  }
  
  var booleanValue: Bool? {
    if Self.yes.contains(self) {
      return true
    }
    if Self.no.contains(self) {
      return false
    }
    return nil
  }
  
  var hasQuotePrefix: Bool {
    for q in Self.quotes {
      if hasPrefix(q) {
        return true
      }
    }
    return false
  }
}

fileprivate extension CharacterSet {
  static let quotes = CharacterSet(charactersIn: #""'\\"#)
  static let hashes = CharacterSet(charactersIn: "#")
}

fileprivate enum Line {
  case tag(String, Any)
  case comment(String)
  case uri(String)
}

class M3U8Parser {
  
  private static let regexExtTag = try! NSRegularExpression(pattern: "^#(EXT[^:]+):?(.*)$", options: [])
  private static let regexAttributes = try! NSRegularExpression(pattern: #"([^=,\s]+)=((\\?"[^\\"]+)|(\\?'[^\\']+)|([^,\s]+))"#)
  private static let regexExtInf = try! NSRegularExpression(pattern: "^([^,]+),?(.*)$")
  private static let regexByterange = try! NSRegularExpression(pattern: "(\\d+)@?(\\d*)")
  private static let regexResolution = try! NSRegularExpression(pattern: "(\\d+)x(\\d+)")
  
  private static let arrayTags: [String] = [
    "EXT-X-MEDIA",
    "EXT-X-I-FRAME-STREAM-INF"
  ]
  
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
  
  private static func json(lines: [Line]) throws -> NSMutableDictionary {
    let dict = NSMutableDictionary()
    let comments = NSMutableArray()
    
    // Variant stream
    let streams = NSMutableArray()
    let stream = NSMutableDictionary()
    
    // Media segment
    let segments = NSMutableArray()
    let segment = NSMutableDictionary()
    
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
          
        case .comment(let comment):
          comments.add(comment)
          
        case .uri(let uri):
          // Variant stream
          if stream.count > 0 {
            stream["uri"] = uri
            streams.add(stream.copy())
            stream.removeAllObjects()
          }
          
          // Media segment
          if segment.count > 0 {
            segment["uri"] = uri
            segments.add(segment.copy())
            segment.removeAllObjects()
          }
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
  
  private static func value(text: String) -> Any {
    // Skip hex
    guard text.hasPrefix("0x") == false, text.hasPrefix("0X") == false else {
      return text
    }
    
    if let number = Double(text) {
      return number
    }
    else if let value = text.booleanValue {
      return value
    }
    
    return text
  }
  
  private static func parse(attribute: String, text: String) -> Any? {
    let range = NSRange(location: 0, length: text.utf16.count)
    
    // BYTERANGE:<n>[@<o>]
    if attribute == "BYTERANGE" {
      if let match = Self.regexByterange.matches(in: text, options: [], range: range).first,
         match.numberOfRanges == 3,
         let lengthRange = Range(match.range(at: 1), in: text),
         let startRange = Range(match.range(at: 2), in: text)
      {
        var keyValues = [String : Any]()
        
        let length = String(text[lengthRange])
        keyValues["length"] = value(text: length)
        
        let start = String(text[startRange])
        if start.isEmpty == false {
          keyValues["start"] = value(text: start)
        }
        
        return keyValues
      }
    }
    // RESOLUTION=<width>x<height>
    else if attribute == "RESOLUTION" {
      let matches = Self.regexResolution.matches(in: text, options: [], range: range)
      if let match = matches.first, match.numberOfRanges == 3,
         let widthRange = Range(match.range(at: 1), in: text),
         let heightRange = Range(match.range(at: 2), in: text)
      {
        var keyValues = [String : Any]()
        
        let width = String(text[widthRange])
        keyValues["width"] = value(text: width)
        
        let height = String(text[heightRange])
        keyValues["height"] = value(text:height)
        
        return keyValues
      }
    }
    // CODECS="codec1,codec2,..."
    else if attribute == "CODECS" {
      return text
        .trimmingCharacters(in: .quotes)
        .components(separatedBy: ",")
    }
    
    return nil
  }
  
  private static func parse(tag: String, attributes: String) -> Any {
    // Bool
    guard attributes.isEmpty == false else {
      return true
    }
    
    // Base64 data
    if attributes.isBase64 {
      return attributes
    }
    
    var keyValues = [String : Any]()
    let range = NSRange(location: 0, length: attributes.utf16.count)
    
    // #EXTINF:<duration>,[<title>]
    if tag == "EXTINF" {
      if let match = Self.regexExtInf.matches(in: attributes, options: [], range: range).first,
         match.numberOfRanges == 3,
         let durationRange = Range(match.range(at: 1), in: attributes),
         let titleRange = Range(match.range(at: 2), in: attributes)
      {
        let duration = String(attributes[durationRange])
        keyValues["duration"] = value(text: duration)
        
        let title = String(attributes[titleRange])
        if !title.isEmpty {
          keyValues["title"] = title
        }
      }
    }
    // #EXT-X-BYTERANGE:<n>[@<o>]
    else if tag == "EXT-X-BYTERANGE" {
      if let match = Self.regexByterange.matches(in: attributes, options: [], range: range).first,
         match.numberOfRanges == 3,
         let lengthRange = Range(match.range(at: 1), in: attributes),
         let startRange = Range(match.range(at: 2), in: attributes)
      {
        let length = String(attributes[lengthRange])
        keyValues["length"] = value(text: length)
        
        let start = String(attributes[startRange])
        if !start.isEmpty {
          keyValues["start"] = value(text:start)
        }
      }
    }
    
    // Other
    Self.regexAttributes.matches(in: attributes, options: [], range: range).forEach {
      guard $0.numberOfRanges >= 3 else { return }
      
      let keyRange = Range($0.range(at: 1), in: attributes)!
      let key = String(attributes[keyRange])
      
      let valueRange = Range($0.range(at: 2), in: attributes)!
      let value = String(attributes[valueRange])
      
      if let obj = parse(attribute: key, text: value) {
        keyValues[key] = obj
      }
      else {
        // Base64 data
        if value.isBase64 {
          keyValues[key] = value
        }
        else {
          if value.hasQuotePrefix {
            keyValues[key] = value.trimmingCharacters(in: .quotes)
          }
          else {
            keyValues[key] = self.value(text: value)
          }
        }
      }
    }
    
    return keyValues.isEmpty
      ? value(text: attributes)
      : keyValues
  }
  
  private static func parse(line: String, parseHandler: M3U8Decoder.ParseHandler?) -> Line {
    // #EXT
    if line.hasPrefix("#EXT") {
      let range = NSRange(location: 0, length: line.utf16.count)
      if let match = Self.regexExtTag.matches(in: line, options: [], range: range).first,
         let tagRange = Range(match.range(at: 1), in: line),
         let attributesRange = Range(match.range(at: 2), in: line)
      {
        let tag = String(line[tagRange])
        let attributes = String(line[attributesRange])
        
        let value = if let parseHandler {
          switch parseHandler(tag, attributes) {
            case .parse:
              parse(tag: tag, attributes: attributes)
              
            case .parsed(let value):
              value
          }
        }
        else {
          parse(tag: tag, attributes: attributes)
        }
        
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
  
  static func parse(string: String, parseHandler: M3U8Decoder.ParseHandler?) throws -> NSMutableDictionary {
    var lines = [String]()
    string.enumerateLines { line, stop in
      guard !line.isEmpty else {
        return
      }
      let trimmed = line.trimmingCharacters(in: .whitespaces)
      lines.append(trimmed)
      stop = trimmed == "#EXT-X-ENDLIST"
    }
    
    // It MUST be the first line of every Media Playlist and every Master Playlist.
    guard lines.first == "#EXTM3U" else {
      throw M3U8Decoder.Error.notPlaylist
    }
    
    var items = [Line](repeating: .uri(""), count: lines.count)
    
    let group = DispatchGroup()
    
    lines
      .enumerated()
      .forEach { i, line in
        group.enter()
        DispatchQueue.global().async {
          items[i] = parse(line: line, parseHandler: parseHandler)
          group.leave()
        }
      }
    
    group.wait()
    
    return try json(lines: items)
  }
}
