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
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print(test.cache.totalCost)
    }
   
}

