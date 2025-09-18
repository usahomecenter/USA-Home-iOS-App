import UIKit
import WebKit

class ViewController: UIViewController, WKNavigationDelegate, WKScriptMessageHandler {
    
    var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
        loadWebsite()
    }
    
    // MARK: - WebView Setup
    
    private func setupWebView() {
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.allowsInlineMediaPlayback = true
        webConfiguration.mediaTypesRequiringUserActionForPlayback = []
        
        // Setup user content controller with message handlers
        let userContentController = WKUserContentController()
        
        // Add native function bridges
        userContentController.add(self, name: "getLocation")
        userContentController.add(self, name: "findNearbyProfessionals")
        userContentController.add(self, name: "shareContent")
        userContentController.add(self, name: "requestLocationPermission")
        userContentController.add(self, name: "checkLocationPermission")
        
        webConfiguration.userContentController = userContentController
        
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(webView)
        
        // Set up constraints
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func loadWebsite() {
        print("🚀 USAHome: Starting app launch...")
        
        // Always prioritize remote URL for better user experience
        if let remoteURL = URL(string: "https://021e3b25-a69f-4fbd-a0a1-185392808866-00-xfyqdodsp3wj.sisko.replit.dev") {
            print("📱 USAHome: Loading remote content from: \(remoteURL)")
            let request = URLRequest(url: remoteURL)
            request.setValue("USAHome-iOS-App", forHTTPHeaderField: "User-Agent")
            webView.load(request)
        } else {
            print("❌ USAHome: Failed to create remote URL, attempting local fallback...")
            loadLocalContent()
        }
    }
    
    private func loadLocalContent() {
        // Fallback to local web content from app bundle
        if let bundlePath = Bundle.main.path(forResource: "www/index", ofType: "html"),
           let url = URL(string: "file://\(bundlePath)") {
            print("📂 USAHome: Loading local content from: \(url)")
            let request = URLRequest(url: url)
            webView.load(request)
        } else {
            print("❌ USAHome: Could not find local web content at www/index.html")
            showErrorMessage()
        }
    }
    
    private func showErrorMessage() {
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body { 
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif; 
                    text-align: center; 
                    padding: 40px 20px; 
                    background: linear-gradient(135deg, #3b82f6, #1d4ed8);
                    color: white;
                    margin: 0;
                    height: 100vh;
                    display: flex;
                    flex-direction: column;
                    justify-content: center;
                }
                .error-container { background: rgba(0,0,0,0.2); padding: 30px; border-radius: 15px; }
                h1 { margin: 0 0 20px 0; font-size: 24px; }
                p { margin: 0; font-size: 16px; line-height: 1.5; }
            </style>
        </head>
        <body>
            <div class="error-container">
                <h1>🏠 USA Home Center</h1>
                <p>Please check your internet connection and try again.</p>
            </div>
        </body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: nil)
    }
    
    // MARK: - WKScriptMessageHandler
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        let callbackId = extractCallbackId(from: message.body)
        
        switch message.name {
        case "getLocation":
            handleGetLocation(callbackId: callbackId)
            
        case "findNearbyProfessionals":
            handleFindNearbyProfessionals(message: message, callbackId: callbackId)
            
        case "shareContent":
            handleShareContent(message: message, callbackId: callbackId)
            
        case "requestLocationPermission":
            handleRequestLocationPermission(callbackId: callbackId)
            
        case "checkLocationPermission":
            handleCheckLocationPermission(callbackId: callbackId)
            
        default:
            print("Unknown message received: \(message.name)")
        }
    }
    
    // MARK: - Native Function Handlers
    
    private func handleGetLocation(callbackId: String?) {
        LocationService.shared.getCurrentLocation { [weak self] location in
            DispatchQueue.main.async {
                if let location = location {
                    let result = [
                        "success": true,
                        "data": [
                            "latitude": location.coordinate.latitude,
                            "longitude": location.coordinate.longitude,
                            "accuracy": location.horizontalAccuracy,
                            "timestamp": location.timestamp.timeIntervalSince1970
                        ]
                    ] as [String: Any]
                    self?.sendCallback(callbackId: callbackId, result: result)
                } else {
                    let result = [
                        "success": false,
                        "error": "Location not available"
                    ] as [String: Any]
                    self?.sendCallback(callbackId: callbackId, result: result)
                }
            }
        }
    }
    
    private func handleFindNearbyProfessionals(message: WKScriptMessage, callbackId: String?) {
        guard let messageBody = message.body as? [String: Any] else {
            sendCallback(callbackId: callbackId, result: ["success": false, "error": "Invalid parameters"])
            return
        }
        
        let serviceType = messageBody["serviceType"] as? String
        let radius = messageBody["radius"] as? Double ?? 50000.0
        
        LocationService.shared.findNearbyProfessionals(serviceType: serviceType, radius: radius) { [weak self] response in
            DispatchQueue.main.async {
                if let error = response["error"] as? String {
                    let result = [
                        "success": false,
                        "error": error
                    ] as [String: Any]
                    self?.sendCallback(callbackId: callbackId, result: result)
                } else {
                    let result = [
                        "success": true,
                        "data": response
                    ] as [String: Any]
                    self?.sendCallback(callbackId: callbackId, result: result)
                }
            }
        }
    }
    
    private func handleShareContent(message: WKScriptMessage, callbackId: String?) {
        guard let messageBody = message.body as? [String: Any],
              let content = messageBody["content"] as? String else {
            sendCallback(callbackId: callbackId, result: ["success": false, "error": "Invalid share content"])
            return
        }
        
        let title = messageBody["title"] as? String
        let url = messageBody["url"] as? String
        
        var items: [Any] = [content]
        
        if let title = title {
            items.append(title)
        }
        
        if let urlString = url, let shareURL = URL(string: urlString) {
            items.append(shareURL)
        }
        
        let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        // For iPad
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = self.view
            popover.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        present(activityViewController, animated: true) { [weak self] in
            let result = ["success": true] as [String: Any]
            self?.sendCallback(callbackId: callbackId, result: result)
        }
    }
    
    private func handleRequestLocationPermission(callbackId: String?) {
        LocationService.shared.requestLocationPermission { [weak self] status in
            DispatchQueue.main.async {
                let result = [
                    "success": true,
                    "data": [
                        "status": status.rawValue,
                        "authorized": status == .authorizedWhenInUse || status == .authorizedAlways
                    ]
                ] as [String: Any]
                self?.sendCallback(callbackId: callbackId, result: result)
            }
        }
    }
    
    private func handleCheckLocationPermission(callbackId: String?) {
        let locationService = LocationService.shared
        let isEnabled = locationService.isLocationServicesEnabled()
        
        let result = [
            "success": true,
            "data": [
                "enabled": isEnabled,
                "status": CLLocationManager().authorizationStatus.rawValue
            ]
        ] as [String: Any]
        
        sendCallback(callbackId: callbackId, result: result)
    }
    
    // MARK: - Helper Methods
    
    private func extractCallbackId(from messageBody: Any) -> String? {
        if let bodyDict = messageBody as? [String: Any] {
            return bodyDict["callbackId"] as? String
        }
        return nil
    }
    
    private func sendCallback(callbackId: String?, result: [String: Any]) {
        guard let callbackId = callbackId else {
            print("No callback ID provided")
            return
        }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: result)
            let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"
            
            let script = """
                if (window.nativeCallbacks && window.nativeCallbacks['\(callbackId)']) {
                    window.nativeCallbacks['\(callbackId)'](\(jsonString));
                    delete window.nativeCallbacks['\(callbackId)'];
                }
            """
            
            webView.evaluateJavaScript(script) { _, error in
                if let error = error {
                    print("Error executing callback: \(error)")
                }
            }
        } catch {
            print("Error serializing callback result: \(error)")
        }
    }
    
    // MARK: - WKNavigationDelegate
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        // Show loading indicator if needed
        print("🔄 USAHome: WebView started loading...")
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Hide loading indicator and inject native bridge JavaScript
        print("✅ USAHome: WebView finished loading successfully")
        injectNativeBridge()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        // Handle navigation errors
        print("❌ USAHome: WebView navigation failed: \(error.localizedDescription)")
        print("🔄 USAHome: Attempting local content fallback...")
        loadLocalContent()
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        // Handle provisional navigation errors (network failures, etc.)
        print("❌ USAHome: WebView provisional navigation failed: \(error.localizedDescription)")
        print("🔄 USAHome: Attempting local content fallback...")
        loadLocalContent()
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        // Allow all navigation within the app domain
        if let url = navigationAction.request.url {
            if url.host?.contains("replit.dev") == true ||
               url.host?.contains("usa-homedollar-thenilecreditle.replit.app") == true ||
               url.host?.contains("localhost") == true ||
               url.host?.contains("0.0.0.0") == true {
                decisionHandler(.allow)
                return
            }
        }
        
        decisionHandler(.allow)
    }
    
    // MARK: - JavaScript Bridge Injection
    
    private func injectNativeBridge() {
        let bridgeScript = """
            // iOS Native Bridge
            window.iOSNativeBridge = {
                callbackCounter: 0,
                callbacks: {},
                
                // Generate unique callback ID
                generateCallbackId: function() {
                    return 'callback_' + (++this.callbackCounter) + '_' + Date.now();
                },
                
                // Generic native call function
                callNative: function(functionName, parameters, callback) {
                    const callbackId = this.generateCallbackId();
                    
                    if (callback) {
                        if (!window.nativeCallbacks) {
                            window.nativeCallbacks = {};
                        }
                        window.nativeCallbacks[callbackId] = callback;
                    }
                    
                    const message = {
                        callbackId: callbackId,
                        ...parameters
                    };
                    
                    try {
                        window.webkit.messageHandlers[functionName].postMessage(message);
                    } catch (error) {
                        console.error('Error calling native function:', functionName, error);
                        if (callback) {
                            callback({ success: false, error: 'Native function not available' });
                            delete window.nativeCallbacks[callbackId];
                        }
                    }
                },
                
                // Specific native function wrappers
                getLocation: function(callback) {
                    this.callNative('getLocation', {}, callback);
                },
                
                findNearbyProfessionals: function(serviceType, radius, callback) {
                    this.callNative('findNearbyProfessionals', {
                        serviceType: serviceType,
                        radius: radius || 50000
                    }, callback);
                },
                
                shareContent: function(content, title, url, callback) {
                    this.callNative('shareContent', {
                        content: content,
                        title: title,
                        url: url
                    }, callback);
                },
                
                requestLocationPermission: function(callback) {
                    this.callNative('requestLocationPermission', {}, callback);
                },
                
                checkLocationPermission: function(callback) {
                    this.callNative('checkLocationPermission', {}, callback);
                }
            };
            
            // Make bridge globally available
            window.NativeBridge = window.iOSNativeBridge;
            
            // Legacy support for existing code
            window.getLocation = function(callback) {
                window.iOSNativeBridge.getLocation(callback);
            };
            
            window.findNearbyProfessionals = function(serviceType, radius, callback) {
                window.iOSNativeBridge.findNearbyProfessionals(serviceType, radius, callback);
            };
            
            window.shareContent = function(content, title, url, callback) {
                window.iOSNativeBridge.shareContent(content, title, url, callback);
            };
            
            // Dispatch ready event
            const event = new Event('nativeBridgeReady');
            window.dispatchEvent(event);
            
            console.log('iOS Native Bridge initialized');
        """
        
        webView.evaluateJavaScript(bridgeScript) { result, error in
            if let error = error {
                print("Error injecting native bridge: \(error)")
            } else {
                print("Native bridge injected successfully")
            }
        }
    }
}