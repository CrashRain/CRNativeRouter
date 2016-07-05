//
//  CRNativeRouter.swift
//  CRNativeRouter
//
//  Created by 易行 on 16/7/1.
//  Copyright © 2016年 Demeijia. All rights reserved.
//

import UIKit

enum CRNativeRouterError {
    case unavailableFormat
}

infix operator =~ {
    associativity left
    precedence 160
}

func =~ (lhs: String, rhs: String) -> Bool {
    var match = false
    
    if let _ = try? NSRegularExpression(pattern: rhs, options: .CaseInsensitive).firstMatchInString(lhs, options: NSMatchingOptions(rawValue: 0), range: NSRange(location: 0, length: lhs.characters.count)) {
        match = true
    }
    
    return match
}

protocol CRNativeRouterProtocol {
    func getParametersFromRouter(parameter: [String:AnyObject])
}

class CRNativeRouter: NSObject {
    
    private let CRNativeRouterTypeKey = "CRNativeRouterTypeKey"
    private let CRNativeRouterModuleKey = "CRNativeRouterModuleKey"
    private let CRNativeRouterParametersKey = "CRNativeRouterParametersKey"
    
    private var navigationController: UINavigationController? = nil
    
    private var mapClass: [String:AnyClass] = [:]
    private var mapParameters: [String:[String]] = [:]
    
    private var regularFormat = "^(Medical://)(\\w+\\.md)(\\?(([a-zA-Z]+\\w*=\\w+)(&[a-zA-Z]+\\w*=\\w+)*)|([a-zA-Z]+\\w*=\\w+))?$"
    
    private struct Static {
        static var instance: CRNativeRouter! = nil
        static var predicate: dispatch_once_t = 0
    }
    
    /**
     实例返回函数
     
     - returns: 类实例
     */
    class func sharedInstance() -> CRNativeRouter {
        if Static.instance == nil {
            dispatch_once(&Static.predicate) {
                Static.instance = self.init()
            }
        }
        
        return Static.instance
    }
    
    /**
     初始化函数
     */
    internal required override init() {
        super.init()
    }
    
    private func judgeUrlAvailable(url: String) -> Bool {
        return url =~ regularFormat
    }
    
    private func divideComponentsFromUrl(url: String) -> [String:String] {
        var compResult: [String:String] = [:]
        
        do {
            // 分离模块名称
            var regularExpression = try NSRegularExpression(pattern: "://\\w+\\.md", options: .CaseInsensitive)
            var components = regularExpression.matchesInString(url, options: .ReportCompletion, range: NSMakeRange(0, url.characters.count))
            
            if components.count > 0 {
                let tempRange = components[0].range
                let range = url.startIndex.advancedBy(tempRange.location + 3) ..< url.startIndex.advancedBy(tempRange.location + tempRange.length)
                
                compResult[CRNativeRouterModuleKey] = url.substringWithRange(range)
            }
            
            // 分离参数
            regularExpression = try NSRegularExpression(pattern: "\\?[\\w|&|=]*$", options: .CaseInsensitive)
            components = regularExpression.matchesInString(url, options: .ReportCompletion, range: NSMakeRange(0, url.characters.count))
            
            if components.count > 0 {
                let tempRange = components[0].range
                let range = url.startIndex.advancedBy(tempRange.location + 1) ..< url.startIndex.advancedBy(tempRange.location + tempRange.length)
                
                compResult[CRNativeRouterParametersKey] = url.substringWithRange(range)
            }
        } catch {
            
        }
        
        return compResult
    }
    
    private func reflectViewController(module: String) -> UIViewController? {
        guard let type = mapClass[module] where type is UIViewController.Type else { return nil }
        
        return (type as! UIViewController.Type).init()
    }
    
    private func viewControllerParametersCheck(module: String, parameter: String) -> Bool {
        guard let requiredList = mapParameters[module] else { return false }
        
        let components = parameter.componentsSeparatedByString("&")
        var params: [String] = []
        
        components.forEach { item in
            params.append(item.componentsSeparatedByString("=")[0])
        }
        
        var result = true
        for item in requiredList {
            if !params.contains(item) {
                result = false
                break
            }
        }
        
        return result
    }
    
    private func viewControllerParameterGenerate(parameter: String) -> [String:AnyObject] {
        let components = parameter.componentsSeparatedByString("&")
        var params: [String:AnyObject] = [:]
        
        components.forEach { item in
            let refs = item.componentsSeparatedByString("=")
            
            if let intValue = Int(refs[1]) {
                params[refs[0]] = intValue
            } else if let doubleValue = Double(refs[1]) {
                params[refs[0]] = doubleValue
            } else {
                params[refs[0]] = refs[1]
            }
        }
        
        return params
    }
    
    // MARK: API
    
    /**
     设置统跳URL格式，以正则表达式表示
     内部使用固定格式正则，暂不提供该接口
     
     - parameter format: URL格式（正则表达式）
     */
    func setURLModifyFormat(format: String, navigationController: UINavigationController?) {
        self.regularFormat = format
        self.navigationController = navigationController
    }
    
    /**
     注册新的统跳类型
     
     - parameter label:      标识支付串
     - parameter type:       要注册的类型
     - parameter parameters: 对应的参数名称列表
     
     - returns: 是否注册成功
     */
    func registerNewModule(label: String, type: AnyClass, parameters: [String]) -> Bool {
        if type is UIViewController.Type {
            mapClass[label] = type
            mapParameters[label] = parameters
            
            return true
        }
        
        return false
    }
    
    func showModuleViewController(url: String) -> Bool {
        guard judgeUrlAvailable(url) else { return false }
        
        let components = divideComponentsFromUrl(url)
        guard let module = components[CRNativeRouterModuleKey] else { return false }
        let parameters = components[CRNativeRouterParametersKey] ?? ""
        
        if let viewController = reflectViewController(module) {
            if viewControllerParametersCheck(module, parameter: components[CRNativeRouterParametersKey]!) {
                if viewController is CRNativeRouterProtocol {
                    let vcParams = viewControllerParameterGenerate(parameters)
                    let proto = viewController as! CRNativeRouterProtocol
                    proto.getParametersFromRouter(vcParams)
                }
                
                if let navController = navigationController {
                    dispatch_async(dispatch_get_main_queue()) {
                        navController.pushViewController(viewController, animated: true)
                    }
                }
            } else {
                return false
            }
        }
        
        return true
    }
    
}
