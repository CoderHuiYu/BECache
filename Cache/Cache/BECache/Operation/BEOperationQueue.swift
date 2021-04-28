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
    case low, `default`, high
}

protocol BEOperationReference {}
extension NSNumber : BEOperationReference {}
public typealias OperationItem = () -> Void
public typealias Handler = () -> Void
public typealias ResultHandler<T> = () -> T

class BEOperation : Equatable {
    static func == (lhs: BEOperation, rhs: BEOperation) -> Bool { return lhs === rhs }

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
    private var mutex: pthread_mutex_t = {
        var mutex = pthread_mutex_t()
        var attr: pthread_mutexattr_t = pthread_mutexattr_t()
        pthread_mutexattr_init(&attr)
        pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE)
        pthread_mutex_init(&mutex, &attr)
        return mutex
    }()
    
    var _maxConcurrentOperations: Int {
        set { setMaxConcurrentOperationsChanged(newValue: newValue) }
        get { return getMaxConcurrentOperations() }
    }
    
    private var maxConcurrentOperations = 2
    static let sharedOperationQueue = BEOperationQueue.init(maxConcurrentOperations: 2)
    
    private var queueOperations = SafeArray<BEOperation>()
    private var lowPriorityOperations = SafeArray<BEOperation>()
    private var defaultPriorityOperations = SafeArray<BEOperation>()
    private var highPriorityOperations = SafeArray<BEOperation>()
    
    // Queue
    private var group = DispatchGroup()
    private var serialQueue = DispatchQueue(label: "BEOperation Serial Queue")
    private var semaphoreQueue = DispatchQueue(label: "BEOperation Semaphore Queue")
    private var concurrentQueue = DispatchQueue(label: "BEOperation Concurrent Queue", attributes: .concurrent)
    
    private var concurrentSemaphore: DispatchSemaphore?
    private var serialQueueBusy = false
    private var operationReferenceCount = 0
    
    private var referenceToOperations: [NSNumber : BEOperation] = [:]
    private var identifierToOperations: [String : BEOperation] = [:]
    
    init(maxConcurrentOperations: Int=2) {
        _maxConcurrentOperations = maxConcurrentOperations
        concurrentSemaphore = DispatchSemaphore(value: maxConcurrentOperations - 1)
    }
    
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
        lockOperation { referenceToOperations.values.forEach { locked_cancle(operationReference: $0.reference) } }
    }
    
    @discardableResult func cancle(operationReference: BEOperationReference) -> Bool {
        lock()
        let success = locked_cancle(operationReference: operationReference)
        unlock()
        return success
    }
    
    private func scheduleNextOperation(with onlyCheckSerial: Bool) {
        /**
         *   serialQueue.async  {
         *       这里面不需要 写 [weak self] 或者 [unowned self] 原因是gcd内部会对self有一个强引用
         *    }
         */
        lock()
        if serialQueueBusy == false {
            if let operation = locked_nextOperationByQueue() {
                serialQueueBusy = true
                serialQueue.async {
                    operation.workItems.forEach { $0() }
                    self.group.leave()
                    self.lockOperation { self.serialQueueBusy = false }
                    self.scheduleNextOperation(with: true)
                }
            }
        }
        unlock()
        
        if onlyCheckSerial { return }
        if maxConcurrentOperations < 2 { return }
        
        semaphoreQueue.async {
            self.concurrentSemaphore?.wait()
            self.lock()
            let op = self.locked_nextOperationByPriority()
            self.unlock()
            if let operation = op {
                self.concurrentQueue.async {
                    operation.workItems.forEach { $0() }
                    self.group.leave()
                    self.concurrentSemaphore?.signal()
                }
            } else {
                self.concurrentSemaphore?.signal()
            }
        }
    }
        
    private func locked_addOperation(with operation: BEOperation) {
        group.enter()
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
            if lowPriorityOperations.contains(elememt: op) {
                lowPriorityOperations.remove(element: op)
                return true
            }
        case .default:
            if defaultPriorityOperations.contains(elememt: op) {
                defaultPriorityOperations.remove(element: op)
                return true
            }
        case .high:
            if highPriorityOperations.contains(elememt: op) {
                highPriorityOperations.remove(element: op)
                return true
            }
        }
        return false
    }
    
    private func locked_nextOperationByQueue() -> BEOperation? {
        let operation = queueOperations[0]
        return locked_removeOperation(with: operation) ? operation : nil
    }
    
    private func locked_nextOperationByPriority() -> BEOperation? {
        guard let op = highPriorityOperations[0] ?? defaultPriorityOperations[0] ?? lowPriorityOperations[0] else { return nil }
        return locked_removeOperation(with: op) ? op : nil
    }
    
    @discardableResult private func locked_removeOperation(with operation: BEOperation?) -> Bool {
        guard let op = operation else { return false }
        if priorityQueueRemoved(with: op) {
            queueOperations.remove(element: op)
            if let identifier = op.identifier {
                identifierToOperations.removeValue(forKey: identifier)
            }
            return true
        }
        return false
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
        
    private func getMaxConcurrentOperations() -> Int {
        lock()
        let max = maxConcurrentOperations
        unlock()
        return max
    }
    
    private func setMaxConcurrentOperationsChanged(newValue: Int) {
        lock()
        var difference = newValue - maxConcurrentOperations
        self.maxConcurrentOperations = newValue
        unlock()
        
        if difference == 0  { return }
        
        semaphoreQueue.async { [weak self] in
            guard let self = self else { return }
            while difference != 0 {
                if difference > 0 {
                    self.concurrentSemaphore?.signal()
                    difference -= 1
                }else {
                    self.concurrentSemaphore?.wait()
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
    
    private func lock() { pthread_mutex_lock(&mutex) }
    private func unlock() { pthread_mutex_unlock(&mutex) }
    deinit { pthread_mutex_destroy(&mutex) }
}
