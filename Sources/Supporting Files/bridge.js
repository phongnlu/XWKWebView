webkit.messageHandlers.XWKWebView.promises = {};

webkit.messageHandlers.XWKWebView.generateUUID = function() {
    var d = new Date().getTime();
    var uuid = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx';
    uuid = uuid.replace(/[xy]/g, function(c) {
        var r = (d + Math.random()*16)%16 | 0;
        d = Math.floor(d/16);
        return (c=='x' ? r : (r&0x3|0x8)).toString(16);
    });
    return uuid;
};

webkit.messageHandlers.XWKWebView.resolvePromise = function(promiseId, data) {
    webkit.messageHandlers.XWKWebView.promises[promiseId].resolve(data);
    // remove referenfe to stored promise
    delete webkit.messageHandlers.XWKWebView.promises[promiseId];
}

webkit.messageHandlers.XWKWebView.rejectPromise = function(promiseId, error) {
    webkit.messageHandlers.XWKWebView.promises[promiseId].reject(error);    
    // remove referenfe to stored promise
    delete webkit.messageHandlers.XWKWebView.promises[promiseId];
}
