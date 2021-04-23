//
//  BECache.swift
//  Cache
//
//  Created by yuhui on 2021/4/21.
//

import Foundation

class BECache : BECaching {
    
    private lazy var dataMap: [ String: Codable] = [:]
    
    func set(object: Codable, key: String) {
        dataMap[key] = object
    }
    
    func get(key: String) -> Codable? {
        return dataMap[key]
    }
    
}

public protocol BECaching : AnyObject {
    func set(object: Codable, key: String)
    func get(key: String) -> Codable?
}
