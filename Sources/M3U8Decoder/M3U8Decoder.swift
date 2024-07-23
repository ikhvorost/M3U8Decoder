//  M3U8Decoder.swift
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
  var camelCased: String {
    self.split(separator: "-")
      .reduce("", { $0 + ($0.isEmpty ? String($1) : $1.capitalized) })
  }
}

fileprivate extension DateFormatter {
  static let iso8601withFractionalSeconds: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
    return formatter
  }()
  
  static let iso8601: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
    return formatter
  }()
}

// An implementation of CodingKey that's useful for combining and transforming keys as strings.
fileprivate struct AnyKey: CodingKey {
  var stringValue: String
  var intValue: Int?
  
  init?(stringValue: String) {
    self.stringValue = stringValue
    self.intValue = nil
  }
  
  init?(intValue: Int) {
    self.stringValue = String(intValue)
    self.intValue = intValue
  }
}

extension JSONDecoder.KeyDecodingStrategy {
  static let snakeCase = custom {
    let key = $0.last!.stringValue
      .lowercased()
      .replacingOccurrences(of: "-", with: "_")
    return AnyKey(stringValue: key)!
  }
  
  static let camelCase = custom {
    let key = $0.last!.stringValue
      .lowercased()
      .camelCased
    return AnyKey(stringValue: key)!
  }
}

fileprivate extension JSONDecoder.DateDecodingStrategy {
  static let ISO_8601 = custom {
    let container = try $0.singleValueContainer()
    let string = try container.decode(String.self)
    if let date = DateFormatter.iso8601withFractionalSeconds.date(from: string) ?? DateFormatter.iso8601.date(from: string) {
      return date
    }
    throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(string)")
  }
}

fileprivate extension JSONDecoder.DataDecodingStrategy {
  private static let regex = try! NSRegularExpression(pattern: "([0-9a-fA-F]{2})", options: [])
  
  static let hex = custom {
    let container = try $0.singleValueContainer()
    let string = try container.decode(String.self)
    let range = NSRange(location: 0, length: string.utf16.count)
    let bytes = Self.regex.matches(in: string, options: [], range: range)
      .compactMap { Range($0.range(at: 1), in: string) }
      .compactMap { UInt8(string[$0], radix: 16) }
    return Data(bytes)
  }
}

/// An object that decodes instances of a data and string types from Media Playlist text
/// format: https://datatracker.ietf.org/doc/html/rfc8216.
///
/// The example below shows how to decode an instance of a simple Playlist type
/// from a text of Media Playlist format.
///
///     struct Playlist: Decodable {
///         let extm3u: Bool
///         let ext_x_version: Int
///         let ext_x_targetduration: Int
///         let ext_x_media_sequence: Int
///         let extinf: [EXTINF]
///         let uris: [String]
///     }
///
///     let m3u8 = """
///     #EXTM3U
///     #EXT-X-VERSION:7
///     #EXT-X-TARGETDURATION:10
///     #EXT-X-MEDIA-SEQUENCE:2680
///
///     #EXTINF:13.333,Sample artist - Sample title
///     http://example.com/low.m3u8
///     """
///
///     let playlist = try M3U8Decoder().decode(Playlist.self, from: m3u8)
///     print(playlist.ext_x_version) // Prints "7"
///     print(playlist.ext_x_targetduration) // Prints "10"
///     print(playlist.extinf[0].duration) // Prints "13.33"
///     print(playlist.extinf[0].title!) // Prints "Sample artist - Sample title"
///     print(playlist.uri[0]) // Prints "http://example.com/low.m3u8"
///
public class M3U8Decoder {
  
  /// Decoding errors.
  public enum Error: String, LocalizedError {
    /// Not Extended M3U Playlist file.
    case notPlaylist = "Not Extended M3U Playlist file."
    /// Bad data.
    case badData = "Bad data."
  }
  
  /// The strategy to use for automatically changing the value of keys before decoding.
  public enum KeyDecodingStrategy {
    /// Converting playlist tag and attribute names to snake case.
    ///
    /// 1. Converting keys to lower case.
    /// 2. Replaces all `-` with `_`.
    ///
    /// For example: `#EXT-X-TARGETDURATION` becomes `ext_x_targetduration`.
    case snakeCase
    
    /// Converting playlist tag and attribute names to camel case.
    ///
    /// 1. Converting keys to lower case.
    /// 2. Capitalises the word starting after each `-`
    /// 3. Removes all `-`.
    ///
    /// For example: `#EXT-X-TARGETDURATION` becomes `extXTargetduration`.
    case camelCase
    
