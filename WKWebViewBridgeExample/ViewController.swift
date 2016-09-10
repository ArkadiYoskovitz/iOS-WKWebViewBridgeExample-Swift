//
//  ViewController.swift
//  WKWebViewBridgeExample
//
//  Created by Priya Rajagopal on 12/8/14.
//  Copyright (c) 2014 Lunaria Software LLC. All rights reserved.
//

import UIKit
import WebKit

class ViewController : UIViewController {
    
    // MARK: - Private Properties
    private var colors  = [
        "0xff00ff",
        "#ff0000",
        "#ffcc00",
        "#ccff00",
        "#ff0033",
        "#ff0099",
        "#cc0099",
        "#0033ff",
        "#0066ff",
        "#ffff00",
        "#0000ff",
        "#0099cc"
    ]
    private var buttonClicked : Int = 0
    
    private var webConfig : WKWebViewConfiguration {
        
        // Create WKWebViewConfiguration instance
        let webCfg = WKWebViewConfiguration()
        
        // Setup WKUserContentController instance for injecting user script
        let userController = WKUserContentController()
        
        // Add a script message handler for receiving  "buttonClicked" event notifications posted from the JS document using window.webkit.messageHandlers.buttonClicked.postMessage script message
        userController.addScriptMessageHandler(self, name: "buttonClicked")
        userController.addScriptMessageHandler(self, name: "openGraphClicked")
        
        // Get script that's to be injected into the document
        if let js = buttonClickEventTriggeredScriptToAddToDocument() {
            
            // Specify when and where and what user script needs to be injected into the web document
            let userScript =  WKUserScript(source: js, injectionTime: WKUserScriptInjectionTime.AtDocumentEnd, forMainFrameOnly: false)
            
            // Add the user script to the WKUserContentController instance
            userController.addUserScript(userScript)
        }
        
        // Get script that's to be injected into the document
        if let js = OpenGraphTagsExtractionScriptToAddToDocument() {
            
            // Specify when and where and what user script needs to be injected into the web document
            let userScript =  WKUserScript(source: js, injectionTime: WKUserScriptInjectionTime.AtDocumentEnd, forMainFrameOnly: false)
            
            // Add the user script to the WKUserContentController instance
            userController.addUserScript(userScript)
        }
        
        // Configure the WKWebViewConfiguration instance with the WKUserContentController
        webCfg.userContentController = userController
        
        return webCfg
    }
    private var webView : WKWebView! {
        didSet {
            // Delegate to handle navigation of web content
            webView.navigationDelegate = self
        }
    }
    
