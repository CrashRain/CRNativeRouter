//
//  ViewController.swift
//  CRNativeRouter
//
//  Created by 易行 on 16/7/1.
//  Copyright © 2016年 Demeijia. All rights reserved.
//

import UIKit

class ViewController: UIViewController, CRNativeRouterProtocol {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func jump(sender: UIButton) {
//        CRNativeRouter.sharedInstance().navigationControllerShowViewController("Medical://vc2.md?temp=1", navigationController: navigationController)
        CRNativeRouter.sharedInstance().navigationControllerShowViewController("Medical://vc2.md?temp=1", parameters: ["test": 1, "url": "http://xxxx.com?id=1&fdfd=2&fdg=3"], navigationController: navigationController)
    }
    
    func getParametersFromRouter(parameter: [String : AnyObject]) {
        
    }
}

