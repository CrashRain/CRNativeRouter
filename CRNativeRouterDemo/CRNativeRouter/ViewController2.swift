//
//  ViewController2.swift
//  CRNativeRouter
//
//  Created by CrashRain on 16/7/5.
//  Copyright © 2016年 CrashRain. All rights reserved.
//

import UIKit

class ViewController2: UIViewController {
    
    fileprivate var temp = 0
    fileprivate var test = 0
    fileprivate var url = ""

    @IBOutlet weak var tempLabel: UILabel!
    @IBOutlet weak var testLabel: UILabel!
    @IBOutlet weak var urlLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        tempLabel.text = "temp=\(temp)"
        testLabel.text = "test=\(test)"
        urlLabel.text = "URL: \(url)"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension ViewController2: CRNativeRouterProtocol {
    func getParametersFromRouter(_ parameter: [String : Any]) {
        temp = parameter["temp"] as! Int
        test = parameter["test"] as! Int
        url = parameter["url"] as! String
    }
}
