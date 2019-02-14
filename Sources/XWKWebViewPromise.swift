//
//  XWKWebViewPromise.swift
//  XWKWebView
//
//  Created by plu on 2/14/19.
//

import Foundation
import WebKit

public class XWKWebViewPromise: NSObject {
    private var webView: WKWebView
    private var promiseId: String
    private var payload: String?
    
    init(webView: WKWebView, promiseId: String) {
        self.webView = webView
        self.promiseId = promiseId
    }
    
    public func resolve(_ payload: String?) {
        var result = "{}"
        if let payload = payload {
            result = payload
        }
        let js =
        """
        webkit.messageHandlers.XWKWebView.resolvePromise('\(promiseId)', \(result));
        """
        webView.evaluateJavaScript(js, completionHandler: { (result, error) in
            XWKWebViewUtil.log("promise resolved")
        })
    }
    
    public func resolve() {
        resolve(nil)
    }
    
    public func reject(_ payload: String?) {
        var result = "{}"
        if let payload = payload {
            result = payload
        }
        let js =
        """
        webkit.messageHandlers.XWKWebView.rejectPromise('\(promiseId)', \(result));
        """
        webView.evaluateJavaScript(js, completionHandler: { (result, error) in
            XWKWebViewUtil.log("promise rejected")
        })
    }
    
    public func reject() {
        reject(nil)
    }
}
