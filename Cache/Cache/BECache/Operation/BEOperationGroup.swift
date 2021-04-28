//
//  BEOperationGroup.swift
//  Cache
//
//  Created by yuhui on 2021/4/27.
//

import Foundation
protocol BEGroupOperationReference {}
extension NSNumber : BEGroupOperationReference {}

class BEOperationGroup {
    
    private var mutex: pthread_mutex_t = {
        var mutex = pthread_mutex_t()
        var attr: pthread_mutexattr_t = pthread_mutexattr_t()
        pthread_mutexattr_init(&attr)
        pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE)
        pthread_mutex_init(&mutex, &attr)
        return mutex
    }()
    
    private var operationQueue: BEOperationQueue?
    private var operations = [OperationItem]()
    private var operationReferences = [BEGroupOperationReference]()
    private var groupToOperationReferences = [NSNumber:BEOperationReference]()
    private var operationPriorities = [BEOperationQueuePriority]()
    private var operationReferenceCount: Int = 0
    private var group = DispatchGroup()
    private var started = false, canceled = false
    var _completion: OperationItem?
    var completion: OperationItem? {
        willSet {
            lock()
            assert(started == false && canceled == false, "Operation group already started or canceled.")
            if started == false && canceled == false {
               _completion = completion
            }
            unlock()
        }
    }
  
    required init(queue operationQueue: BEOperationQueue) { self.operationQueue = operationQueue }
    
    func add(operation op:@escaping OperationItem) -> BEGroupOperationReference? { return add(operation: op, with: .default) }
    
    func add(operation op: @escaping OperationItem, with priority: BEOperationQueuePriority) -> BEGroupOperationReference? {
        lock()
        assert(started == false && canceled == false, "Operation group already started or canceled.")
        var reference: BEGroupOperationReference?
        if started == false && canceled == false {
            reference = locked_nextOperationReference()
            operations.append(op)
            operationPriorities.append(priority)
            operationReferences.append(reference!)
        }
        unlock()
        return reference
    }
    
    func start() {
        lock()
        assert(canceled == false, "Operation group canceled.")
        if started == false && canceled == false {
            for ( index, op ) in operations.enumerated() {
                group.enter()
                // excute operation and let the op's refercenc connect to groupOperation's reference
                let reference: BEOperationReference? = operationQueue?.scheduleOperation(with: { [weak self] in
                    if let self = self { op(); self.group.leave() }
                }, priority: operationPriorities[index])
                if let refer = reference {
                    groupToOperationReferences[operationReferences[index] as! NSNumber] = refer
                }
            }
            
            if _completion != nil{
                group.notify(queue: .global(), work: DispatchWorkItem { [weak self] in
                    if let self = self { self.runCompletionIfNeeded() }
                })
            }
            operations.removeAll()
            operationPriorities.removeAll()
            operationReferences.removeAll()
        }
        unlock()
    }
    
    func cancel() {
        lock()
        canceled = true
        
        groupToOperationReferences.forEach { (_, value) in
            operationQueue?.cancle(operationReference: value)
            group.leave()
        }
        operations.removeAll()
        operationPriorities.removeAll()
        operationReferences.removeAll()
        groupToOperationReferences.removeAll()
        _completion = nil
        unlock()
    }
    
    func waitUntilComplete() {
        // 有点多此一举,已经有notify了
        start()
        let _ = group.wait(timeout: .distantFuture)
        runCompletionIfNeeded()
    }
    
    private func runCompletionIfNeeded() {
        // can be optimized
        let com: OperationItem?
        lock()
        com = _completion
        _completion = nil
        unlock()
        com?()
    }
    
    private func locked_nextOperationReference() -> BEGroupOperationReference {
        ++operationReferenceCount
        let reference = NSNumber(value: operationReferenceCount)
        return reference
    }
    
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
    
}
