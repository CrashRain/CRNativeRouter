//
//  ViewController3.swift
//  CRNativeRouter
//
//  Created by CrashRain on 16/7/21.
//  Copyright © 2016年 CrashRain. All rights reserved.
//

import UIKit

class ViewController3: UIViewController {
    
    fileprivate var test = 0
    fileprivate var temp = 0
    fileprivate var url = ""

    @IBOutlet weak var testLabel: UILabel!
    @IBOutlet weak var tempLabel: UILabel!
    @IBOutlet weak var urlLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        testLabel.text = "test=\(test)"
        tempLabel.text = "temp=\(temp)"
        urlLabel.text = "URL: \(url)"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension ViewController3: CRNativeRouterDelegate {
    func getParameters(from router: CRNativeRouter, parameters: CRNativeRouterParam) {
        test = parameters.test as? Int ?? 0
        temp = parameters.temp as? Int ?? 0
        url = parameters.url as? String ?? ""
    }
}
