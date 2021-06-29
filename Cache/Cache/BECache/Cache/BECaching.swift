//
//  BEOperationQueue.swift
//  Cache
//
//  Created by yuhui on 2021/4/21.
//

import Foundation

protocol CacheObjectSubscripting {
    /**
     * This method enables using literals on the receiving object, such as `id object = cache[@"key"];`.
     */
    func objectForKeyedSubscript(key: String) -> Any
    /**
     * This method enables using literals on the receiving object, such as `cache[@"key"] = object;`.*
     */
    func setObject(object: Any, key keyedSubcript: String)
}

typealias BECacheHandler = ((_ cache: BECaching) -> Void)
typealias BECacheObjectHandler = ((_ cache: BECaching, _ key: String, _ object: Any?) -> Void)
typealias BECacheObjectContainmentHandler = ((_ containsObject: Bool ) -> Void)

protocol BECaching {
   
    var name: String { get }
    
    func containsObjectForKeyAsync(key: String, completion: BECacheObjectContainmentHandler?)
    func objectForKeyAsync(key: String, completion: BECacheObjectHandler?)
    
    func setObjectAsync(object: Any, key: String, completion: BECacheObjectHandler?)
    func setObjectAsync(object: Any, key: String, ageLimit: TimeInterval, completion: BECacheObjectHandler?)
    func setObjectAsync(object: Any, key: String, cost: Int, completion: BECacheObjectHandler?)
    func setObjectAsync(object: Any, key: String, cost: Int, ageLimit: TimeInterval, completion: BECacheObjectHandler?)
    
    func removeObjectForKeyAsync(key: String, completion: BECacheObjectHandler?)
    func trimToDateAsync(date: Date, completion: BECacheHandler?)
    func removeExpiredObjectsAsync(Handler: BECacheHandler?)
    func removeAllObjectsAsync(Handler: BECacheHandler?)
    
    func containsObjectForKey(key: String) -> Bool
    func objectForKey(key: String) -> Any?
    
    func setObject(object: Any?, key: String)
    func setObject(object: Any?, key: String, ageLimit: TimeInterval)
    func setObject(object: Any?, key: String, cost: Int)
    func setObject(object: Any?, key: String, cost: Int, ageLimit: TimeInterval)
    
    func removeObjectForKey(key: String)
    func trimToDate(date: Date)
    func removeExpiredObjects()
    func removeAllObjects()
}

