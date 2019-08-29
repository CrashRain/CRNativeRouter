//
//  ViewController5.swift
//  CRNativeRouter
//
//  Created by 易行 on 2017/3/17.
//  Copyright © 2017年 Demeijia. All rights reserved.
//

import UIKit

class ViewController5: UIViewController {

    @IBOutlet weak var urlLabel: UILabel!
    @IBOutlet weak var tempLabel: UILabel!
    @IBOutlet weak var testLabel: UILabel!
    
    var url = ""
    var temp = 0
    var test = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        urlLabel.text = "url=\(url)"
        testLabel.text = "test=\(test)"
        tempLabel.text = "temp=\(temp)"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func testNavigation(_ sender: UIButton) {
        let viewController = UIViewController()
        viewController.view.backgroundColor = UIColor.green
        
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    @IBAction func dismiss(_ sender: UIBarButtonItem) {
        navigationController?.dismiss(animated: true, completion: nil)
    }
}

extension ViewController5: CRNativeRouterDelegate {
    func getParameters(from router: CRNativeRouter, parameters: CRNativeRouterParam) {
        url = parameters.url as? String ?? ""
        temp = parameters.temp as? Int ?? 0
        test = parameters.test as? Int ?? 0
    }
}
