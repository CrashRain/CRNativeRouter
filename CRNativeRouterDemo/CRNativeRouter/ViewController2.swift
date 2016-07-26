//
//  ViewController2.swift
//  CRNativeRouter
//
//  Created by 易行 on 16/7/5.
//  Copyright © 2016年 易行. All rights reserved.
//

import UIKit

class ViewController2: UIViewController, CRNativeRouterProtocol {
    
    private var temp = 0
    private var test = 0
    private var url = ""

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
    

    func getParametersFromRouter(parameter: [String : AnyObject]) {
        temp = parameter["temp"] as! Int
        test = parameter["test"] as! Int
        url = parameter["url"] as! String
    }

}