    /// Provide a custom conversion from a tag or attribute name in the playlist
    /// to the keys specified by the provided function.
    case custom((_ key: String) -> String)
  }
  
  /// The strategy to use for decoding tag and attribute names. Defaults to `.snakeCase`.
  public var keyDecodingStrategy: KeyDecodingStrategy = .snakeCase
  
  /// The strategy to use for decoding `Data` values.
  public enum DataDecodingStrategy {
    /// Decode the `Data` from a hex string (e.g. `0xa2c4f622...`). This is the default strategy.
    case hex
    
    /// Decode the `Data` from a Base64-encoded string.
    case base64
  }
  
  /// The strategy to use in decoding binary data. Defaults to `.hex`.
  public var dataDecodingStrategy: DataDecodingStrategy = .hex
  
  /// The policy to pass back to the parsing handler.
  public enum ParseAction {
    /// Parse the attributes.
    case parse
    /// Apply the attributes.
    case apply(Any)
  }
  
  /// The parsing handler function type.
  public typealias ParseHandler = (String, String) -> ParseAction
  
  /// The parsing handler to call to parse or apply the attributes.
  public var parseHandler: ParseHandler?
  
  private var decoder: JSONDecoder {
    let decoder = JSONDecoder()
    
    // Date
    decoder.dateDecodingStrategy = .ISO_8601
    
    // Key
    switch keyDecodingStrategy {
      case .snakeCase:
        decoder.keyDecodingStrategy = .snakeCase
        
      case .camelCase:
        decoder.keyDecodingStrategy = .camelCase
        
      case let .custom(f):
        decoder.keyDecodingStrategy = .custom {
          let key = $0.last!.stringValue
          return AnyKey(stringValue: f(key))!
        }
    }
    
    // Data
    switch dataDecodingStrategy {
      case .hex:
        decoder.dataDecodingStrategy = .hex
        
      case .base64:
        decoder.dataDecodingStrategy = .base64
    }
    return decoder
  }
  
  /// Creates a new, reusable Media Playlist decoder with the default formatting settings and decoding strategies.
  public init() {}
  
  /// Returns a value of the type you specify, decoded from Media Playlist text.
  ///
  /// If the text isn’t valid Media Playlist or fails to decode this method throws the corresponding error.
  ///
  /// - Parameters:
  ///    - type: The type of the value to decode.
  ///    - text: The text to decode from.
  /// - Returns: A value of the requested type.
  /// - Throws: An error if any value throws an error during decoding.
  public func decode<T: Decodable>(_ type: T.Type, from string: String) throws -> T {
    let dict = try M3U8Parser.parse(string: string, parseHandler: parseHandler)
    let data = try JSONSerialization.data(withJSONObject: dict)
    return try decoder.decode(type, from: data)
  }
  
  /// Returns a value of the type you specify, decoded from Media Playlist data.
  ///
  /// If the data isn’t valid Media Playlist or fails to decode this method throws the corresponding error.
  ///
  /// - Parameters:
  ///    - type: The type of the value to decode.
  ///    - data: The data to decode from.
  /// - Returns: A value of the requested type.
  /// - Throws: An error if any value throws an error during decoding.
  public func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
    guard let text = String(data: data, encoding: .utf8) else {
      throw Error.badData
    }
    return try decode(type, from: text)
  }
  
  /// Returns a value of the type you specify, decoded from Media Playlist URL.
  ///
  /// If the data from the URL isn’t valid Media Playlist or fails to decode this method throws the corresponding error.
  ///
  /// - Parameters:
  ///    - type: The type of the value to decode.
  ///    - url: The URL to decode from.
  /// - Returns: A value of the requested type.
  /// - Throws: An error if any value throws an error during decoding.
  public func decode<T: Decodable>(_ type: T.Type, from url: URL) throws -> T {
    let text = try String(contentsOf: url)
    return try decode(type, from: text)
  }
  
  /// Delivers a value of the type you specify asynchronously, decoded from contents of a Media Playlist URL.
  ///
  /// If the data from the URL isn’t valid Media Playlist or fails to decode this method throws the corresponding error.
  ///
  /// - Parameters:
  ///    - type: The type of the value to decode.
  ///    - url: The URL to decode from.
  /// - Returns: A value of the requested type.
  public func decode<T: Decodable>(_ type: T.Type, from url: URL) async throws -> T {
    let request = URLRequest(url: url)
    let (data, _) = try await URLSession.shared.data(for: request)
    return try decode(type, from: data)
  }
}

#if canImport(Combine)

import protocol Combine.TopLevelDecoder

extension M3U8Decoder: TopLevelDecoder {
  /// The type this decoder accepts.
  public typealias Input = Data
}

#endif
