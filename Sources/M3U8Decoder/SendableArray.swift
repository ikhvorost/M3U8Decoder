//  SendableArray.swift
//
//  Created by Iurii Khvorost <iurii.khvorost@gmail.com> on 2025/02/28.
//  Copyright © 2025 Iurii Khvorost. All rights reserved.
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

class SendableArray<T>: @unchecked Sendable {
  private(set) var array: [T]
  
  var count: Int {
    array.count
  }
  
  var first: T? {
    array.first
  }
  
  init() {
    array = [T]()
  }
  
  init(repeating: T, count: Int) {
    array = [T](repeating: repeating, count: count)
  }
  
  func append(_ value: T) {
    array.append(value)
  }
  
  subscript(i: Int) -> T {
    get {
      array[i]
    }
    set {
      array[i] = newValue
    }
  }
}
