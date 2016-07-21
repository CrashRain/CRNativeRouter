//
//  CRNativeRouter.swift
//  CRNativeRouter
//
//  Created by 易行 on 16/7/1.
//  Copyright © 2016年 Demeijia. All rights reserved.
//

import UIKit

infix operator =~ {
    associativity none
    precedence 130
}

func ~= (lhs: String, rhs: String) -> Bool {
    var match = false
    
    if let result = try? NSRegularExpression(pattern: rhs, options: .CaseInsensitive).firstMatchInString(lhs, options: NSMatchingOptions(rawValue: 0), range: NSRange(location: 0, length: lhs.characters.count)) {
        
        match = (result != nil)
    }
    
    return match
}

protocol CRNativeRouterProtocol {
    func getParametersFromRouter(parameter: [String:AnyObject])
}

class CRNativeRouter: NSObject {
    
    // 视图控制器类型枚举
    private enum CRNativeRouterViewControllerType {
        case normal(type: AnyClass)
        case nib(type: AnyClass, name: String)
        case storyboard(type: AnyClass, name: String, identifier: String)
    }
    
    // 视图显示方式
    private enum CRNativeRouterViewPresentType {
        case show
        case showDetail
        case presentModally
        case presentAsPopover
    }
    
    private enum CRNativeRouterKey: String {
        case module = "CRNativeRouterModuleKey"
        case parameters = "CRNativeRouterParametersKey"
    }
    
    // 导航栏
//    private var navigationController: UINavigationController
    
    // 映射关系
    private var mapClass: [String:CRNativeRouterViewControllerType] = [:]
    private var mapParameters: [String:[String]] = [:]
    
    // 预设的URL匹配正则表达式
    private var regularFormat = "^(Medical://)(\\w+\\.md)(\\?(([a-zA-Z]+\\w*=\\w+)(&[a-zA-Z]+\\w*=\\w+)*)|([a-zA-Z]+\\w*=\\w+))?$"
    
    // 单例
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
    
    /**
     判断URL是否符合预设的正则表达式
     
     - parameter url: URL
     
     - returns: 比较结果
     */
    private func judgeUrlAvailable(url: String) -> Bool {
        return url ~= regularFormat
    }
    
    /**
     分离URL中的模块名称和参数队列
     
     - parameter url: URL
     
     - returns: 分离后的字典数据
     */
    private func divideComponentsFromUrl(url: String) -> [CRNativeRouterKey:String] {
        var compResult: [CRNativeRouterKey:String] = [:]
        
        do {
            // 分离模块名称
            var regularExpression = try NSRegularExpression(pattern: "://\\w+\\.md", options: .CaseInsensitive)
            var components = regularExpression.matchesInString(url, options: .ReportCompletion, range: NSMakeRange(0, url.characters.count))
            
            if components.count > 0 {
                let tempRange = components[0].range
                let range = url.startIndex.advancedBy(tempRange.location + 3) ..< url.startIndex.advancedBy(tempRange.location + tempRange.length)
                
                compResult[.module] = url.substringWithRange(range)
            }
            
            // 分离参数
            regularExpression = try NSRegularExpression(pattern: "\\?[\\w|&|=]*$", options: .CaseInsensitive)
            components = regularExpression.matchesInString(url, options: .ReportCompletion, range: NSMakeRange(0, url.characters.count))
            
            if components.count > 0 {
                let tempRange = components[0].range
                let range = url.startIndex.advancedBy(tempRange.location + 1) ..< url.startIndex.advancedBy(tempRange.location + tempRange.length)
                
                compResult[.parameters] = url.substringWithRange(range)
            }
        } catch {
            // exception catched
        }
        
        return compResult
    }
    
    /**
     通过module名称映射到对应的视图控制器
     
     - parameter module: module名称
     
     - returns: 对应的视图控制器
     */
    private func reflectViewController(module: String) -> UIViewController? {
        guard let type = mapClass[module] else { return nil }
        
        var viewController: UIViewController? = nil
        
        switch type {
        case .normal(let vcType):
            viewController = (vcType as! UIViewController.Type).init()
        case .nib(let vcType, let nib):
            viewController = (vcType as! UIViewController.Type).init(nibName: nib, bundle: nil)
        case .storyboard(_, let name, let identifier):
            let storyboard = UIStoryboard(name: name, bundle: nil)
            viewController = storyboard.instantiateViewControllerWithIdentifier(identifier)
        }
        
        return viewController
    }
    
    /**
     视图控制器参数校验
     
     - parameter module:    module名称
     - parameter parameter: URL中的参数队列字符串
     
     - returns: 校验结果
     */
    private func viewControllerParametersCheck(module: String, parameter: String, paramDict: [String:AnyObject]? = nil) -> Bool {
        guard let requiredList = mapParameters[module] else { return false }
        
        let components = parameter.componentsSeparatedByString("&")
        var params: [String] = []
        
        components.forEach { item in
            params.append(item.componentsSeparatedByString("=")[0])
        }
        
        if let additionalParams = paramDict {
            params.appendContentsOf(additionalParams.keys)
        }
        
        for item in requiredList {
            if !params.contains(item) {
                return false
            }
        }
        
        return true
    }
    
