//
//  BEOperationQueue.swift
//  Cache
//
//  Created by yuhui on 2021/4/21.
//

import Foundation

extension Int {
    static prefix func ++ (count: inout Int) { count += 1 }
}

enum BEOperationQueuePriority: Int {
    case low
    case `default`
    case high
}

protocol BEOperationReference {}
extension NSNumber : BEOperationReference {}
public typealias OperationItem = () -> Void

class BEOperation {
    
    var priority: BEOperationQueuePriority = .default
    lazy var workItems = [OperationItem]()
    var identifier: String?
    var reference: BEOperationReference?
    static func operation(with priority: BEOperationQueuePriority = .default, identifier: String? = nil, reference: BEOperationReference?, workitem: @escaping OperationItem) -> BEOperation {
        let operation = BEOperation()
        operation.priority = priority
        operation.add(with: workitem)
        operation.identifier = identifier
        operation.reference = reference
        return operation
    }
    
    func add(with workItem: @escaping OperationItem) {
        workItems.append(workItem)
    }
    
}

class BEOperationQueue {
    /**
     * operation 是对workitem的一层包装，一个operation可以管理多个workItem
     * operationQueue可以管理多个operation
     *  最后，operationQueue.通过串行队列和并行队列来控制operation里面的workitem的执行
     */
    private lazy var mutex: pthread_mutex_t = {
        var mutex = pthread_mutex_t()
        var attr: pthread_mutexattr_t = pthread_mutexattr_t()
        pthread_mutexattr_init(&attr)
        pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE)
        pthread_mutex_init(&mutex, &attr)
        return mutex
    }()
    
    private var maxConcurrentOperations = 2 { didSet { maxConcurrentOperationsChanged(oldValue: oldValue) } }
    static let sharedOperationQueue = BEOperationQueue()
    private var queueOperations = [BEOperation]()
    private var lowPriorityOperations = [BEOperation]()
    private var defaultPriorityOperations = [BEOperation]()
    private var highPriorityOperations = [BEOperation]()
    
    // Queue
    private var group = DispatchGroup()
    private var serialQueue = DispatchQueue(label: "BEOperation Serial Queue")
    private var semaphoreQueue = DispatchQueue(label: "BEOperation Semaphore Queue")
    private var concurrentQueue = DispatchQueue(label: "BEOperation Concurrent Queue", attributes: .concurrent)
    
    private var operationReferenceCount = 0
    private var referenceToOperations: [NSNumber : BEOperation] = [:]
    private var concurrentSemaphore = DispatchSemaphore(value: 1);
    private var serialQueueBusy = false
    private var identifierToOperations: [String : BEOperation] = [:]
    
    public typealias Handler = () -> Void
    public typealias ResultHandler<T> = () -> T
    
    init(maxConcurrentOperations: Int=2) { self.maxConcurrentOperations = maxConcurrentOperations }
    
    @discardableResult func scheduleOperation(with workItem: @escaping OperationItem) -> BEOperationReference {
        return scheduleOperation(with: workItem, priority: .default)
    }
    
    @discardableResult func scheduleOperation(with workItem: @escaping OperationItem, priority: BEOperationQueuePriority = .default) -> BEOperationReference{
        // when the workItem come in, i will arrange it a reference
        let operation = BEOperation.operation(with: priority, reference: nextOperationReference(), workitem: workItem)
        lockOperation { locked_addOperation(with: operation) }
        scheduleNextOperation(with: false)
        return operation.reference!
    }
    
    func scheduleOperation(with workItem: OperationItem, priority: BEOperationQueuePriority = .default, completion: OperationItem) {
    }
    
    func cancleAll() {
        lockOperation {
            referenceToOperations.values.forEach { locked_cancle(operationReference: $0.reference) }
        }
    }
    
    func cancle(operationReference: BEOperationReference) -> Bool {
        lock()
        let success = locked_cancle(operationReference: operationReference)
        unlock()
        return success
    }
    
    private func scheduleNextOperation(with onlyCheckSerial: Bool) {
        //        print("----进入-----")
        lockOperation {
            if serialQueueBusy == false {
                guard let operation = locked_nextOperationByQueue() else { return }
                
                serialQueueBusy = true
                serialQueue.async { [weak self] in
                    //                        print("----执行1-----")
                    guard let self = self else { return }
                    operation.workItems.forEach { $0() }
                    self.group.leave()
                    //                        print("--------------qqqqqqleave------------------")
                    self.lockOperation { self.serialQueueBusy = false }
                    self.scheduleNextOperation(with: true)
                }
            }

        }
        
        if onlyCheckSerial { return }
        if maxConcurrentOperations < 2 { return }
        
        semaphoreQueue.async { [weak self] in
//            print("----执行2-----")
            guard let self = self else { return }
            self.concurrentSemaphore.wait()
            self.lock()
            let op = self.locked_nextOperationByPriority()
            self.unlock()
            guard let operation = op else { self.concurrentSemaphore.signal(); return }
            self.concurrentQueue.async {
                operation.workItems.forEach { $0() }
                self.group.leave()
//                print("--------------qqqqqqleave------------------")
                self.concurrentSemaphore.signal()
            }
        }
    }
        
    private func locked_addOperation(with operation: BEOperation) {
        group.enter()
//        print("--------------enter------------------")
        priorityQueueAdded(with: operation)
        queueOperations.append(operation)
        referenceToOperations[operation.reference as! NSNumber] = operation
        if let identifier = operation.identifier { identifierToOperations[identifier] = operation }
    }
    
    private func priorityQueueAdded(with op: BEOperation) {
        switch op.priority {
        case .low: lowPriorityOperations.append(op)
        case .default: defaultPriorityOperations.append(op)
        case .high: highPriorityOperations.append(op)
        }
    }
    
    private func priorityQueueRemoved(with op: BEOperation) -> Bool {
        switch op.priority {
        case .low:
            if lowPriorityOperations.contains(where: { $0 === op }) {
                lowPriorityOperations.removeAll(where: { $0 === op })
                return true
            }
        case .default:
            if defaultPriorityOperations.contains(where: { $0 === op }) {
                defaultPriorityOperations.removeAll(where: { $0 === op })
                return true
            }
        case .high:
            if highPriorityOperations.contains(where: { $0 === op }) {
                highPriorityOperations.removeAll(where: { $0 === op })
                return true
            }
        }
        return false
    }
    
    
    private func locked_nextOperationByQueue() -> BEOperation? {
        let operation = queueOperations.first
        locked_removeOperation(with: operation)
        return operation
    }
    private func locked_nextOperationByPriority() -> BEOperation? {
        var op = highPriorityOperations.first
        if op == nil { op = defaultPriorityOperations.first }
        if op == nil { op = lowPriorityOperations.first }
        if op != nil { locked_removeOperation(with: op!) }
        return op
    }
    
   @discardableResult private func locked_removeOperation(with operation: BEOperation?) -> Bool {
        guard let op = operation else { return false }
    print("---delete----\(String(describing: op.reference))")
        guard priorityQueueRemoved(with: op) else { return false}
        queueOperations.removeAll(where: { $0 === op })
        guard let identifier = op.identifier else { return false}
        identifierToOperations.removeValue(forKey: identifier)
        return true
    }
    
   
   @discardableResult private func locked_cancle(operationReference: BEOperationReference?) -> Bool {
        guard let reference = operationReference else { return false }
        let op = referenceToOperations[reference as! NSNumber]
        let success = locked_removeOperation(with: op)
        if success {
            group.leave()
        }
        return success
    }
    
    private func nextOperationReference() -> BEOperationReference {
        lock()
        ++operationReferenceCount
        let reference = NSNumber(value: operationReferenceCount)
        unlock()
        return reference
    }
        
    private func maxConcurrentOperationsChanged(oldValue: Int) {
        lock()
        var difference = maxConcurrentOperations - oldValue
        unlock()
        
        semaphoreQueue.async { [weak self] in
            guard let self = self else { return }
            while difference != 0 {
                if difference > 0 {
                    self.concurrentSemaphore.signal()
                    difference -= 1
                }else {
                    self.concurrentSemaphore.wait()
                    difference += 1
                }
            }
        }
    }
    
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
    
    private func lock() { pthread_mutex_trylock(&mutex) }
    private func unlock() { pthread_mutex_unlock(&mutex) }
    deinit { pthread_mutex_destroy(&mutex) }
}



