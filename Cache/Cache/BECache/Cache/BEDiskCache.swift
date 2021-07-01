//
//  BEDiskCache.swift
//  Cache
//
//  Created by yuhui on 2021/7/1.
//

import UIKit

class BEDiskCache: NSObject {

}

extension BEDiskCache : BECaching {
    var name: String {
        <#code#>
    }
    
    func containsObjectForKeyAsync(key: String, completion: BECacheObjectContainmentHandler?) {
        <#code#>
    }
    
    func objectForKeyAsync(key: String, completion: BECacheObjectHandler?) {
        <#code#>
    }
    
    func setObjectAsync(object: Any, key: String, completion: BECacheObjectHandler?) {
        <#code#>
    }
    
    func setObjectAsync(object: Any, key: String, ageLimit: TimeInterval, completion: BECacheObjectHandler?) {
        <#code#>
    }
    
    func setObjectAsync(object: Any, key: String, cost: Int, completion: BECacheObjectHandler?) {
        <#code#>
    }
    
    func setObjectAsync(object: Any, key: String, cost: Int, ageLimit: TimeInterval, completion: BECacheObjectHandler?) {
        <#code#>
    }
    
    func removeObjectForKeyAsync(key: String, completion: BECacheObjectHandler?) {
        <#code#>
    }
    
    func trimToDateAsync(date: Date, completion: BECacheHandler?) {
        <#code#>
    }
    
    func removeExpiredObjectsAsync(Handler: BECacheHandler?) {
        <#code#>
    }
    
    func removeAllObjectsAsync(Handler: BECacheHandler?) {
        <#code#>
    }
    
    func containsObjectForKey(key: String) -> Bool {
        <#code#>
    }
    
    func objectForKey(key: String) -> Any? {
        <#code#>
    }
    
    func setObject(object: Any?, key: String) {
        <#code#>
    }
    
    func setObject(object: Any?, key: String, ageLimit: TimeInterval) {
        <#code#>
    }
    
    func setObject(object: Any?, key: String, cost: Int) {
        <#code#>
    }
    
    func setObject(object: Any?, key: String, cost: Int, ageLimit: TimeInterval) {
        
    }
    
    func removeObjectForKey(key: String) {
        <#code#>
    }
    
    func trimToDate(date: Date) {
        <#code#>
    }
    
    func removeExpiredObjects() {
        <#code#>
    }
    
    func removeAllObjects() {
        <#code#>
    }
    
    
}
