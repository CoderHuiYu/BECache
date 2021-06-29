//
//  TestBEMeoryCache.swift
//  Cache
//
//  Created by yuhui on 2021/6/28.
//

import UIKit

class TestBEMeoryCache: NSObject {
    
    let cache = BEMemoryCache.sharedCache
    func test() {
        
        cache.costLimit = 2
       
        cache.willAddObjectHandler = { (_, _, _ ) in
            print("will add")
        }
        
        cache.didAddObjectHandler = { (_, _, _ ) in
            print("did add")
        }
        
        let bob = People(name: "Bob", age: 23, sex: "male")
        let jack = People(name: "jack", age: 22, sex: "male")
        let alisa = People(name: "alisa", age: 21, sex: "female")
        cache.setObject(object: bob, key: "bob",cost: 1)
        cache.setObject(object: jack, key: "jack",cost: 2)
        cache.setObject(object: alisa, key: "alisa",cost: 3)
        
        
    }
}


class People {
    var name: String
    var age: Int
    var sex: String
    init(name: String, age: Int, sex: String) {
        self.age = age
        self.name = name
        self.sex = sex
    }
}
