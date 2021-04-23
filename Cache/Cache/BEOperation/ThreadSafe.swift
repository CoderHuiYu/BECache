//
//  ThreadSafe.swift
//  Cache
//
//  Created by yuhui on 2021/4/23.
//

import Foundation


class Person {
    var name: String
    var age: Int
    
    init(name: String, age: Int) {
        self.name = name
        self.age = age
    }
}

class ThreadSafe {
    public typealias Handler = () -> Void
    private lazy var mutex: pthread_mutex_t = {
        var mutex = pthread_mutex_t()
        var attr: pthread_mutexattr_t = pthread_mutexattr_t()
        pthread_mutexattr_init(&attr)
        pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE)
        pthread_mutex_init(&mutex, &attr)
        return mutex
    }()
    
    var group = DispatchGroup()
   
    var serialQueueBusy = false
    private var concurrentSemaphore = DispatchSemaphore(value: 5);
    var semaphorequeue = DispatchQueue(label: "semaphorequeue")
    var serialQueue = DispatchQueue(label: "serial")
    var conCurrentQueue = DispatchQueue(label: "conCurrentQueue", attributes: .concurrent)
    var array = [Person]()
    
    init() {
        for i in 1..<10 {
            group.enter()
            let p = Person(name: "A\(i)", age: i)
            array.append(p)
        }
    }
    
    func test() {
        excute()
    }
    
    func excute() {
        lock()
        if serialQueueBusy == false {
            serialQueueBusy = true
            guard let p = item() else { return }
            serialQueue.async { [weak self] in
                guard let self = self else { return }
                print("1-index == \(String(describing: p.age))")
                self.group.leave()
                self.lock()
                self.serialQueueBusy = false
                self.unlock()
                self.excute()
            }
        }
        unlock()
        
        semaphorequeue.async { [weak self] in
           
            guard let self = self else { return }
            self.concurrentSemaphore.wait()
            self.lock()
            guard let p = self.item() else { return }
            self.unlock()
            self.conCurrentQueue.async {
                print("2-index == \(String(describing: p.age))")
                self.group.leave()
                self.concurrentSemaphore.signal()
            }
            
        }
    }

    
    func item() -> Person? {
        let p = array.first
        array.removeAll(where: { $0 === p } )
        return p
    }
    
    private func lockOperation(handler: Handler) {
        lock()
        handler()
        unlock()
    }
    
    private func lock() { pthread_mutex_trylock(&mutex) }
    private func unlock() { pthread_mutex_unlock(&mutex) }
    deinit { pthread_mutex_destroy(&mutex) }
    
}
