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
        get { return get(value: _totalCost) }
    }
    
    var costLimit: Int {
        set { lock(); _costLimit = newValue; unlock() }
        get { return get(value: _costLimit) }
    }
    var ageLimit = TimeInterval()
    // 存的对象有更长的保存周期
    var ttlCache: Bool {
        set { lock(); _ttlCache = newValue; unlock() }
        get { return get(value: _ttlCache) }
    }
    var removeAllObjectsOnMemoryWarning = true
    var removeAllObjectsOnEnteringBackground = false
    
    private var _name: String = ""
    private var _totalCost = 0
    private var _costLimit = 0
    private var _ttlCache = false
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
    private var accessDates = [String: Date]()
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
        trimToCostLimitByDate(limit: cost)
    }
    
    func trimToCostLimitByDate(limit: Int) {
        if ttlCache { removeExpiredObjects() }
        var totalCost = 0
        
        lock()
        totalCost = _totalCost
        let keysSortedByAccessDate = accessDates.sorted { return $0.value.compare($1.value) == .orderedAscending }
        unlock()
        
        if totalCost <= limit { return }
        
        for (key,_) in keysSortedByAccessDate {
            removeObjectAndExecuteBlocksForKey(key: key)
            
            lock()
            totalCost = _totalCost // 执行完后removeObjectAndExecuteBlocksForKey(key: key) _totalcost的值会发生变化
            unlock()
            
            //
            if totalCost <= limit { break }
        }
        
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
        setObject(object: object, key: key, cost: 0)
    }
    
    func setObject(object: Any?, key: String, ageLimit: TimeInterval) {
        setObject(object: object, key: key, cost: 0, ageLimit: ageLimit)
    }
    
    func setObject(object: Any?, key: String, cost: Int) {
        setObject(object: object, key: key, cost: cost, ageLimit: 0)
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

        let now = Date()
        dictionary[key] = object
        createdDates[key] = now
        accessDates[key] = now
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
        lock()
        // 这里先copy一份，这样是为了读写安全考虑
        let createdDates = createdDates
        let ageLimits = ageLimits
        unlock()
        
        let now = Date()
        for (key,ageLimit) in ageLimits {
            let try_createDate: Date? = createdDates[key]
            guard let createDate = try_createDate else { continue }
            
            let expirationDate: Date = createDate.addingTimeInterval(ageLimit)
            if expirationDate.compare(now) == .orderedAscending { // 根据时间进行比对
                removeObjectAndExecuteBlocksForKey(key: key)
            }
        }
    }
    
    private func removeObjectAndExecuteBlocksForKey(key: String) {
        lock()
        let objct = dictionary[key]
        let cost = costs[key]
        let willRemoveObjectHandler = _willRemoveObjectHandler
        let didRemoveObjectHandler = _didRemoveObjectHandler
        unlock()
        
        willRemoveObjectHandler?(self, key, objct)
        
        lock()
        _totalCost -= cost ?? 0
        dictionary.removeValue(forKey: key)
        createdDates.removeValue(forKey: key)
        accessDates.removeValue(forKey: key)
        costs.removeValue(forKey: key)
        ageLimits.removeValue(forKey: key)
        unlock()
        
        didRemoveObjectHandler?(self, key, objct)
    }
    
    func removeAllObjects() {
        
    }
    
}