    deinit {
        webView.configuration.userContentController.removeScriptMessageHandlerForName( "buttonClicked"   )
        webView.configuration.userContentController.removeScriptMessageHandlerForName( "openGraphClicked")
        webView.configuration.userContentController.removeAllUserScripts()
    }
    // MARK: - View LifeCycle
    override func loadView() {
        super.loadView()
        
        // Create a WKWebView instance
        webView = WKWebView (frame: view.frame, configuration: webConfig)
        view.addSubview(webView)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Load the HTML document
        loadHtml()
        //let sitePath = "http://www.google.com/"
        //let sitePath = "http://kaytana.yediot.co.il"
        let sitePath =  "http://www.yediot.co.il/Iphone/Html/Yedioth/0,,L-Article-V9-4845973,00.html"
        guard let URLObject = NSURL(string: sitePath) else {
            print("=========: ERROR: COULD NOT CREATE URL OBJCTE :=========")
            return
        }
        webView.loadRequest(NSURLRequest(URL: URLObject))
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        let fileName = "\(NSProcessInfo.processInfo().globallyUniqueString)_TestFile.html"
        let tempHtmlPath = (NSTemporaryDirectory() as NSString).stringByAppendingPathComponent(fileName)
        
        do {
            try NSFileManager.defaultManager().removeItemAtPath(tempHtmlPath)
        } catch let error as NSError {
            print("Error: \(error)")
        }
        webView = nil
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // File Loading
    func loadHtml() {
        
        // NOTE: Due to a bug in webKit as of iOS 8.1.1 we CANNOT load a local resource when running on device. Once that is fixed, we can get rid of the temp copy
        let mainBundle = NSBundle(forClass: ViewController.self)
        
        let fileName = "\( NSProcessInfo.processInfo().globallyUniqueString)_TestFile.html"
        let tempHtmlPath = (NSTemporaryDirectory() as NSString).stringByAppendingPathComponent(fileName)
        
        guard let htmlPath = mainBundle.pathForResource("TestFile", ofType: "html") else { showAlertWithMessage("Could not load HTML File!"); return }
        
        do {
            try NSFileManager.defaultManager().copyItemAtPath(htmlPath, toPath: tempHtmlPath)
        } catch let error as NSError {
            print("Error: \(error)")
        }
        let requestUrl = NSURLRequest(URL: NSURL(fileURLWithPath: tempHtmlPath))
        webView.loadRequest(requestUrl)
    }
    
    // Button Click Script to Add to Document
    func buttonClickEventTriggeredScriptToAddToDocument() -> String? {
        
        // Script: When window is loaded, execute an anonymous function that adds a "click" event handler function to the "ClickMeButton" button element. The "click" event handler calls back into our native code via the window.webkit.messageHandlers.buttonClicked.postMessage call
        var script : String?
        let mainBundle = NSBundle(forClass: ViewController.self)
        
        if let filePath = mainBundle.pathForResource("ClickMeEventRegister", ofType:"js") {
            
            script = try? String (contentsOfFile: filePath, encoding: NSUTF8StringEncoding)
        }
        return script
        
    }
    
    func OpenGraphTagsExtractionScriptToAddToDocument() -> String? {
        
        var script : String?
        let mainBundle = NSBundle(forClass: ViewController.self)
        if let filePath = mainBundle.pathForResource("OpenGraphTagsExtraction", ofType:"js") {
            
            script = try? String (contentsOfFile: filePath, encoding: NSUTF8StringEncoding)
        }
        return script
        
    }
    
    // Update color of Button with specified Id
    func updateColorOfButtonWithId(buttonId:String) {
        
        let count = UInt32(colors.count)
        let index = Int(arc4random_uniform(count))
        let color = colors [index]
        
        // Script that changes the color of tapped button
        let js2 = "var button = document.getElementById('\(buttonId)'); button.style.backgroundColor='\(color)';"
        
        webView.evaluateJavaScript(js2, completionHandler: { (AnyObject, NSError) -> Void in
            print("\(#function)")
            
        })
    }
    
    // Helper
    func showAlertWithMessage(message: String) {
        
        let alertAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) { alertAction in
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(alertAction)
        presentViewController(alertController, animated: true, completion: nil)
    }
}
// MARK: - WKNavigationDelegate
extension ViewController : WKNavigationDelegate {
    
    /*! @abstract Decides whether to allow or cancel a navigation.
     @param webView The web view invoking the delegate method.
     @param navigationAction Descriptive information about the action
     triggering the navigation request.
     @param decisionHandler The decision handler to call to allow or cancel the
     navigation. The argument is one of the constants of the enumerated type WKNavigationActionPolicy.
     @discussion If you do not implement this method, the web view will load the request or, if appropriate, forward it to another application.
     */
    @available(iOS 8.0, *)
    func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
        decisionHandler(WKNavigationActionPolicy.Allow)
    }
    
    /*! @abstract Decides whether to allow or cancel a navigation after its
     response is known.
     @param webView The web view invoking the delegate method.
     @param navigationResponse Descriptive information about the navigation
     response.
     @param decisionHandler The decision handler to call to allow or cancel the
     navigation. The argument is one of the constants of the enumerated type WKNavigationResponsePolicy.
     @discussion If you do not implement this method, the web view will allow the response, if the web view can show it.
     */
    @available(iOS 8.0, *)
    func webView(webView: WKWebView, decidePolicyForNavigationResponse navigationResponse: WKNavigationResponse, decisionHandler: (WKNavigationResponsePolicy) -> Void) {
        decisionHandler(WKNavigationResponsePolicy.Allow)
    }
    
