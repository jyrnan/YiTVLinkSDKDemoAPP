//
//  AppViewModel+LocalServerDelegate.swift
//  YiTVLinkSDKDemoAPP
//
//  Created by jyrnan on 2024/10/26.
//

extension AppViewModel: LocalServerDelegate {
   
    
    func localServerDidHandle(_ request: GCDWebServerRequest) {
        let path = request.path
        let method = request.method
        updateLog(with: "handled request of \"\(method) \(path)\"")
    }
    
    func localServerDidstart(with url: URL) {
        isSharing = true
        updateLog(with: "Visit \(url) in your web browser")
    }
    
    func localServerManagerDidStop() {
        isSharing = false
        updateLog(with: "Local http server stopped")
    }
    
    func localServerDidHandleCallback(_ request: GCDWebServerRequest) {
        updateLog(with: request.description)
    }
}
