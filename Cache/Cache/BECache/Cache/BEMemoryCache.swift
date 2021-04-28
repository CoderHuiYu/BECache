//
//  BEMemoryCache.swift
//  Cache
//
//  Created by yuhui on 2021/4/28.
//

import Foundation

 class BEMemoryCache {
    
    var name: String = ""
    var totalCost: Int {
        set { lock(); _totalCost = newValue; unlock() }
        get { return get(value: _totalCost) }
    }
    var costLimit: Int {
        set { lock(); _costLimit = newValue; unlock() }
        get { return get(value: _costLimit) }
    }
    var ageLimit = TimeInterval()
    var ttlCache = true // 存的对象有更长的保存周期
    var removeAllObjectsOnMemoryWarning = true
    var removeAllObjectsOnEnteringBackground = false
    
    private var _name: String = ""
    private var _totalCost = 0
    private var _costLimit = 0
    private var _ageLimit = TimeInterval()
    private var _willAddObjectHandler: BECacheObjectHandler?
    private var _willRemoveObjectHandler: BECacheObjectHandler?
    private var _willRemoveAllObjectsHandler: BECacheHandler?
    private var _didAddObjectHandler: BECacheObjectHandler?
    private var _didRemoveObjectHandler: BECacheObjectHandler?
    private var _didRemoveAllObjectsHandler: BECacheHandler?
    
    var willAddObjectHandler: BECacheObjectHandler? {
        set { lock(); _willAddObjectHandler = newValue; unlock() }
        get { return get(value: _willAddObjectHandler) }
    }
    var willRemoveObjectHandler: BECacheObjectHandler? {
        set { lock(); _willRemoveObjectHandler = newValue; unlock() }
        get { return get(value: _willRemoveObjectHandler) }
    }
    var willRemoveAllObjectsHandler: BECacheHandler? {
        set { lock(); _willRemoveAllObjectsHandler = newValue; unlock() }
        get { return get(value: _willRemoveAllObjectsHandler) }
    }
    var didAddObjectHandler: BECacheObjectHandler? {
        set { lock(); _didAddObjectHandler = newValue; unlock() }
        get { return get(value: _didAddObjectHandler) }
    }
    var didRemoveObjectHandler: BECacheObjectHandler?{
        set { lock(); _didRemoveObjectHandler = newValue; unlock() }
        get { return get(value: _didRemoveObjectHandler) }
    }
    var didRemoveAllObjectsHandler: BECacheHandler? {
        set { lock(); _didRemoveAllObjectsHandler = newValue; unlock() }
        get { return get(value: _didRemoveAllObjectsHandler) }
    }
    
    var didReceiveMemoryWarningBlock: BECacheHandler?
    var didEnterBackgroundBlock: BECacheHandler?
    
    // private
    private var operationQueue: BEOperationQueue?
    private var mutex: pthread_mutex_t = {
        var mutex = pthread_mutex_t()
        var attr: pthread_mutexattr_t = pthread_mutexattr_t()
        pthread_mutexattr_init(&attr)
        pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE)
        pthread_mutex_init(&mutex, &attr)
        return mutex
    }()
    
    private var dictionary = [String: Any]()
    private var createdDates = [String: Date]()
    private var accessDates = [String: Any]()
    private var costs = [String: Int]()
    private var ageLimits = [String: TimeInterval]()
    
    static let sharedCache = BEMemoryCache()
    /// LifeCycle
    init(name: String? = nil, operationQueue: BEOperationQueue? = BEOperationQueue.sharedOperationQueue) {
        self.name = name ?? ""
        self.operationQueue = operationQueue
        
    }
    
    func trimToCostAsync(cost: Int, completion: BECacheHandler?) {
        
    }
    
    func trimToCostByDateAsync(cost: Int, completion: BECacheHandler?) {
        
    }
    
    //- (void)enumerateObjectsWithBlockAsync:(PINCacheObjectEnumerationBlock)block completionBlock:(nullable PINCacheBlock)completionBlock;
    
    func trimToCost(cost: Int) {
        
    }
    
    func trimToCostByDate(cost: Int) {
        
    }
    
    //- (void)enumerateObjectsWithBlock:(PIN_NOESCAPE PINCacheObjectEnumerationBlock)block;
   
    /// lock
    private func lockOperation(handler: Handler) {
        lock()
        handler()
        unlock()
    }
    
    private func lockOperation<T>(handler: ResultHandler<T>) -> T {
        lock()
        let result = handler()
        unlock()
        return result
    }
    
    private func lock() { pthread_mutex_lock(&mutex) }
    private func unlock() { pthread_mutex_unlock(&mutex) }
    deinit { pthread_mutex_destroy(&mutex) }
    
    // auxiliary function
    private func get<T>(value: T) -> T {
        let tmp: T
        lock()
        tmp = value
        unlock()
        return tmp
    }
}

extension BEMemoryCache : BECaching {
    
    func containsObjectForKeyAsync(key: String, completion: BECacheObjectContainmentHandler?) {
        
    }
    
    func objectForKeyAsync(key: String, completion: BECacheObjectHandler?) {
        
    }
    
    func setObjectAsync(object: Any, key: String, completion: BECacheObjectHandler?) {
        
    }
    
    func setObjectAsync(object: Any, key: String, ageLimit: TimeInterval, completion: BECacheObjectHandler?) {
        
    }
    
    func setObjectAsync(object: Any, key: String, cost: Int, completion: BECacheObjectHandler?) {
        
    }
    
    func setObjectAsync(object: Any, key: String, cost: Int, ageLimit: TimeInterval, completion: BECacheObjectHandler?) {
        
    }
    
    func removeObjectForKeyAsync(key: String, completion: BECacheObjectHandler?) {
        
    }
    
    func trimToDateAsync(date: Date, completion: BECacheHandler?) {
        
    }
    
    func removeExpiredObjectsAsync(Handler: BECacheHandler?) {
        
    }
    
    func removeAllObjectsAsync(Handler: BECacheHandler?) {
        
    }
    
    func containsObjectForKey(key: String) -> Bool {
        return true
    }
    
    func objectForKey(key: String) -> Any? {
        return nil
    }
    
    func setObject(object: Any?, key: String) {
        
    }
    
    func setObject(object: Any?, key: String, ageLimit: TimeInterval) {
        
    }
    
    func setObject(object: Any?, key: String, cost: Int) {
        
    }
    
    func setObject(object: Any?, key: String, cost: Int, ageLimit: TimeInterval) {
        assert(ageLimit <= 0.0 || (ageLimit > 0 && ttlCache), "ttlCache must be set to YES if setting an object-level age limit.")
        
        if key.count == 0 || object == nil { return }
        lock()
        let willAddObjectHandler = _willAddObjectHandler
        let didAddObjectHandler = _didAddObjectHandler
        let costLimit = _costLimit
        unlock()
        
        willAddObjectHandler?(self, key, object)
        
        lock()
        let oldCost = costs[key] ?? 0
        _totalCost -= oldCost

        let dateNow = Date()
        dictionary[key] = object
        createdDates[key] = dateNow
        costs[key] = cost
        
        if ageLimit > 0.0 { ageLimits[key] = ageLimit } else { ageLimits.removeValue(forKey: key) }
        
        _totalCost += cost
        unlock()
        
        didAddObjectHandler?(self, key, object)
        if costLimit > 0 { trimToCostByDate(cost: costLimit) }
    }
    
    func removeObjectForKey(key: String) {
        
    }
    
    func trimToDate(date: Date) {
        
    }
    
    func removeExpiredObjects() {
        
    }
    
    func removeAllObjects() {
        
    }
    
}