    /*! @abstract Invoked when a main frame navigation starts.
     @param webView The web view invoking the delegate method.
     @param navigation The navigation.
     */
    @available(iOS 8.0, *)
    func webView(webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("\(#function)")
    }
    
    /*! @abstract Invoked when a server redirect is received for the main
     frame.
     @param webView The web view invoking the delegate method.
     @param navigation The navigation.
     */
    @available(iOS 8.0, *)
    func webView(webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        print("\(#function)")
    }
    
    /*! @abstract Invoked when an error occurs while starting to load data for
     the main frame.
     @param webView The web view invoking the delegate method.
     @param navigation The navigation.
     @param error The error that occurred.
     */
    @available(iOS 8.0, *)
    func webView(webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: NSError) {
        print("\(#function) With Error \(error)")
    }
    
    /*! @abstract Invoked when content starts arriving for the main frame.
     @param webView The web view invoking the delegate method.
     @param navigation The navigation.
     */
    @available(iOS 8.0, *)
    func webView(webView: WKWebView, didCommitNavigation navigation: WKNavigation!) {
        print("\(#function)")
    }
    
    /*! @abstract Invoked when a main frame navigation completes.
     @param webView The web view invoking the delegate method.
     @param navigation The navigation.
     */
    @available(iOS 8.0, *)
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        print("\(#function)")
    }
    
    /*! @abstract Invoked when an error occurs during a committed main frame
     navigation.
     @param webView The web view invoking the delegate method.
     @param navigation The navigation.
     @param error The error that occurred.
     */
    @available(iOS 8.0, *)
    func webView(webView: WKWebView, didFailNavigation navigation: WKNavigation!, withError error: NSError) {
        print("\(#function) With Error \(error)")
        showAlertWithMessage("Failed to load file with error \(error.localizedDescription)!")
    }
    
    /*! @abstract Invoked when the web view needs to respond to an authentication challenge.
     @param webView The web view that received the authentication challenge.
     @param challenge The authentication challenge.
     @param completionHandler The completion handler you must invoke to respond to the challenge. The
     disposition argument is one of the constants of the enumerated type
     NSURLSessionAuthChallengeDisposition. When disposition is NSURLSessionAuthChallengeUseCredential,
     the credential argument is the credential to use, or nil to indicate continuing without a
     credential.
     @discussion If you do not implement this method, the web view will respond to the authentication challenge with the NSURLSessionAuthChallengeRejectProtectionSpace disposition.
     */
    @available(iOS 8.0, *)
    func webView(webView: WKWebView, didReceiveAuthenticationChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
        print("\(#function)")
        completionHandler(NSURLSessionAuthChallengeDisposition.PerformDefaultHandling, nil)
    }
    
    /*! @abstract Invoked when the web view's web content process is terminated.
     @param webView The web view whose underlying web content process was terminated.
     */
    @available(iOS 9.0, *)
    func webViewWebContentProcessDidTerminate(webView: WKWebView) {
        print("\(#function)")
    }
    
}
// MARK: - WKScriptMessageHandler Delegate
extension ViewController : WKScriptMessageHandler {
    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        
        switch message.name {
            
        case "buttonClicked":
            guard let messageBody = message.body as? NSDictionary else { return }
            guard let idOfTappedButton = messageBody["ButtonId"] as? String else { return }
            updateColorOfButtonWithId(idOfTappedButton)
            
        case "openGraphClicked":
            guard let messageBody = message.body as? NSDictionary else { return }
            for (key, value) in messageBody {
                print("messageBody: key: \(key), value: \(value)")
            }
            
        default: break
        }
    }
}
