//
//  AppViewModel.swift
//  YiTVLinkTestApp
//
//  Created by jyrnan on 2023/1/12.
//

import CoreLocation
import NetworkExtension
import SwiftUI
import YiTVLinkSDK

class AppViewModel: NSObject, ObservableObject, YMLListener, CLLocationManagerDelegate {
    static var mock: AppViewModel = .init(service: YMLNetwork.shared)
    
    static var preview: AppViewModel {
        return AppViewModel(service: .shared)
            .setupPreview()
    }
    
    var netService: YMLNetwork
    var locationManager: CLLocationManager?
    var localServerManager:LocalServerManager?
    
    @Published var devices: [DeviceInfo] = []
    @Published var hasConnectedToDevice: DeviceInfo?
  
    @Published var fileURLs: [URL] = []
    @Published var isSharing: Bool = false
  
    @Published var wifiName: String = ""
    
    // App中LogView中显示的信息
    @Published var logString: String = "Logs:\n"

    var willConnectToDevice: DeviceInfo?
    
    let testData: Data = "Test Data".data(using: .utf8)!
    
    // MARK: - init & Setup

    init(service: YMLNetwork) {
        self.netService = service
        super.init()
        setupLocation()
        getWifiName()
    }
  
    func setupLocation() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.requestWhenInUseAuthorization()
    }
    
    private func setupPreview() -> AppViewModel {
        logString = "Some Logs"
        return self
    }
  
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        getWifiName()
    }
    
    func setupLocalServer() {
        localServerManager = LocalServerManager()
        localServerManager?.delegate = self
    }
    
    func startLocalServer() {
        if localServerManager == nil {
            setupLocalServer()
        }
        localServerManager?.start()
    }
    
    func stopLocalServer() {
        localServerManager?.stop()
    }
    
    // MARK: - ListenerProtocol
    
    func deliver(data: Data) {
        if let str = String(data: data, encoding: .utf8), str.count != 0 {
            updateLog(with: str)
            print(str.count)
        } else {
            let str = "Unregonized data with length: \(data.count)"
            updateLog(with: str)
        }
    }
    
    func notified(with message: String) {
        updateLog(with: message)
        switch message {
        case "TCPCONNECTED":
            setConnectedDevice(device: willConnectToDevice)
        case "TCPDISCONNECTED":
            setConnectedDevice(device: nil)
        case "WIFICONNECTED":
            getWifiName()
        case "WIFIDISCONNECTED":
            Task {
                await setWifiName(name: "")
                print(#line, #function, "Wifi disconnected")
            }
        case "FILE_SERVER_STARTED":
            Task { @MainActor in
                isSharing = true
            }
        case "FILE_SERVER_STOPPED":
            Task { @MainActor in
                isSharing = false
            }
        default:
            break
        }
    }
    
    func deliver(devices: [YiTVLinkSDK.DeviceInfo]) {
        DispatchQueue.main.async {
            self.devices = devices
        }
    }
    
    func notified(error: Error) {
        setConnectedDevice(device: nil)
        updateLog(with: error.localizedDescription)
    }
    
    @DeviceInfoManagerActor
    func seachDevice() {
        netService.searchDeviceInfo(searchListener: self)
    }
    
    @DeviceInfoManagerActor
    func connectTo(_ device: DeviceInfo) {
        guard device != hasConnectedToDevice else { return }
        willConnectToDevice = device
        
        if hasConnectedToDevice != nil {
            netService.closeTcpChannel()
        }
        
        netService.receiveTcpData(TCPListener: self)
        
        _ = netService.createUdpChannel(info: device)
        _ = netService.createTcpChannel(info: device)
    }
    
    func disconnectCurrentDevice() {
        netService.closeTcpChannel()
        setConnectedDevice(device: nil)
    }
    
    func testSendTcpData() {
        var data = Data()
        data.append(contentsOf: [0x00, 0x00, 0x30, 0x03])
        netService.sendTcpData(data: data)
    }
    
    func testSendGenneralCommand() {
        _ = netService.sendGeneralCommand(command: RemoteControl(cmd: .CTRL_TYPE_MOUSE, keyData: KEYData()))
    }
    
    func updateLog(with string: String) {
        let time = Date.now
        let timeStr = time.formatted(date: .omitted, time: .standard)
        
        DispatchQueue.main.async {
            self.logString += "[ " + timeStr + " ]: " + string + "\n"
        }
    }
    
    private func setConnectedDevice(device: DeviceInfo?) {
        DispatchQueue.main.async { [self] in
            self.hasConnectedToDevice = device
            willConnectToDevice = nil
        }
    }

    // MARK: - 安装应用
 
    func shareAPK(fileURL: URL) -> Bool {
        /// 获取文件大小
        guard let fileAttribute = try? FileManager.default.attributesOfItem(atPath: fileURL.path) as NSDictionary else { return false }
        let fileSize = fileAttribute.fileSize()
    
        /// 获取共享网络URL
        guard let url = netService.shareFile(pickedURL: fileURL) else { return false }
        print(url)
    
        /// 创建数据结构
        let dic: [String: Any] = ["cmd": Int(0x510a),
                                  "type": 2,
                                  "name": "",
                                  "downloadUrl": url,
                                  "packageName": "",
                                  "versionName": "",
                                  "versionCode": "",
                                  "size": fileSize]
        guard let dicData = try? JSONSerialization.data(withJSONObject: dic) else { return false }
    
        /// 获取数据长度
        let length = UInt16(dicData.count)
        var lengthData = Data()
        withUnsafeBytes(of: length.bigEndian) { lengthData.append(contentsOf: $0)
        }
    
        /// 创建完整发送数据
        var apkPacketData = Data()
        apkPacketData.append(lengthData)
        apkPacketData.append(Data(bytes: [0x51, 0x00], count: 2))
        apkPacketData.append(dicData)
    
        #if DEBUG
        print(#line, #function, String(data: dicData, encoding: .utf8)!)
        #endif
    
        netService.sendTcpData(data: apkPacketData)
    
        return true
    }
  
    // MARK: - 投屏方法
    
    func shareFile(fileURL: URL) {
        if let url = localServerManager?.prepareFileForShareNoCopy(fileUrl: fileURL) {
            updateLog(with: "\(url)")
        }
    }
  
    func sharePicture(fileURL: URL) {
        if let url = netService.shareFile(pickedURL: fileURL) {
            print(url)
      
            let sharePicturePacket = PlayMediaFilePacket(file_size: 0, have_next_flag: .no, local_ip: getWiFiAddress(), file_name: url + "&MP")
            netService.sendTcpData(data: sharePicturePacket.encodedData)
      
            isSharing = true
        }
    }
  
    func shareMovie(fileURL: URL) {
        if let url = netService.shareFile(pickedURL: fileURL) {
            print(url)
            let sharePicturePacket = PlayMediaFilePacket(file_size: 0, have_next_flag: .no, local_ip: getWiFiAddress(), file_name: url + "&MV")
            netService.sendTcpData(data: sharePicturePacket.encodedData)
     
            isSharing = true
        }
    }
  
    // MARK: - 遥控按键

    func sendRCKey(rcKey: RCKeyPacket) {
        netService.sendTcpData(data: rcKey.encodedData)
    }
  
    // MARK: - 空鼠按键

    func sendMouseEvent(event: MouseEventPacket) {
        netService.sendTcpData(data: event.encodedData)
    }
  
    // MARK: - Fileserver operation（可能不需要）

    // TOOD: - 可以不需要
    public func loadFiles() {
        do {
            let documentsDirectory = try URL.serverRoot()
      
            let fileUrls = try FileManager.default.contentsOfDirectory(
                at: documentsDirectory,
                includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles)
            fileURLs = fileUrls
        } catch {
            print(error)
        }
    }

    public func deleteFile(at offsets: IndexSet) {
        let urlsToDelete = offsets.map { fileURLs[$0] }
        fileURLs.remove(atOffsets: offsets)
        for url in urlsToDelete {
            try? FileManager.default.removeItem(at: url)
        }
    }
  
    // MARK: - 检测Wi-Fi名
  
    func getWifiName() {
        let wifiName = NetworkTool.getWIFISSID()
        Task {
            await setWifiName(name: wifiName)
        }
    }
  
    @MainActor
    func setWifiName(name: String) {
        wifiName = name
    }
}
