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

fileprivate extension JSONDecoder.DateDecodingStrategy {
    static let customISO8601 = custom {
        let container = try $0.singleValueContainer()
        let string = try container.decode(String.self)
        if let date = DateFormatter.iso8601withFractionalSeconds.date(from: string) ?? DateFormatter.iso8601.date(from: string) {
            return date
        }
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(string)")
    }
}

public class M3U8Decoder {
    
    public enum KeyDecodingStrategy {
        //case original?
        case snakeCase
        case camelCase
        case custom((_ key: String) -> String)
    }
    
    public var keyDecodingStrategy: KeyDecodingStrategy = .snakeCase
    
    public init() {
    }
    
    public func decode<T>(_ type: T.Type, from text: String) throws -> T where T : Decodable {
        let parser = M3U8Parser()
        parser.keyDecodingStrategy = keyDecodingStrategy
        guard let dict = parser.parse(text: text) else {
            throw "Bad data."
        }
        
        // Debug
        //print(dict)
        
        // Decoder
        let decoder = JSONDecoder()
        
        decoder.dateDecodingStrategy = .customISO8601
        
        if case .camelCase = keyDecodingStrategy {
            decoder.keyDecodingStrategy = .convertFromSnakeCase
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: dict)
        return try decoder.decode(type, from: jsonData)
    }
    
    public func decode<T>(_ type: T.Type, from data: Data) throws -> T where T : Decodable {
        guard let text = String(data: data, encoding: .utf8) else {
            throw "Bad data."
        }
        return try decode(type, from: text)
    }
    
    public func decode<T>(_ type: T.Type, from url: URL) throws -> T where T : Decodable {
        let data = try Data(contentsOf: url)
        return try decode(type, from: data)
    }
    
    public func decode<T>(_ type: T.Type, from url: URL, _ completion: @escaping (T?, Error?) -> Void) where T : Decodable {
        let request = URLRequest(url: url)
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil else {
                completion(nil, error!)
                return
            }
            
            guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                completion(nil, URLError(.badServerResponse))
                return
            }
            
            guard let data = data, data.isEmpty == false else {
                completion(nil, "No data.")
                return
            }
            
            do {
                let playlist = try self.decode(type, from: data)
                completion(playlist, nil)
            }
            catch {
                completion(nil, error)
            }
        }
        .resume()
    }
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    public func decode<T>(_ type: T.Type, from url: URL) async throws -> T where T : Decodable {
        try await withCheckedThrowingContinuation { continuation in
            decode(type, from: url) { playlist, error in
                guard error == nil else {
                    continuation.resume(throwing: error!)
                    return
                }
                
                guard let playlist = playlist else {
                    continuation.resume(throwing: "No playlist")
                    return
                }
                
                continuation.resume(returning: playlist)
            }
        }
    }
}

#if canImport(Combine)

import protocol Combine.TopLevelDecoder

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension M3U8Decoder: TopLevelDecoder {
    public typealias Input = Data
}

#endif
