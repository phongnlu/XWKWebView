# XWKWebView

XWKWebView is a library that enhance the communication between Javascript and native Swift code. It is built on top of WKWebView and enable automatically bridging between JS function and native Swift implementation. The goal is to simplify the language binding without the need to understand how WKWebView JS bridge works.

## How it works

![XWKWebView](docs/XWKWebView.png?raw=true "XWKWebView")

XWKWebView provides true bi-directional binding between JS and Native, and the binding resolution is built on top of modern concept of [Promise](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise)

To simplify things, XWKWebView maps all declared methods of a Swift object to Javascript methods of a namespace, essentially allows plugging in Swift code to fully scoped JS namespace. The exposed JS object can then be called from typical webapp.

## Features

- Based on plugin architecture. Native Swift class is registered as plugin and mapped to JS namespace. There's no limit of number of plugin defined and number of JS namespace.
- Bridging is happened automatically, so no need to define any JS context. Once native class is registered, JS object can be used right away.
- Bridging works with both remotely hosted webapp as well as embedded local webapp
- JS method exposed as promise and native Swift can resolve/reject promise
- Works with WKWebView on iOS, macOS, Safari app extension

## Example

There's an example project [XWKWebViewDemo](https://github.com/phongnlu/XWKWebViewDemo) to showcase how to use XWKWebView

## Minimum deployment target

- iOS: 10.3
- macOS: 10.14

## Build

```cmd
> scripts/build
```

Note: [Carthage required](https://github.com/Carthage/Carthage)

## Usage

- Register plugin 

```swift
let webView = WKWebView(frame: view.frame)
let xwebview = XWKWebView(webView);
xwebview.registerPlugin(MyPlugin(), namespace: "myPlugin")
```

- Call plugin from JS

```javascript
myPlugin.foo({'this is cool': true})
.then(function(result) {
    // result is data that sent back from native through promise result
    console.log(result);
})
.catch(function(error) {
    // error is data that sent back from native through promise reject
    console.error(error);
});
```

- MyPlugin defined as

```swift
public class MyPlugin: NSObject {
    @objc func foo(_ payload: AnyObject?, _ promise: XWKWebViewPromise) {
        print("payload from JS: \(payload)")
        let nativePayload = "{\"data\": \"something useful\"}"
        promise.resolve(nativePayload)
        // Or reject
        // let nativePayload = "{\"data\": \"something is wrong\"}"
        // promise.reject(nativePayload)
    }
}
```