//
//  SafeArray.swift
//  Cache
//
//  Created by yuhui on 2021/4/23.
//

import Foundation
class SafeArray<Element: Equatable> {
    private var array: Array<Element> = []
    private let lock = NSLock()
    
    subscript(index: Int) -> Element? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return array.indices ~= index ? array[index] : nil
        }
        
        set {
            lock.lock()
            defer { lock.unlock() }
            if let newValue = newValue, array.indices ~= index {
                array[index] = newValue
            }
        }
    }
    
    var count : Int {
        lock.lock()
        defer { lock.unlock() }
        return array.count
    }
    
    func contains(elememt: Element) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return array.contains(elememt)
    }
    
    func reserveCapacity(_ count: Int) {
        lock.lock()
        defer { lock.unlock() }
        array.reserveCapacity(count)
    }
    
    func append(_ element: Element) {
        lock.lock()
        defer { lock.unlock() }
        array += [element]
    }
    
    func removeAll() {
        lock.lock()
        defer { lock.unlock() }
        array = []
    }
    
    func remove(element: Element) {
        lock.lock()
        defer { lock.unlock() }
        array.removeAll(where: { $0 == element })
    }
}
