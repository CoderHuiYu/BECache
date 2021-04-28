//
//  TestBEoperationQueue.swift
//  Cache
//
//  Created by yuhui on 2021/4/22.
//

class TestBEOperationqueue {
    
        var opQueue =  BEOperationQueue.init(maxConcurrentOperations: 3)
    
    func test() {
//        for _ in 0...20 {
//        opQueue.scheduleOperation(with: { print("BE-1-1-default"); sleep(1) }, priority: .default)
//        opQueue.scheduleOperation(with: {  sleep(1); print("BE-1-2-high") }, priority: .high)
//            opQueue.scheduleOperation(with: { sleep(1);  print("BE-1-3-low") }, priority: .low)
//            opQueue.scheduleOperation(with: { sleep(1); print("BE-1-4-low") }, priority: .low)
//            opQueue.scheduleOperation(with: { sleep(1);  print("BE-1-5-low") }, priority: .low)
//            opQueue.scheduleOperation(with: { sleep(1);  print("BE-1-6-low") }, priority: .low)
//            opQueue.scheduleOperation(with: { sleep(1);  print("BE-1-7-low") }, priority: .low)
//            opQueue.scheduleOperation(with: { sleep(1); print("BE-1-8-high") }, priority: .high)
//            opQueue.scheduleOperation(with: { sleep(1);  print("BE-1-9-high") }, priority: .high)
//        }
        BEOperationGroup(queue: opQueue)
        
        for _ in 0...20 {
        opQueue.scheduleOperation(with: { print("BE-1-1-default"); sleep(1) }, priority: .default)
        opQueue.scheduleOperation(with: { print("BE-1-2-high") }, priority: .high)
            opQueue.scheduleOperation(with: { print("BE-1-3-low") }, priority: .low)
            opQueue.scheduleOperation(with: {  print("BE-1-4-low") }, priority: .low)
            opQueue.scheduleOperation(with: { print("BE-1-5-low") }, priority: .low)
            opQueue.scheduleOperation(with: { print("BE-1-6-low") }, priority: .low)
            opQueue.scheduleOperation(with: { print("BE-1-7-low") }, priority: .low)
            opQueue.scheduleOperation(with: { print("BE-1-8-high") }, priority: .high)
            opQueue.scheduleOperation(with: { print("BE-1-9-high") }, priority: .high)
        }
    }
    
    func test2() {
        //        print("------分割线2---------")
        //        let opQueue = PINOperationQueue(maxConcurrentOperations: 3)
        //        opQueue.scheduleOperation { print("Pin-1-default") }
        //        opQueue.scheduleOperation({ print("Pin--2-high") }, with: .high)
        //        opQueue.scheduleOperation({ print("Pin--3-low") }, with: .low)
        //        opQueue.scheduleOperation({ print("Pin--4-low") }, with: .low)
        //        opQueue.scheduleOperation({ print("Pin--5-low") }, with: .low)
        //        opQueue.scheduleOperation({ print("Pin--6-low") }, with: .low)
        //        opQueue.scheduleOperation({ print("Pin--7-low") }, with: .low)
        //        opQueue.scheduleOperation({ print("Pin--8-low") }, with: .low)
        //        opQueue.scheduleOperation({ print("Pin--9-high") }, with: .high)
        //        opQueue.scheduleOperation({ print("Pin--10-high") }, with: .high)
        
        //        print("------分割线2-end---------")
    }
    
}
