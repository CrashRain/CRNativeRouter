//
//  ViewController.swift
//  CRNativeRouter
//
//  Created by CrashRain on 16/7/1.
//  Copyright © 2016年 CrashRain. All rights reserved.
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
        CRNativeRouter.sharedInstance().pushViewController("Medical://vc2.md?temp=1", parameters: ["test": 1, "url": "http://xxxx.com?id=1&fdfd=2&fdg=3"])
    }
    
    @IBAction func jumpToView3(sender: UIButton) {
        CRNativeRouter.sharedInstance().showViewController("Medical://vc3.md?temp=3", parameters: ["test": 2, "url": "http://yyyy.com?id=1&haha=2&hello=3"])
    }
    
    @IBAction func jumpToView4(sender: UIButton) {
        CRNativeRouter.sharedInstance().showModallyViewController("Medical://vc4.md?test=1&value=3")
    }
    
    func getParametersFromRouter(parameter: [String : AnyObject]) {
        
    }
}

