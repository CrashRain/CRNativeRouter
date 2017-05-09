//
//  CRNativeRouter.swift
//  CRNativeRouter
//
//  Created by CrashRain on 16/7/1.
//  Copyright © 2016年 CrashRain. All rights reserved.
//

import UIKit

func ~= (lhs: String, rhs: String) -> Bool {
    var match = false
    
    if let result = try? NSRegularExpression(pattern: rhs, options: .caseInsensitive).firstMatch(in: lhs, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSRange(location: 0, length: lhs.characters.count)) {
        
        match = (result != nil)
    }
    
    return match
}

@objc
public protocol CRNativeRouterProtocol {
    func getParametersFromRouter(_ parameter: [String: Any])
}

open class CRNativeRouter: NSObject {
    
    private static var __once: () = {
                Static.instance = CRNativeRouter()
            }()
    
    // 视图控制器类型枚举
    fileprivate enum CRNativeRouterViewControllerType {
        case normal(type: AnyClass)
        case nib(type: AnyClass, name: String)
        case storyboard(type: AnyClass, name: String, identifier: String)
    }
    
    // 视图显示方式
    fileprivate enum CRNativeRouterViewPresentType {
        case show
        case showDetail
        case presentModally
        case presentAsPopover
    }
    
    fileprivate enum CRNativeRouterKey: String {
        case module = "CRNativeRouterModuleKey"
        case parameters = "CRNativeRouterParametersKey"
    }
    
    // 导航栏
//    private var navigationController: UINavigationController
    
    // 映射关系
    fileprivate var mapClass: [String:CRNativeRouterViewControllerType] = [:]
    fileprivate var mapParameters: [String:[String]] = [:]
    
    // 预设的URL匹配正则表达式
    fileprivate var regularFormat = "^(Medical://)(\\w+\\.md)(\\?(([a-zA-Z]+\\w*=\\w+)(&[a-zA-Z]+\\w*=\\w+)*)|([a-zA-Z]+\\w*=\\w+))?$"
    
    // 单例
    fileprivate struct Static {
        static var instance: CRNativeRouter! = nil
        static var predicate: Int = 0
    }
    
    /**
     实例返回函数
     
     - returns: 类实例
     */
    open class func sharedInstance() -> CRNativeRouter {
        if Static.instance == nil {
            _ = CRNativeRouter.__once
        }
        
        return Static.instance
    }
    
    /**
     初始化函数
     */
    public required override init() {
        super.init()
    }
    
    /**
     判断URL是否符合预设的正则表达式
     
     - parameter url: URL
     
     - returns: 比较结果
     */
    fileprivate func judgeUrlAvailable(_ url: String) -> Bool {
        return url ~= regularFormat
    }
    
