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

public class M3U8Decoder {
    
    public enum KeyDecodingStrategy {
        //case original?
        case snakeCase
        case camelCase
        case custom((_ key: String) -> String)
    }
    
    public var keyDecodingStrategy: KeyDecodingStrategy = .snakeCase
    public var dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .iso8601
    
    public init() {
    }
    
    public func decode<T>(_ type: T.Type, text: String) throws -> T where T : Decodable {
        let parser = M3U8Parser()
        parser.keyDecodingStrategy = keyDecodingStrategy
        guard let dict = parser.parse(text: text) else {
            throw "Bad data."
        }
        
        // Debug
        //print(dict)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = dateDecodingStrategy
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
        return try decode(type, text: text)
    }
    
    public func decode<T>(_ type: T.Type, url: URL) throws -> T where T : Decodable {
        let data = try Data(contentsOf: url)
        return try decode(type, from: data)
    }
    
    public func decode<T>(_ type: T.Type, url: URL, _ completion: @escaping (T?, Error?) -> Void) where T : Decodable {
        let request = URLRequest(url: url)
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil else {
                completion(nil, error!)
                return
            }
            
            guard let data = data, data.isEmpty == false else {
                completion(nil, "No data.")
                return
            }
            
            do {
                completion(try self.decode(type, from: data), nil)
            }
            catch {
                completion(nil, error)
            }
        }
        .resume()
    }
    
    // TODO: async
    // TODO: Combine
}
