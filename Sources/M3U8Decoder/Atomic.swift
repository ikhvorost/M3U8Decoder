//  Atomic.swift
//
//  Created by Iurii Khvorost <iurii.khvorost@gmail.com> on 2025/03/20.
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


@discardableResult
func synchronized<T>(_ obj: AnyObject, closure: () -> T) -> T {
  objc_sync_enter(obj)
  defer {
    objc_sync_exit(obj)
  }
  return closure()
}

class Atomic<T>: @unchecked Sendable {
  var _value: T
  
  init(_ value: T) {
    _value = value
  }
  
  var value: T {
    get {
      synchronized(self) { _value }
    }
    set {
      synchronized(self) { _value = newValue }
    }
  }
}

final class AtomicArray<U>: Atomic<Array<U>>, @unchecked Sendable {
  
  convenience init(repeating: U, count: Int) {
    self.init([U](repeating: repeating, count: count))
  }
  
  subscript(i: Int) -> U {
    get {
      synchronized(self) { _value[i] }
    }
    set {
      synchronized(self) { _value[i] = newValue }
    }
  }
  
  var count: Int {
    synchronized(self) { _value.count }
  }
  
  var first: U? {
    synchronized(self) { _value.first }
  }
  
  func append(_ item: U) {
    synchronized(self) {
      _value.append(item)
    }
  }
}
