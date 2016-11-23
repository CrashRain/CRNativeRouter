//
//  ViewController4.swift
//  CRNativeRouter
//
//  Created by 易行 on 16/7/30.
//  Copyright © 2016年 Demeijia. All rights reserved.
//

import UIKit

class ViewController4: UIViewController {
    
    fileprivate var test = 0
    fileprivate var value = 0

    @IBOutlet weak var testLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        testLabel.text = "test=\(test)"
        valueLabel.text = "value=\(value)"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func dismiss(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
}

extension ViewController4: CRNativeRouterProtocol {
    func getParametersFromRouter(_ parameter: [String : Any]) {
        test = parameter["test"] as! Int
        value = parameter["value"] as! Int
    }
}