    /**
     生成视图控制器参数对应的字典数据
     
     - parameter parameter: 参数队列字符串
     
     - returns: 参数字典数据
     */
    private func viewControllerParameterGenerate(parameter: String, paramDict: [String:AnyObject]? = nil) -> [String:AnyObject] {
        guard  parameter != "" else { return [:] }

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
        
        if let additionalParam = paramDict {
            additionalParam.keys.forEach { key in
                params[key] = additionalParam[key]
            }
        }
        
        return params
    }
    
    /**
     返回URL对应的视图控制器，并且完成对应的参数初始化
     
     - parameter url: URL
     
     - returns: 视图控制器
     */
    private func figureModuleViewControllerAndParameter(url: String, parameters: [String:AnyObject]? = nil) -> UIViewController? {
        guard judgeUrlAvailable(url) else { return nil }
        
        let components = divideComponentsFromUrl(url)
        guard let module = components[.module] else { return nil }
        let parameterStr = components[.parameters] ?? ""
        
        if viewControllerParametersCheck(module, parameter: parameterStr, paramDict: parameters), let viewController = reflectViewController(module) where viewController is CRNativeRouterProtocol {
            (viewController as! CRNativeRouterProtocol).getParametersFromRouter(viewControllerParameterGenerate(parameterStr, paramDict: parameters))
            
            return viewController
        }
        
        return nil
    }
    
    // MARK: API
    
    /**
     设置统跳URL格式，以正则表达式表示
     内部使用固定格式正则，暂不提供该接口
     
     - parameter format:                URL格式（正则表达式）
     - parameter navigationController:  导航栏
     */
    func setURLModifyFormat(format: String) {
        self.regularFormat = format
    }
    
    /**
     注册新的视图控制器
     
     - parameter name:       视图控制器名称
     - parameter type:       视图控制器类型
     - parameter parameters: 对应的参数名称列表
     
     - returns: 注册结果
     */
    func registerNewModule(name: String, type: AnyClass, parameters: [String]) -> Bool {
        if type is UIViewController.Type {
            mapClass[name] = .normal(type: type)
            mapParameters[name] = parameters
            
            return true
        }
        
        return false
    }
    
    /**
     注册新的nib视图控制器
     
     - parameter name:       视图控制器名称
     - parameter type:       视图控制器类型
     - parameter nib:        nib名称
     - parameter parameters: 对应的参数名称列表
     
     - returns: 注册结果
     */
    func registerNewModule(name: String, type: AnyClass, nib: String, parameters: [String]) -> Bool {
        if type is UIViewController.Type {
            mapClass[name] = .nib(type: type, name: nib)
            mapParameters[name] = parameters
            
            return true
        }
        
        return false
    }
    
    /**
     注册新的Storyboard视图控制器
     
     - parameter name:       视图控制器名称
     - parameter type:       视图控制器类型
     - parameter storyboard: storyboard名称
     - parameter identifier: identifier标识
     - parameter parameters: 对应的参数名称列表
     
     - returns: 注册结果
     */
    func registerNewModule(name: String, type: AnyClass, storyboard: String, identifier: String, parameters: [String]) -> Bool {
        if type is UIViewController.Type {
            mapClass[name] = .storyboard(type: type, name: storyboard, identifier: identifier)
            mapParameters[name] = parameters
            
            return true
        }
        
        return false
    }
    
    /**
     从plist文件注册视图控制器
     
     - parameter filename: plist文件名称
     */
    func registerModulesFromConfiguration(filename: String) {
        guard let plistPath = NSBundle.mainBundle().pathForResource(filename, ofType: "plist") else { return }
        guard let modulesDict = NSDictionary(contentsOfFile: plistPath) else { return }
        guard let modules = modulesDict["Modules"] as? [[String:AnyObject]] else { return }
        
        modules.forEach { module in
            guard let name = module["name"] as? String else { return }
            guard let type = module["type"] as? String else { return }
            
            guard let namespace = NSBundle.mainBundle().infoDictionary!["CFBundleExecutable"] as? String else { return }
            guard let className = NSClassFromString(namespace + "." + type) else { return }
            
            guard let parameters = module["parameters"] as? [String] else { return }
            
            if let storyboard = module["storyboard"] as? String { // storyboard
                guard let identifier = module["identifier"] as? String else { return }
                
                registerNewModule(name, type: className, storyboard: storyboard, identifier: identifier, parameters: parameters)
            } else if let nib = module["nib"] as? String {
                registerNewModule(name, type: className, nib: nib, parameters: parameters)
            } else {
                registerNewModule(name, type: className, parameters: parameters)
            }
        }
    }
    
