//
//  XWKWebViewUtil.swift
//  XWKWebView
//
//  Created by plu on 2/14/19.
//

import Foundation

public class XWKWebViewUtil {
    static func log<T>(_ object: T, filename: String = #file, line: Int = #line, funcname: String = #function) {
        if XWKWebView.enableLogging {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM/dd/yyyy HH:mm:ss:SSS"
            let process = ProcessInfo.processInfo
            let threadId = "."
            
            NSLog("%@", "\(dateFormatter.string(from: Date())) \(process.processName))[\(process.processIdentifier):\(threadId)] \((filename as NSString).lastPathComponent)(\(line)) \(funcname):\r\t\(object)\n")
        }
    }
}
