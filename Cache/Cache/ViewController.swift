//
//  ViewController.swift
//  Cache
//
//  Created by yuhui on 2021/4/21.
//

import UIKit

class ViewController: UIViewController {

    var map: [String: Any] = [:]
    var test = TestBEOperationqueue()
    var array = [Int]() {
        didSet {
            pthread_mutex_lock(&mutex)
            
            pthread_mutex_unlock(&mutex)
            
        }
    }
//
//    var handler: Handler? = {
//        print("i am an handler")
//    }
    
    var group = DispatchGroup()
    var serailQueue = DispatchQueue(label: "test Serial Queue")
    private var mutex: pthread_mutex_t = {
        var mutex = pthread_mutex_t()
        var attr: pthread_mutexattr_t = pthread_mutexattr_t()
        pthread_mutexattr_init(&attr)
        pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE)
        pthread_mutex_init(&mutex, &attr)
        return mutex
    }()
    
    var ts = ThreadSafe()
    override func viewDidLoad() {
        super.viewDidLoad()
        let started = false
        assert(started == false, "Operation group already started or canceled.")
        
        print(1111111111)
//        let h = handler
//        handler = nil
//        h?()
//        handler = {
//            print(" i am changend")
//        }
//        handler?()
//        return
        
        
//       array = [ 2, 3, 4, 5]
//        for index in 2...100 {
//            array.append(index)
//        }
//        testLock()
//        testasync()
//        ts.test()
        
//        group_test()
//
//        test.test()
//        test.test2()
//        testLock()
       
    }
    
    private func testasync() {
        let queue = DispatchQueue(label: "11", attributes: .concurrent)
        queue.async {
            self.remove(t: 1)
        }
        queue.async {
            self.remove(t: 2)
        }
        queue.async {
            self.remove(t: 3)
        }
        
    }
    
    private func remove(t: Int) {
        //arraqy = [2...100]
        print("===\(t)")
        pthread_mutex_lock(&mutex)
        let num = array.removeFirst()
        print("thread = \(Thread.current)  element == \(num)")
        pthread_mutex_unlock(&mutex)
    }
    
    
    private func removeItem() {
        
    }
    
    private func group_test() {
        group.enter()
        serailQueue.async {
            print(1)
            self.group.leave()
        }
        
        group.enter()
        print(2)
        group.leave()
        
        group.enter()
        print(3)
        group.leave()
        
        group.notify(queue: serailQueue, work: DispatchWorkItem {
            print(4)
        })
        
        
    }
    
    private func testArray_set() {
        var array = [BECache2]()
        let a = BECache2()
        array.append(a)
        array.append(a)
        print(array)
        
      
     
    }
    
    
    private func testLock() {
        var array = [ 1, 2, 3 ]
        pthread_mutex_lock(&mutex)
        serailQueue.async {
            sleep(2)
            print(array.first ?? 0)
            array.removeFirst()
            print(array)
           
//            self.serailQueue.async {
//                print(3)
//            }
        }
        pthread_mutex_unlock(&mutex)
        
        print(array.first ?? 0)
    }
    
    deinit {
        pthread_mutex_destroy(&mutex)
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    func testArray() {
       var temp = array
        temp.append(1)
        print("temp = \(temp) , array= \(array)")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        test_serialQueue_async()
    }
    
    private func testDict() {
        var dict: [String: String] = ["a":"1", "b":"2", "c":"3"]
        dict.removeValue(forKey: "a")
        print(dict)
        print(dict.keys)
        dict.removeValue(forKey: "mmmmm")
        print(dict.values)
    }
    
    private func test_serialQueue_async() {
        let workItem1 = DispatchWorkItem { print("1") }
        let workItem2 = DispatchWorkItem { print("2") }
        let workItem3 = DispatchWorkItem { print("3") }
        let workItem4 = DispatchWorkItem { print("4") }
        let workItem5 = DispatchWorkItem { print("5") }
        let workItem6 = DispatchWorkItem { print("6") }
        let items = [workItem1, workItem2,workItem3, workItem4,workItem5, workItem6]
//        let serialQueue = DispatchQueue(label: "serialQueue")
        let conCurrentQueue = DispatchQueue(label: "conCurrentQueue", attributes: .concurrent)
//        serialQueue.async {
//            print("===000thread === \(Thread.current)")
//            conCurrentQueue.async {
//                items.forEach { workItem in
//                    workItem.perform()
//                    print("===111thread === \(Thread.current)")
//
//                }
//            }
//
//        }
        
        conCurrentQueue.async {
            items.forEach { workItem in
                workItem.perform()
                print("===2222thread === \(Thread.current)")

            }
        }
        
        conCurrentQueue.async {
            items.forEach { workItem in
                workItem.perform()
                print("===333thread === \(Thread.current)")

            }
        }
        
//        items.forEach { workItem in
//            conCurrentQueue.async {
//                workItem.perform()
//                print("===2222thread === \(Thread.current)")
//            }
//        }
        
        
    }
    
    private func test_pinOperationGroup() {
        let pinQueue = PINOperationQueue(maxConcurrentOperations: 100)
        let operationGroup = PINOperationGroup.asyncOperationGroup(with: pinQueue)
        operationGroup.addOperation ({
            print("---1---")
        }, with: .low)
        operationGroup.addOperation {
            print("---2---")
        }
        
        operationGroup.addOperation({
            print("---3---")
        }, with: .high)
        operationGroup.start()
    }
    
    private func testCache() {
        let places = [
            Placemark(name: "Berlin", coordinate:
                        Coordinate(latitude: 52, longitude: 13)),
            Placemark(name: "Cape Town", coordinate:
                        Coordinate(latitude: -34, longitude: 18))
        ]
        
        let cache = BECache2()
        cache.set(object: places, key: "place")
        
        let data = cache.get(key: "place")
        print(data!)
    }

    
    private func test_dispatch_block_t() {
        
        /**
         * operation 是对workitem的一层包装，一个operation可以管理多个workItem
         * operationQueue可以管理多个operation，并且各个operation是可以添加依赖关系的
         *  最后，operationQueue.schedule执行里面各个operation里面的workItem
         *  此外。wotkitem也可以执行 workItem.perform()
         */
        
        //oc 中的dispatch_block_t 在swift里面的是：DispatchWorkItem
        let workItem = DispatchWorkItem {
            print("is studying DispatchWorkItem")
        }
        
        let workItem2 = DispatchWorkItem {
            print("is studying  2DispatchWorkItem")
        }
        
        DispatchQueue.global().async {
            workItem2.perform()
            workItem.perform()
        }
//        workItem.perform()
        
        
      
        
        let opB = BlockOperation {
            print("block operation--0")
        }
        
        let opB1 = BlockOperation {
            print("block operation--1")
        }
        
        let opB2 = BlockOperation {
            print("block operation--2")
        }
            
        opB.addExecutionBlock {
            print("block operation0----1")
        }
        
        opB1.addDependency(opB2)
        opB2.addDependency(opB)
        
        let operationQueue = OperationQueue()
        operationQueue.addOperation(opB)
        operationQueue.addOperation(opB1)
        operationQueue.addOperation(opB2)
     

        operationQueue.schedule {
            print("finish")
        }
        
      
        
        
    }

}

