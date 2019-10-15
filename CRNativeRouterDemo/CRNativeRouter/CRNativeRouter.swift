//
//  CRNativeRouter.swift
//  CRNativeRouter
//
//  Created by CrashRain on 16/7/1.
//  Copyright © 2016年 CrashRain. All rights reserved.
//

import UIKit

private func ~= (lhs: String, rhs: String) -> Bool {
    if let result = ((try? NSRegularExpression(pattern: rhs, options: .caseInsensitive).firstMatch(in: lhs, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSRange(location: 0, length: lhs.count))) as NSTextCheckingResult??) {
        return result != nil
    }
    
    return false
}

@objc public class CRNativeRouterPresentOptions: NSObject {
    var presentationStyle = UIModalPresentationStyle.overCurrentContext
    var transitionStyle = UIModalTransitionStyle.coverVertical
}

@dynamicMemberLookup
public struct CRNativeRouterParamT<Key, Value> where Key: Hashable & ExpressibleByStringLiteral {
    var wrappedValue: [Key: Value] = [:]
    
    init(dict: [Key: Value]) {
        wrappedValue = dict
    }
    
    subscript(key: Key) -> Value? {
        get {
            return wrappedValue[key]
        }
        set {
            wrappedValue[key] = newValue
        }
    }
    
    subscript(dynamicMember key: Key) -> Value? {
        return wrappedValue[key]
    }
}

public typealias CRNativeRouterParam = CRNativeRouterParamT<String, Any>

// Use it only for Objective-C
@objc public protocol CRNativeRouterProtocol: class {
    func getParametersFromRouter(_ parameter: [String: Any])
}

public protocol CRNativeRouterDelegate {
    func getParameters(from router: CRNativeRouter, parameters: CRNativeRouterParam)
}

public class CRNativeRouter: NSObject {
    
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
    
    // 映射关系
    private var mapClass: [String: CRNativeRouterViewControllerType] = [:]
    private var mapParameters: [String: [String]] = [:]
    
    // 预设的URL匹配正则表达式
    private var regularFormat = "^(Module://)(\\w+\\.md)(\\?(([a-zA-Z]+\\w*=\\w+)(&[a-zA-Z]+\\w*=\\w+)*)|([a-zA-Z]+\\w*=\\w+))?$"
    
    // 单例
    public static let shared = CRNativeRouter()
    
    @available(iOS, deprecated, message: "Use shared instead")
    @objc public class func sharedInstance() -> CRNativeRouter! {
        return shared
    }
    
