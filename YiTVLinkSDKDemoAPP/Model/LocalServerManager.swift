//
//  LocalServerManager.swift
//  YiTVLinkSDKDemoAPP
//
//  Created by jyrnan on 2024/10/25.
//

import Foundation
/// 当前GCDWebserver是采用了直接内置源码方式，通过桥接文件实现直接混编，无需import框架
/// 也可以通过SPM来引入，需要import框架

protocol LocalServerDelegate {
    func localServerDidstart(with url: URL)
    func localServerManagerDidStop()
    func localServerDidHandle(_ request: GCDWebServerRequest)
    func localServerDidHandleCallback(_ request: GCDWebServerRequest)
}

class LocalServerManager: Observable {
    let HTTP_SERVER_PORT: UInt = 8089
    let welcomeText = "Welcome to YiMultiScreen!"
    
    let webServer = GCDWebServer()
    var delegate: LocalServerDelegate?
    
    /// 保存当前共享文件的url
    var sharingFileURLs: [String: URL] = [:]
    
    init() { initWebServer() }
    
    func start() {
        guard !webServer.isRunning else { return }
        webServer.start(withPort: HTTP_SERVER_PORT, bonjourName: "http")
        
        if let url = webServer.serverURL {
            print("Visit \(url) in your web browser")
            delegate?.localServerDidstart(with: url)
        }
    }
    
    func stop() {
        guard webServer.isRunning else { return }
        webServer.stop()
        delegate?.localServerManagerDidStop()
    }
    
    /// 设置http的request请求的处理方法
    func initWebServer() {
        
        /// 处理通用文件下载请求
        webServer.addDefaultHandler(forMethod: "GET", request: GCDWebServerRequest.self) { [weak self] request in
            guard let self else { return nil }
            self.delegate?.localServerDidHandle(request)
                
            let path: String = request.path
            switch path {
            case "/":
                return GCDWebServerDataResponse(html: "<html><body><p>[ \(Date.now.formatted()) ] \(welcomeText)</p></body></html>")
            default:
                let urlKey = String(path.dropFirst())
                    
                /// 查找已保存的文件路径，如不存在，返回not found
                guard let fileUrl = self.sharingFileURLs[urlKey] else {
                    return GCDWebServerDataResponse(html: "<html><body><p>[ \(Date.now.formatted()) ] \(self.welcomeText) <br> Request not found.</p></body></html>")
                }
                    
                /// 存在文件路径，返回文件数据
                return GCDWebServerFileResponse(file: fileUrl.path)
            }
        }
        
        /// 处理callback请求，会把请求直接传给代理
        webServer.addHandler(forMethod: "GET", path: "/callback", request: GCDWebServerRequest.self) { [weak self] request in
            guard let self else { return nil }
            self.delegate?.localServerDidHandleCallback(request)
                
            return GCDWebServerDataResponse(html: "<html><body><p>[ \(Date.now.formatted()) ] \(self.welcomeText) <br> \(request.description)</p></body></html>")
        }
    }
                                    
    // MARK: - File Share
    
    /// 将需要共享的文件的url保存在manager中并生成索引，利用索引返回通过http服务访问地址
    /// - Parameter pickedURL: 需要共享文件的url
    /// - Returns: 通过http服务访问文件的url
    func prepareFileForShareNoCopy(fileUrl: URL) -> String? {
        guard webServer.isRunning else { return nil }
    
        let urlKey = String(UUID().uuidString.prefix(8)) // 采用8位随机数代替文件名做索引
//        let filename = pickedURL.lastPathComponent
        sharingFileURLs[urlKey] = fileUrl
        
        return makeShareUrl(filename: urlKey)
    }
  
    func makeShareUrl(filename: String) -> String? {
        guard let host = webServer.serverURL else { return nil }
       
        return "\(host)\(filename)"
    }
}
