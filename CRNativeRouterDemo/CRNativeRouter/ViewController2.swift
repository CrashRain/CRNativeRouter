//
//  ViewController2.swift
//  CRNativeRouter
//
//  Created by 易行 on 16/7/5.
//  Copyright © 2016年 Demeijia. All rights reserved.
//

import UIKit

class ViewController2: UIViewController, CRNativeRouterProtocol {
    
    private var temp = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    func getParametersFromRouter(parameter: [String : AnyObject]) {
        temp = parameter["temp"] as! Int
    }

}