    /**
     从plist总文件中获取各个分plist文件，并注册视图控制器
     
     - parameter filename: plist文件名称
     */
    func registerModulesFromDeveloperGroupConfiguration(filename: String) {
        guard let plistPath = NSBundle.mainBundle().pathForResource(filename, ofType: "plist") else { return }
        guard let groupArray = NSArray(contentsOfFile: plistPath) as? [String] else { return }
        
        groupArray.forEach { file in
            registerModulesFromConfiguration(file)
        }
    }
    
    /**
     Navigation controller push a new view controller
     
     - parameter url:                  URL
     - parameter navigationController: navigation controller
     */
    @available(iOS, deprecated=8.0, message="Up to iOS 8.0 deprecated, use show view controller instead")
    func navigationControllerPushViewController(url: String, navigationController: UINavigationController?) {
        if let navigation = navigationController, let viewController = figureModuleViewControllerAndParameter(url) {
            navigation.pushViewController(viewController, animated: true)
        }
    }
    
    @available(iOS, deprecated=8.0, message="Up to iOS 8.0 deprecated, use show view controller instead")
    func navigationControllerPushViewController(url: String, parameters: [String:AnyObject], navigationController: UINavigationController?) {
        if let navigation = navigationController, let viewController = figureModuleViewControllerAndParameter(url, parameters: parameters) {
            navigation.pushViewController(viewController, animated: true)
        }
    }
    
    /**
     Navigation controller show a new view controller
     
     - parameter url:                  URL
     - parameter navigationController: navigation controller
     */
    @available(iOS 8.0, *)
    func navigationControllerShowViewController(url: String, navigationController: UINavigationController?) {
        if let navigation = navigationController, let viewController = figureModuleViewControllerAndParameter(url) {
            navigation.showViewController(viewController, sender: self)
        }
    }
    
    @available(iOS 8.0, *)
    func navigationControllerShowViewController(url: String, parameters: [String:AnyObject], navigationController: UINavigationController?) {
        if let navigation = navigationController, let viewController = figureModuleViewControllerAndParameter(url, parameters: parameters) {
            navigation.showViewController(viewController, sender: self)
        }
    }
    
    /**
     Navigation controller show detail a new view controller
     
     - parameter url:                  URL
     - parameter navigationController: navigation controller
     */
    @available(iOS 8.0, *)
    func navigationControllerShowDetailViewController(url: String, navigationController: UINavigationController?) {
        if let navigation = navigationController, let viewController = figureModuleViewControllerAndParameter(url) {
            navigation.showDetailViewController(viewController, sender: self)
        }
    }
    
    @available(iOS 8.0, *)
    func navigationControllerShowDetailViewController(url: String, parameters: [String:AnyObject], navigationController: UINavigationController?) {
        if let navigation = navigationController, let viewController = figureModuleViewControllerAndParameter(url, parameters: parameters) {
            navigation.showDetailViewController(viewController, sender: self)
        }
    }
    
    /**
     Show a view controller modally
     
     - parameter url:            URL
     - parameter viewController: view controller
     */
    @available(iOS 8.0, *)
    func showModallyViewController(url: String, viewController: UIViewController) {
        if let vc = figureModuleViewControllerAndParameter(url) {
            viewController.modalPresentationStyle = .OverCurrentContext
            viewController.modalTransitionStyle = .CoverVertical
            viewController.navigationController?.modalTransitionStyle = .CoverVertical
            
            viewController.presentViewController(vc, animated: true, completion: nil)
        }
    }
    
    @available(iOS 8.0, *)
    func showModallyViewController(url: String, viewController: UIViewController, parameters: [String:AnyObject]) {
        if let vc = figureModuleViewControllerAndParameter(url, parameters: parameters) {
            viewController.modalPresentationStyle = .OverCurrentContext
            viewController.modalTransitionStyle = .CoverVertical
            viewController.navigationController?.modalTransitionStyle = .CoverVertical
            
            viewController.presentViewController(vc, animated: true, completion: nil)
        }
    }
    
    /**
     Pop over a new view controller
     
     - parameter url:            URL
     - parameter viewController: view controller
     - parameter sourceRect:     source area rect
     */
    @available(iOS 8.0, *)
    func popoverViewController(url: String, viewController: UIViewController, sourceRect: CGRect) {
        if let vc = figureModuleViewControllerAndParameter(url), let popoverController = viewController.popoverPresentationController {
            viewController.navigationController?.modalPresentationStyle = .Popover
            
            popoverController.sourceView = viewController.view
            popoverController.sourceRect = sourceRect
            
            viewController.presentViewController(vc, animated: true, completion: nil)
        }
    }
    
    @available(iOS 8.0, *)
    func popoverViewController(url: String, viewController: UIViewController, parameters: [String:AnyObject], sourceRect: CGRect) {
        if let vc = figureModuleViewControllerAndParameter(url, parameters: parameters), let popoverController = viewController.popoverPresentationController {
            viewController.navigationController?.modalPresentationStyle = .Popover
            
            popoverController.sourceView = viewController.view
            popoverController.sourceRect = sourceRect
            
            viewController.presentViewController(vc, animated: true, completion: nil)
        }
    }
}