    /**
     分离URL中的模块名称和参数队列
     
     - parameter url: URL
     
     - returns: 分离后的字典数据
     */
    fileprivate func divideComponentsFromUrl(_ url: String) -> [CRNativeRouterKey:String] {
        var compResult: [CRNativeRouterKey:String] = [:]
        
        do {
            // 分离模块名称
            var regularExpression = try NSRegularExpression(pattern: "://\\w+\\.md", options: .caseInsensitive)
            var components = regularExpression.matches(in: url, options: .reportCompletion, range: NSMakeRange(0, url.characters.count))
            
            if components.count > 0 {
                let tempRange = components[0].range
                let range = url.characters.index(url.startIndex, offsetBy: tempRange.location + 3) ..< url.characters.index(url.startIndex, offsetBy: tempRange.location + tempRange.length)
                
                compResult[.module] = url.substring(with: range)
            }
            
            // 分离参数
            regularExpression = try NSRegularExpression(pattern: "\\?[\\w|&|=]*$", options: .caseInsensitive)
            components = regularExpression.matches(in: url, options: .reportCompletion, range: NSMakeRange(0, url.characters.count))
            
            if components.count > 0 {
                let tempRange = components[0].range
                let range = url.characters.index(url.startIndex, offsetBy: tempRange.location + 1) ..< url.characters.index(url.startIndex, offsetBy: tempRange.location + tempRange.length)
                
                compResult[.parameters] = url.substring(with: range)
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
    fileprivate func reflectViewController(_ module: String) -> UIViewController? {
        guard let type = mapClass[module] else { return nil }
        
        var viewController: UIViewController? = nil
        
        switch type {
        case .normal(let vcType):
            viewController = (vcType as! UIViewController.Type).init()
        case .nib(let vcType, let nib):
            viewController = (vcType as! UIViewController.Type).init(nibName: nib, bundle: nil)
        case .storyboard(_, let name, let identifier):
            viewController = UIStoryboard(name: name, bundle: nil).instantiateViewController(withIdentifier: identifier)
        }
        
        return viewController
    }
    
    /**
     视图控制器参数校验
     
     - parameter module:    module名称
     - parameter parameter: URL中的参数队列字符串
     
     - returns: 校验结果
     */
    fileprivate func viewControllerParametersCheck(_ module: String, parameter: String, paramDict: [String: Any]? = nil) -> Bool {
        guard let requiredList = mapParameters[module] else { return false }
        
        let components = parameter.components(separatedBy: "&")
        var params: [String] = []
        
        components.forEach { item in
            params.append(item.components(separatedBy: "=")[0])
        }
        
        if let additionalParams = paramDict {
            params.append(contentsOf: additionalParams.keys)
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
    fileprivate func viewControllerParameterGenerate(_ parameter: String, paramDict: [String:Any]? = nil) -> [String: Any] {
        guard parameter != "" else { return paramDict ?? [:] }

        let components = parameter.components(separatedBy: "&")
        var params: [String:Any] = [:]
        
        components.forEach { item in
            let refs = item.components(separatedBy: "=")
            
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
    fileprivate func figureModuleViewControllerAndParameter(_ url: String, parameters: [String:Any]? = nil) -> UIViewController? {
        guard judgeUrlAvailable(url) else { return nil }
        
        let components = divideComponentsFromUrl(url)
        guard let module = components[.module] else { return nil }
        let parameterStr = components[.parameters] ?? ""
        
        if viewControllerParametersCheck(module, parameter: parameterStr, paramDict: parameters), let viewController = reflectViewController(module) {
            if mapParameters[module]!.count != 0 && !(viewController is CRNativeRouterProtocol) {
                return nil
            }
            
            if viewController is CRNativeRouterProtocol {
                (viewController as! CRNativeRouterProtocol).getParametersFromRouter(viewControllerParameterGenerate(parameterStr, paramDict: parameters))
            }
            
            return viewController
        }
        
        return nil
    }
    
    /**
     获取当前显示的视图控制器
     
     - returns: 当前显示的视图控制器
     */
    open func currentViewController() -> UIViewController? {
        guard let rootViewController = UIApplication.shared.keyWindow?.rootViewController else { return nil }
        
        return recursionTopViewController(rootViewController)
    }
    
    /**
     递归查找显示的视图控制器
     
     - parameter rootViewController: 开始查找的视图控制器结点
     
     - returns: 视图控制器
     */
    fileprivate func recursionTopViewController(_ rootViewController: UIViewController) -> UIViewController {
        if rootViewController is UINavigationController {
            let navigationController = rootViewController as! UINavigationController
            return recursionTopViewController(navigationController.topViewController!)
        }
        
        guard let presentedViewController = rootViewController.presentedViewController else { return rootViewController }
        
        return recursionTopViewController(presentedViewController)
    }
    
    // MARK: API
    
    /**
     设置统跳URL格式，以正则表达式表示
     内部使用固定格式正则，暂不提供该接口
     
     - parameter format:                URL格式（正则表达式）
     */
    open func setURLModifyFormat(_ format: String) {
        self.regularFormat = format
    }
    
    /**
     注册新的视图控制器
     
     - parameter name:       视图控制器名称
     - parameter type:       视图控制器类型
     - parameter parameters: 对应的参数名称列表
     
     - returns: 注册结果
     */
    @discardableResult
    open func registerNewModule(_ name: String, type: AnyClass, parameters: [String]?) -> Bool {
        if type is UIViewController.Type {
            mapClass[name] = .normal(type: type)
            mapParameters[name] = parameters ?? []
            
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
    @discardableResult
    open func registerNewModule(_ name: String, type: AnyClass, nib: String, parameters: [String]?) -> Bool {
        if type is UIViewController.Type {
            mapClass[name] = .nib(type: type, name: nib)
            mapParameters[name] = parameters ?? []
            
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
    @discardableResult
    open func registerNewModule(_ name: String, type: AnyClass, storyboard: String, identifier: String, parameters: [String]?) -> Bool {
        if type is UIViewController.Type {
            mapClass[name] = .storyboard(type: type, name: storyboard, identifier: identifier)
            mapParameters[name] = parameters ?? []
            
            return true
        }
        
        return false
    }
    
    /**
     从plist文件注册视图控制器
     
     - parameter filename: plist文件名称
     */
    open func registerModulesFromConfiguration(_ filename: String) {
        guard let plistPath = Bundle.main.path(forResource: filename, ofType: "plist") else { return }
        guard let modulesDict = NSDictionary(contentsOfFile: plistPath) else { return }
        guard let modules = modulesDict["Modules"] as? [[String:Any]] else { return }
        
        modules.forEach { module in
            guard let name = module["name"] as? String else { return }
            guard let type = module["type"] as? String else { return }
            
            guard let namespace = Bundle.main.infoDictionary!["CFBundleExecutable"] as? String else { return }
            guard let className = NSClassFromString(namespace + "." + type) ?? NSClassFromString(type) else { return }
            
            let parameters = module["parameters"] as? [String]
            
            if let storyboard = module["storyboard"] as? String { // storyboard
                guard let identifier = module["identifier"] as? String else { return }
                
                _ = registerNewModule(name, type: className, storyboard: storyboard, identifier: identifier, parameters: parameters)
            } else if let nib = module["nib"] as? String {
                _ = registerNewModule(name, type: className, nib: nib, parameters: parameters)
            } else {
                _ = registerNewModule(name, type: className, parameters: parameters)
            }
        }
    }
    
    /**
     从plist总文件中获取各个分plist文件，并注册视图控制器
     
     - parameter filename: plist文件名称
     */
    open func registerModulesFromDeveloperGroupConfiguration(_ filename: String) {
        guard let plistPath = Bundle.main.path(forResource: filename, ofType: "plist") else { return }
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
    open func navigationControllerPushViewController(_ url: String, navigationController: UINavigationController?) {
        if let navigation = navigationController, let viewController = figureModuleViewControllerAndParameter(url) {
            navigation.pushViewController(viewController, animated: true)
        }
    }
    
    /**
     Navigation controller push a new view controller
     
     - parameter url:                  URL
     - parameter parameters:           additional parameters
     - parameter navigationController: navigation controller
     */
    open func navigationControllerPushViewController(_ url: String, parameters: [String: Any], navigationController: UINavigationController?) {
        if let navigation = navigationController, let viewController = figureModuleViewControllerAndParameter(url, parameters: parameters) {
            navigation.pushViewController(viewController, animated: true)
        }
    }
    
    /**
     Navigation controller push a new view controller
     
     - parameter url:        URL
     - parameter parameters: navigation controller
     */
    @available(iOS, deprecated: 8.0, message: "Up to iOS 8.0 deprecated, use show view controller instead")
    open func pushViewController(_ url: String, parameters: [String: Any]? = nil) {
        if let curViewController = currentViewController(), let viewController = figureModuleViewControllerAndParameter(url, parameters: parameters) {
            curViewController.navigationController?.pushViewController(viewController, animated: true)
        }
    }
    
    /**
     Navigation controller show a new view controller
     
     - parameter url:                  URL
     - parameter navigationController: navigation controller
     */
    open func navigationControllerShowViewController(_ url: String, navigationController: UINavigationController?) {
        if let navigation = navigationController, let viewController = figureModuleViewControllerAndParameter(url) {
            navigation.show(viewController, sender: self)
        }
    }
    
    /**
     Navigation controller show a new view controller
     
     - parameter url:                  URL
     - parameter parameters:           additional parameters
     - parameter navigationController: navigation controller
     */
    open func navigationControllerShowViewController(_ url: String, parameters: [String: Any], navigationController: UINavigationController?) {
        if let navigation = navigationController, let viewController = figureModuleViewControllerAndParameter(url, parameters: parameters) {
            navigation.show(viewController, sender: self)
        }
    }
    
    /**
     Navigation controller show a new view controller
     
     - parameter url:        URL
     - parameter parameters: additional parameters
     */
    @available(iOS 8.0, *)
    open func showViewController(_ url: String, parameters: [String: Any]? = nil) {
        if let curViewController = currentViewController(), let viewController = figureModuleViewControllerAndParameter(url, parameters: parameters) {
            curViewController.navigationController?.show(viewController, sender: self)
        }
    }
    
    /**
     Navigation controller show detail a new view controller
     
     - parameter url:                  URL
     - parameter navigationController: navigation controller
     */
    open func navigationControllerShowDetailViewController(_ url: String, navigationController: UINavigationController?) {
        if let navigation = navigationController, let viewController = figureModuleViewControllerAndParameter(url) {
            navigation.showDetailViewController(viewController, sender: self)
        }
    }
    
    /**
     Navigation controller show detail a new view controller
     
     - parameter url:                  URL
     - parameter parameters:           additional parameters
     - parameter navigationController: navigation controller
     */
    open func navigationControllerShowDetailViewController(_ url: String, parameters: [String: Any], navigationController: UINavigationController?) {
        if let navigation = navigationController, let viewController = figureModuleViewControllerAndParameter(url, parameters: parameters) {
            navigation.showDetailViewController(viewController, sender: self)
        }
    }
    
    /**
     Navigation controller show detail a new view controller
     
     - parameter url:        URL
     - parameter parameters: additional parameters
     */
    @available(iOS 8.0, *)
    open func showDetailViewController(_ url: String, parameters: [String: Any]? = nil) {
        if let curViewController = currentViewController(), let viewController = figureModuleViewControllerAndParameter(url, parameters: parameters) {
            curViewController.navigationController?.showDetailViewController(viewController, sender: self)
        }
    }
    
    /**
     Show a view controller modally
     
     - parameter url:            URL
     - parameter viewController: view controller where new one show from
     */
    open func showModallyViewController(_ url: String, fromViewController viewController: UIViewController) {
        if let vc = figureModuleViewControllerAndParameter(url) {
            viewController.modalPresentationStyle = .overCurrentContext
            viewController.modalTransitionStyle = .coverVertical
            viewController.navigationController?.modalTransitionStyle = .coverVertical
            
            viewController.present(vc, animated: true, completion: nil)
        }
    }
    
    
    /// Show a view controller within navigation modally
    ///
    /// - Parameters:
    ///   - url: URL
    ///   - viewController: view controller where new one show from
    open func showModallyViewControllerInNavigation(_ url: String, fromViewController viewController: UIViewController) {
        if let vc = figureModuleViewControllerAndParameter(url) {
            viewController.modalPresentationStyle = .overCurrentContext
            viewController.modalTransitionStyle = .coverVertical
            viewController.navigationController?.modalTransitionStyle = .coverVertical
            
            let navigationController = UINavigationController(rootViewController: vc)
            
            viewController.present(navigationController, animated: true, completion: nil)
        }
    }
    
    /**
     Show a view controller modally
     
     - parameter url:                  URL
     - parameter viewController:       view controller where new one show from
     - parameter parameters:           additional parameters
     */
    open func showModallyViewController(_ url: String, fromViewController viewController: UIViewController, parameters: [String: Any]) {
        if let vc = figureModuleViewControllerAndParameter(url, parameters: parameters) {
            viewController.modalPresentationStyle = .overCurrentContext
            viewController.modalTransitionStyle = .coverVertical
            viewController.navigationController?.modalTransitionStyle = .coverVertical
            
            viewController.present(vc, animated: true, completion: nil)
        }
    }
    
    
    /// Show a view controller within navigation modally
    ///
    /// - Parameters:
    ///   - url: URL
    ///   - viewController: view controller where new one show from
    ///   - parameters: additional parameters
    open func showModallyViewControllerInNavigation(_ url: String, fromViewController viewController: UIViewController, parameters: [String: Any]) {
        if let vc = figureModuleViewControllerAndParameter(url, parameters: parameters) {
            viewController.modalPresentationStyle = .overCurrentContext
            viewController.modalTransitionStyle = .coverVertical
            viewController.navigationController?.modalTransitionStyle = .coverVertical
            
            let navigationController = UINavigationController(rootViewController: vc)
            
            viewController.present(navigationController, animated: true, completion: nil)
        }
    }
    
    /**
     Show a view controller modally
     
     - parameter url:        URL
     - parameter parameters: additional parameters
     */
    @available(iOS 8.0, *)
    open func showModallyViewController(_ url: String, parameters: [String: Any]? = nil) {
        if let curViewController = currentViewController(), let viewController = figureModuleViewControllerAndParameter(url, parameters: parameters) {
            curViewController.modalPresentationStyle = .overCurrentContext
            curViewController.modalTransitionStyle = .coverVertical
            curViewController.navigationController?.modalTransitionStyle = .coverVertical
            
            curViewController.present(viewController, animated: true, completion: nil)
        }
    }
    
    /// Show a view controller within navigation modally
    ///
    /// - Parameters:
    ///   - url: URL
    ///   - parameters: additional parameters
    @available(iOS 8.0, *)
    open func showModallyViewControllerInNavigation(_ url: String, parameters: [String: Any]? = nil) {
        if let curViewController = currentViewController(), let viewController = figureModuleViewControllerAndParameter(url, parameters: parameters) {
            curViewController.modalPresentationStyle = .overCurrentContext
            curViewController.modalTransitionStyle = .coverVertical
            curViewController.navigationController?.modalTransitionStyle = .coverVertical
            
            let navigationController = UINavigationController(rootViewController: viewController)
            
            curViewController.present(navigationController, animated: true, completion: nil)
        }
    }
    
    /**
     Pop over a new view controller
     
     - parameter url:            URL
     - parameter viewController: view controller where new one show from
     - parameter sourceRect:     source area rect
     */
    open func popoverViewController(_ url: String, fromViewController viewController: UIViewController, sourceRect: CGRect) {
        if let vc = figureModuleViewControllerAndParameter(url), let popoverController = viewController.popoverPresentationController {
            viewController.navigationController?.modalPresentationStyle = .popover
            
            popoverController.sourceView = viewController.view
            popoverController.sourceRect = sourceRect
            
            viewController.present(vc, animated: true, completion: nil)
        }
    }
    
    /**
     Pop over a new view controller
     
     - parameter url:                  URL
     - parameter viewController:       view controller where new one show from
     - parameter parameters:           additional parameters
     - parameter sourceRect:           source area rect
     */
    open func popoverViewController(_ url: String, fromViewController viewController: UIViewController, parameters: [String: Any], sourceRect: CGRect) {
        if let vc = figureModuleViewControllerAndParameter(url, parameters: parameters), let popoverController = viewController.popoverPresentationController {
            viewController.navigationController?.modalPresentationStyle = .popover
            
            popoverController.sourceView = viewController.view
            popoverController.sourceRect = sourceRect
            
            viewController.present(vc, animated: true, completion: nil)
        }
    }
    
    /**
     Pop over a new view controller
     
     - parameter url:        URL
     - parameter sourceRect: source area rect
     - parameter parameters: additional parameters
     */
    @available(iOS 8.0, *)
    open func popoverViewController(_ url: String, sourceRect: CGRect, parameters: [String: Any]? = nil) {
        if let curViewController = currentViewController(), let viewController = figureModuleViewControllerAndParameter(url, parameters: parameters) {
            guard let popoverController = curViewController.popoverPresentationController else { return }
            
            curViewController.navigationController?.modalPresentationStyle = .popover
            
            popoverController.sourceView = curViewController.view
            popoverController.sourceRect = sourceRect
            
            curViewController.present(viewController, animated: true, completion: nil)
        }
    }
}