    /**
     分离URL中的模块名称和参数队列
     
     - parameter url: URL
     
     - returns: 分离后的字典数据
     */
    private func divideComponentsFromUrl(_ url: String) -> [CRNativeRouterKey: String] {
        var compResult: [CRNativeRouterKey: String] = [:]
        
        do {
            // 分离模块名称
            var regularExpression = try NSRegularExpression(pattern: "://\\w+\\.md", options: [])
            var components = regularExpression.matches(in: url, options: .reportCompletion, range: NSMakeRange(0, url.count))
            
            if components.count > 0 {
                let tempRange = components[0].range
                compResult[.module] = String(url[url.index(url.startIndex, offsetBy: tempRange.location + 3) ..< url.index(url.startIndex, offsetBy: tempRange.location + tempRange.length)])
            }
            
            // 分离参数
            regularExpression = try NSRegularExpression(pattern: "\\?[\\w|&|=]*$", options: [])
            components = regularExpression.matches(in: url, options: .reportCompletion, range: NSMakeRange(0, url.count))
            
            if components.count > 0 {
                let tempRange = components[0].range
                compResult[.parameters] = String(url[url.index(url.startIndex, offsetBy: tempRange.location + 1) ..< url.index(url.startIndex, offsetBy: tempRange.location + tempRange.length)])
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
    private func reflectViewController(_ module: String) -> UIViewController? {
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
    private func viewControllerParametersCheck(_ module: String, parameter: String, paramDict: [String: Any]? = nil) -> Bool {
        guard let requiredList = mapParameters[module], requiredList.count > 0 else { return true }
        
        let components = parameter.components(separatedBy: "&")
        var params = Set<String>()
        
        components.filter { $0.count > 0 }.forEach { params.insert($0.components(separatedBy: "=")[0]) }
        
        if let additionalParams = paramDict {
            params.formUnion(Set<String>(additionalParams.keys))
        }
        
        return Set(requiredList).intersection(params).count == requiredList.count
    }
    
    /**
     生成视图控制器参数对应的字典数据
     
     - parameter parameter: 参数队列字符串
     
     - returns: 参数字典数据
     */
    private func viewControllerParameterGenerate(_ parameter: String, paramDict: [String: Any]? = nil) -> [String: Any] {
        guard parameter != "" else { return paramDict ?? [:] }

        let components = parameter.components(separatedBy: "&")
        var params: [String: Any] = [:]
        
        components.forEach { item in
            let refs = item.components(separatedBy: "=")
            
            if let intValue = Int(refs[1]), "\(intValue)" == refs[1] {
                params[refs[0]] = intValue
            } else if let doubleValue = Double(refs[1]), "\(doubleValue)" == refs[1] {
                params[refs[0]] = doubleValue
            } else {
                params[refs[0]] = refs[1]
            }
        }
        
        if let additionalParam = paramDict {
            params.merge(additionalParam) { (_, new) -> Any in new }
        }
        
        return params
    }
    
    /**
     返回URL对应的视图控制器，并且完成对应的参数初始化
     
     - parameter url: URL
     
     - returns: 视图控制器
     */
    private func configureModule(_ url: String, parameters: [String: Any]? = nil) -> UIViewController? {
        guard url ~= regularFormat else { return nil }
        
        let components = divideComponentsFromUrl(url)
        guard let module = components[.module] else { return nil }
        let parameterStr = components[.parameters] ?? ""
        
        guard viewControllerParametersCheck(module, parameter: parameterStr, paramDict: parameters), let viewController = reflectViewController(module) else { return nil }
        
        if let p = mapParameters[module], p.count > 0 && !(viewController is CRNativeRouterProtocol || viewController is CRNativeRouterDelegate) {
            return nil
        }
        
        let paramDict = viewControllerParameterGenerate(parameterStr, paramDict: parameters)
        if viewController is CRNativeRouterDelegate {
            (viewController as! CRNativeRouterDelegate).getParameters(from: self, parameters: CRNativeRouterParam(dict: paramDict))
        } else if viewController is CRNativeRouterProtocol {
            (viewController as! CRNativeRouterProtocol).getParametersFromRouter(paramDict)
        }
        
        return viewController
    }
    
    /**
     获取当前显示的视图控制器
     
     - returns: 当前显示的视图控制器
     */
    public func currentViewController() -> UIViewController? {
        guard let rootViewController = UIApplication.shared.keyWindow?.rootViewController else { return nil }
        
        return recursionTopViewController(rootViewController)
    }
    
    /**
     递归查找显示的视图控制器
     
     - parameter rootViewController: 开始查找的视图控制器结点
     
     - returns: 视图控制器
     */
    private func recursionTopViewController(_ rootViewController: UIViewController) -> UIViewController {
        if let navigationController = rootViewController as? UINavigationController, let topViewController = navigationController.topViewController {
            return recursionTopViewController(topViewController)
        } else if let tabBarController = rootViewController as? UITabBarController {
            if let viewControllers = tabBarController.viewControllers {
                return recursionTopViewController(viewControllers[tabBarController.selectedIndex])
            } else {
                return tabBarController
            }
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
    public func setURLModifyFormat(_ format: String) {
        regularFormat = format
    }
    
    /**
     注册新的视图控制器
     
     - parameter name:       视图控制器名称
     - parameter type:       视图控制器类型
     - parameter parameters: 对应的参数名称列表
     
     - returns: 注册结果
     */
    @discardableResult
    public func registerModule(_ name: String, type: AnyClass, parameters: [String]?) -> Bool {
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
    public func registerModule(_ name: String, type: AnyClass, nib: String, parameters: [String]?) -> Bool {
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
    public func registerModule(_ name: String, type: AnyClass, storyboard: String, identifier: String, parameters: [String]?) -> Bool {
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
    public func registerModules(fromConfiguration configuration: String) {
        guard let plistPath = Bundle.main.path(forResource: configuration, ofType: "plist") else { return }
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
                
                _ = registerModule(name, type: className, storyboard: storyboard, identifier: identifier, parameters: parameters)
            } else if let nib = module["nib"] as? String {
                _ = registerModule(name, type: className, nib: nib, parameters: parameters)
            } else {
                _ = registerModule(name, type: className, parameters: parameters)
            }
        }
    }
    
    /**
     从plist总文件中获取各个分plist文件，并注册视图控制器
     
     - parameter filename: plist文件名称
     */
    public func registerGroupModules(fromConfiguration configuration: String) {
        guard let plistPath = Bundle.main.path(forResource: configuration, ofType: "plist") else { return }
        guard let groupArray = NSArray(contentsOfFile: plistPath) as? [String] else { return }
        
        groupArray.forEach { registerModules(fromConfiguration: $0) }
    }
    
    /**
     Navigation controller show a new view controller
     
     - parameter url:                  URL
     - parameter navigationController: navigation controller
     - parameter delegate: navigation controller delegate
    */
    @discardableResult
    private func showViewController(_ url: String, parameters: [String: Any]? = nil, pushTo navigation: UINavigationController? = nil, delegate: UINavigationControllerDelegate? = nil, type: CRNativeRouterViewPresentType = .show) -> UIViewController? {
        guard let viewController = configureModule(url, parameters: parameters) else { return nil }
        guard let navigationController = navigation ?? currentViewController()?.navigationController else { return nil }
        
        navigationController.delegate = delegate
        if type == .showDetail {
            navigationController.showDetailViewController(viewController, sender: self)
        } else {
            navigationController.show(viewController, sender: self)
        }
        
        return viewController
    }
    
    @discardableResult
    @objc public func present(_ url: String, parameters: [String: Any]? = nil, from current: UIViewController? = nil, inNavigation: Bool = false, params: CRNativeRouterPresentOptions = .init()) -> UIViewController? {
        guard let viewController = configureModule(url, parameters: parameters) else { return nil }
        guard let from = current ?? currentViewController() else { return nil }
        
        let newViewController = inNavigation ? (viewController.navigationController ?? UINavigationController(rootViewController: viewController)) : viewController
        newViewController.modalPresentationStyle = params.presentationStyle
        newViewController.modalTransitionStyle = params.transitionStyle
        from.present(newViewController, animated: true, completion: nil)
        
        return viewController
    }
    
    @discardableResult
    @objc public func popover(_ url: String, parameters: [String: Any]? = nil, from current: UIViewController? = nil, sourceRect: CGRect) -> UIViewController? {
        guard let viewController = configureModule(url, parameters: parameters) else { return nil }
        guard let from = current ?? currentViewController() else { return nil }
        guard let popoverController = from.popoverPresentationController else { return nil }
        
        viewController.navigationController?.modalPresentationStyle = .popover
        viewController.modalPresentationStyle = .popover
        
        popoverController.sourceView = from.view
        popoverController.sourceRect = sourceRect
        from.present(viewController.navigationController ?? viewController, animated: true, completion: nil)
        
        return viewController
    }
    
    @discardableResult
    @objc public func show(_ url: String, parameters: [String: Any]? = nil, navigation: UINavigationController? = nil, delegate: UINavigationControllerDelegate? = nil) -> UIViewController? {
        return showViewController(url, parameters: parameters, pushTo: navigation, delegate: delegate)
    }
    
    @discardableResult
    @objc public func showDetail(_ url: String, parameters: [String: Any]? = nil, navigation: UINavigationController? = nil, delegate: UINavigationControllerDelegate? = nil) -> UIViewController? {
        return showViewController(url, parameters: parameters, pushTo: navigation, delegate: delegate, type: .showDetail)
    }
    
    /**
     Navigation controller show a new view controller
     
     - parameter url:                  URL
     - parameter navigationController: navigation controller
     */
    @available(iOS, deprecated: 8.0, message: "API renamed, use show instead")
    @discardableResult
    @objc public func navigationControllerShowViewController(_ url: String, navigationController: UINavigationController?, delegate: UINavigationControllerDelegate?) -> UIViewController? {
        return show(url, navigation: navigationController, delegate: delegate)
    }
    
    /**
     Navigation controller show a new view controller
     
     - parameter url:                  URL
     - parameter parameters:           additional parameters
     - parameter navigationController: navigation controller
     */
    @available(iOS, deprecated: 8.0, message: "API renamed, use show instead")
    @discardableResult
    @objc public func navigationControllerShowViewController(_ url: String, parameters: [String: Any], navigationController: UINavigationController, delegate: UINavigationControllerDelegate?) -> UIViewController? {
        return show(url, parameters: parameters, navigation: navigationController, delegate: delegate)
    }
    
    @available(iOS, deprecated: 8.0, message: "API renamed, use show instead")
    @discardableResult
    @objc public func navigationControllerShowViewController(_ url: String, parameters: [String: Any], navigationController: UINavigationController?) -> UIViewController? {
        return show(url, parameters: parameters, navigation: navigationController)
    }
    
    /**
     Navigation controller show a new view controller
     
     - parameter url:        URL
     - parameter parameters: additional parameters
     */
    @available(iOS, deprecated: 8.0, message: "API renamed, use show instead")
    @discardableResult
    @objc public func showViewController(_ url: String, parameters: [String: Any]?, delegate: UINavigationControllerDelegate?) -> UIViewController? {
        return show(url, parameters: parameters, delegate: delegate)
    }
    
    @available(iOS, deprecated: 8.0, message: "API renamed, use show instead")
    @discardableResult
    @objc public func showViewController(_ url: String, parameters: [String: Any]?) -> UIViewController? {
        return show(url, parameters: parameters)
    }
    
    /**
     Navigation controller show detail a new view controller
     
     - parameter url:                  URL
     - parameter navigationController: navigation controller
     */
    @available(iOS, deprecated: 8.0, message: "API renamed, use showDetail instead")
    @discardableResult
    @objc public func navigationControllerShowDetailViewController(_ url: String, navigationController: UINavigationController?, delegate: UINavigationControllerDelegate?) -> UIViewController? {
        return showDetail(url, navigation: navigationController, delegate: delegate)
    }
    
    @available(iOS, deprecated: 8.0, message: "API renamed, use showDetail instead")
    @discardableResult
    @objc public func navigationControllerShowDetailViewController(_ url: String, navigationController: UINavigationController?) -> UIViewController? {
        return showDetail(url, navigation: navigationController)
    }
    
    /**
     Navigation controller show detail a new view controller
     
     - parameter url:                  URL
     - parameter parameters:           additional parameters
     - parameter navigationController: navigation controller
     */
    @available(iOS, deprecated: 8.0, message: "API renamed, use showDetail instead")
    @discardableResult
    @objc public func navigationControllerShowDetailViewController(_ url: String, parameters: [String: Any], navigationController: UINavigationController?, delegate: UINavigationControllerDelegate?) -> UIViewController? {
       return showDetail(url, parameters: parameters, navigation: navigationController, delegate: delegate)
    }
    
    @available(iOS, deprecated: 8.0, message: "API renamed, use showDetail instead")
    @discardableResult
    @objc public func navigationControllerShowDetailViewController(_ url: String, parameters: [String: Any], navigationController: UINavigationController?) -> UIViewController? {
        return showDetail(url, parameters: parameters, navigation: navigationController)
    }
    
    /**
     Navigation controller show detail a new view controller
     
     - parameter url:        URL
     - parameter parameters: additional parameters
     */
    @available(iOS, deprecated: 8.0, message: "API renamed, use showDetail instead")
    @discardableResult
    @objc public func showDetailViewController(_ url: String, parameters: [String: Any]?, delegate: UINavigationControllerDelegate?) -> UIViewController? {
        return showDetail(url, parameters: parameters, delegate: delegate)
    }
    
    @available(iOS, deprecated: 8.0, message: "API renamed, use showDetail instead")
    @discardableResult
    @objc public func showDetailViewController(_ url: String, parameters: [String: Any]? = nil) -> UIViewController? {
        return showDetail(url, parameters: parameters)
    }
    
    /**
     Show a view controller modally
     
     - parameter url:            URL
     - parameter viewController: view controller where new one show from
     */
    @available(iOS, deprecated: 8.0, message: "API renamed, use present instead")
    @discardableResult
    @objc public func showModallyViewController(_ url: String, fromViewController viewController: UIViewController) -> UIViewController? {
        return present(url, from: viewController)
    }
    
    
    /// Show a view controller within navigation modally
    ///
    /// - Parameters:
    ///   - url: URL
    ///   - viewController: view controller where new one show from
    @available(iOS, deprecated: 8.0, message: "API renamed, use present instead")
    @discardableResult
    @objc public func showModallyViewControllerInNavigation(_ url: String, fromViewController viewController: UIViewController) -> UIViewController? {
        return present(url, from: viewController, inNavigation: true)
    }
    
    /**
     Show a view controller modally
     
     - parameter url:                  URL
     - parameter viewController:       view controller where new one show from
     - parameter parameters:           additional parameters
     */
    @available(iOS, deprecated: 8.0, message: "API renamed, use present instead")
    @discardableResult
    @objc public func showModallyViewController(_ url: String, fromViewController viewController: UIViewController, parameters: [String: Any]) -> UIViewController? {
        return present(url, parameters: parameters, from: viewController)
    }
    
    
    /// Show a view controller within navigation modally
    ///
    /// - Parameters:
    ///   - url: URL
    ///   - viewController: view controller where new one show from
    ///   - parameters: additional parameters
    @available(iOS, deprecated: 8.0, message: "API renamed, use present instead")
    @discardableResult
    @objc public func showModallyViewControllerInNavigation(_ url: String, fromViewController viewController: UIViewController, parameters: [String: Any]) -> UIViewController? {
        return present(url, parameters: parameters, from: viewController, inNavigation: true)
    }
    
    /**
     Show a view controller modally
     
     - parameter url:        URL
     - parameter parameters: additional parameters
     */
    @available(iOS, deprecated: 8.0, message: "API renamed, use present instead")
    @discardableResult
    @objc public func showModallyViewController(_ url: String, parameters: [String: Any]? = nil) -> UIViewController? {
        return present(url, parameters: parameters)
    }
    
    /// Show a view controller within navigation modally
    ///
    /// - Parameters:
    ///   - url: URL
    ///   - parameters: additional parameters
    @available(iOS, deprecated: 8.0, message: "API renamed, use present instead")
    @discardableResult
    @objc public func showModallyViewControllerInNavigation(_ url: String, parameters: [String: Any]? = nil) -> UIViewController? {
        return present(url, parameters: parameters, inNavigation: true)
    }
    
    /**
     Pop over a new view controller
     
     - parameter url:            URL
     - parameter viewController: view controller where new one show from
     - parameter sourceRect:     source area rect
     */
    @available(iOS, deprecated: 8.0, message: "API renamed, use popover instead")
    @discardableResult
    @objc public func popoverViewController(_ url: String, fromViewController viewController: UIViewController, sourceRect: CGRect) -> UIViewController? {
        return popover(url, from: viewController, sourceRect: sourceRect)
    }
    
    /**
     Pop over a new view controller
     
     - parameter url:                  URL
     - parameter viewController:       view controller where new one show from
     - parameter parameters:           additional parameters
     - parameter sourceRect:           source area rect
     */
    @available(iOS, deprecated: 8.0, message: "API renamed, use popover instead")
    @discardableResult
    @objc public func popoverViewController(_ url: String, fromViewController viewController: UIViewController, parameters: [String: Any], sourceRect: CGRect) -> UIViewController? {
        return popover(url, parameters: parameters, from: viewController, sourceRect: sourceRect)
    }
    
    /**
     Pop over a new view controller
     
     - parameter url:        URL
     - parameter sourceRect: source area rect
     - parameter parameters: additional parameters
     */
    @available(iOS, deprecated: 8.0, message: "API renamed, use popover instead")
    @discardableResult
    @objc public func popoverViewController(_ url: String, sourceRect: CGRect, parameters: [String: Any]? = nil) -> UIViewController? {
        return popover(url, parameters: parameters, sourceRect: sourceRect)
    }
}
