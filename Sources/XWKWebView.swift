//
//  XWKWebView.swift
//  XWKWebView
//
//  Created by plu on 2/14/19.
//

import Foundation
import WebKit

public class XWKWebView: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
    private let webkitNamespace = "XWKWebView"
    private var webView: WKWebView
    private var pluginObjRef = Dictionary<String, AnyObject>()
    public static var enableLogging = true
    
    public init(_ webView: WKWebView) {
        self.webView = webView
        
        super.init()
        
        //inject html
        let bundle = Bundle(for: XWKWebView.self)        
        //inject bridge.js
        guard let path = bundle.path(forResource: "bridge", ofType: "js"),
            let source = try? NSString(contentsOfFile: path, encoding: String.Encoding.utf8.rawValue) else {
                XWKWebViewUtil.log("Failed to read bridge script: bridge.js")
                return
        }
        let script = WKUserScript(source: source as String, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        let userContentController = webView.configuration.userContentController
        userContentController.addUserScript(script)
        
        //inject js to native bridge
        userContentController.add(self, name: webkitNamespace)
    }
    
    public func registerPlugin(_ obj: AnyObject, namespace: String) {
        pluginObjRef["{\(namespace)}"] = obj
        
        let js =
        """
        window['\(namespace)'] = window['\(namespace)'] || {};
        """
        webView.evaluateJavaScript(js, completionHandler: { (result, error) in
            XWKWebViewUtil.log("plugin js namespace successfully injected: \(namespace)")
        })
        
        let str = NSStringFromClass(type(of: obj))
        if let cls = NSClassFromString(str) {
            let methodArr = iterateMethodForClass(cls)
            for method in methodArr {
                addJsMapForNative(method, namespace: namespace)
            }
        } else {
            XWKWebViewUtil.log("Could not locate corresponding class for obj: \(obj)")
        }
    }
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if (message.name == webkitNamespace) {
            XWKWebViewUtil.log("postMessageHandler payload: \(message.body)")
            if let body = message.body as? String {
                do {
                    if let json = body.data(using: String.Encoding.utf8) {
                        if let jsonData = try JSONSerialization.jsonObject(with: json, options: .allowFragments) as? [String: AnyObject] {
                            let namespace = jsonData["namespace"] as! String
                            let method = jsonData["method"] as! String
                            let promiseId = jsonData["promiseId"] as! String
                            let payload = jsonData["payload"]
                            
                            let selector = NSSelectorFromString("\(method)")
                            if let obj = pluginObjRef["{\(namespace)}"] {
                                if obj.responds(to: selector) {
                                    let nativePromise = XWKWebViewPromise(webView: webView, promiseId: promiseId)
                                    _ = obj.perform(NSSelectorFromString("\(method)"), with: payload, with: nativePromise)
                                } else {
                                    XWKWebViewUtil.log("No method found")
                                }
                            } else {
                                XWKWebViewUtil.log("No obj ref found")
                            }
                        }
                    }
                } catch {
                    XWKWebViewUtil.log(error)
                }
            } else {
                XWKWebViewUtil.log("failed to parse json")
            }
        } else {
            XWKWebViewUtil.log("postMessageHandler payload: unsupported webkit namespace")
        }
    }
}

extension XWKWebView {
    func iterateMethodForClass(_ cls: AnyClass) -> [String] {
        var methodCount: UInt32 = 0
        let methodList = class_copyMethodList(cls, &methodCount)
        var methodArr: [String] = []
        if let methodList = methodList, methodCount > 0 {
            enumerateCArray(array: methodList, count: methodCount) { i, m in
                let name = methodName(m: m) ?? "unknown"
                methodArr.append(name)
            }
            
            free(methodList)
        }
        return methodArr
    }
    
    func enumerateCArray<T>(array: UnsafePointer<T>, count: UInt32, f: (UInt32, T) -> Void) {
        var ptr = array
        for i in 0..<count {
            f(i, ptr.pointee)
            ptr = ptr.successor()
        }
    }
    
    func methodName(m: Method) -> String? {
        let sel = method_getName(m)
        let nameCString = sel_getName(sel)
        return String(cString: nameCString)
    }
    
    func addJsMapForNative(_ name: String, namespace: String) {
        let fn = name.replacingOccurrences(of: ":", with: "")
        let js =
        """
        window['\(namespace)'] = window['\(namespace)'] || {};
        window['\(namespace)'].\(fn) = function(payload) {
        return new Promise(function(resolve, reject) {
        var promiseId = webkit.messageHandlers.XWKWebView.generateUUID();
        webkit.messageHandlers.XWKWebView.promises[promiseId] = { resolve, reject };
        var dataToSend = {};
        dataToSend.payload = payload;
        dataToSend.namespace = '\(namespace)';
        dataToSend.method = '\(name)';
        dataToSend.promiseId = promiseId;
        var jsonString = (JSON.stringify(dataToSend));
        try {
        webkit.messageHandlers.\(webkitNamespace).postMessage(jsonString);
        } catch(e) { console.log(e) }
        });
        };
        """
        
        webView.evaluateJavaScript(js, completionHandler: { (result, error) in
            XWKWebViewUtil.log("js function injected successfully: \(namespace).\(name)")
        })
    }
}
