//
//  ViewController.swift
//  Cache
//
//  Created by yuhui on 2021/4/21.
//

import UIKit

class ViewController: UIViewController {
    let test = TestBEMeoryCache()
    override func viewDidLoad() {
        super.viewDidLoad()
        test.test()
        print( self.add(5)(3) )
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print(test.cache.totalCost)
    }
    
    func add(_ num: Int) -> (Int) -> Int {
        return { val in
            return num + val
        }
    }
    
    func fib(_ n: Int) -> Int {
        
        if n <= 2 { return 1 }
        
        return fib(n-1) + fib(n-2)
    }
    
    
   
}

