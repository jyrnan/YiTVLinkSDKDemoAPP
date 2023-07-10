//
//  AppViewModel.swift
//  YiTVLinkTestApp
//
//  Created by jyrnan on 2023/1/12.
//

import SwiftUI
import YiTVLinkSDK
import NetworkExtension
import CoreLocation



class AppViewModel: NSObject, ObservableObject, YMLListener, CLLocationManagerDelegate {
  static var mock: AppViewModel = .init(service: YMLNetwork.shared)
    
  private init(service: YMLNetwork) {
    
    self.netService = service
    super.init()
    setupLocation()
    getWifiName()
  }
  
  func setupLocation() {
    self.locationManager = CLLocationManager()
    self.locationManager?.delegate = self
    self.locationManager?.requestWhenInUseAuthorization()
  }
  
  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    getWifiName()
  }
    
  var netService: YMLNetwork
  var locationManager:CLLocationManager?

  @Published var devices: [DeviceInfo] = []
  @Published var logs: [Log] = [Log(content: "Sample string")]
  @Published var hasConnectedToDevice: DeviceInfo?
  
  @Published var fileURLs: [URL] = []
  @Published var isSharing: Bool = false
  
  @Published var wifiName: String = ""
    
  var willConnectToDevice: DeviceInfo?
    
  let testData: Data = "Test Data".data(using: .utf8)!
    
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
    
  @DeviceInfoManager
    func seachDevice() {
    netService.searchDeviceInfo(searchListener: self)
  }
    
  @DeviceInfoManager
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
    
  private func updateLog(with string: String) {
    let time = Date.now
    let timeStr = time.formatted(date: .omitted, time: .standard)
        
    DispatchQueue.main.async {
      self.logs.append(Log(content: timeStr + ": " + string))
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
    guard let fileAttribute = try? FileManager.default.attributesOfItem(atPath: fileURL.path) as NSDictionary else {return false}
    let fileSize = fileAttribute.fileSize()
    
    /// 获取共享网络URL
    guard let url = netService.shareFile(pickedURL: fileURL) else {return false}
    print(url)
    
    /// 创建数据结构
    let dic: [String: Any] = ["cmd":Int(0x510a),
                              "type":2,
                              "name":"",
                              "downloadUrl":url,
                              "packageName":"",
                              "versionName":"",
                              "versionCode":"",
                              "size":fileSize]
    guard let dicData = try? JSONSerialization.data(withJSONObject: dic) else {return false}
    
    /// 获取数据长度
    let length = UInt16(dicData.count)
    var lengthData = Data()
    withUnsafeBytes(of: length.bigEndian) { lengthData.append(contentsOf: $0)
    }
    
    ///创建完整发送数据
    var apkPacketData = Data()
    apkPacketData.append(lengthData)
    apkPacketData.append(Data.init(bytes: [0x51,0x00],count: 2))
    apkPacketData.append(dicData)
    
    #if DEBUG
    print(#line, #function, String(data: dicData, encoding: .utf8)!)
    #endif
    
    netService.sendTcpData(data: apkPacketData)
    
    return true
  }
  
  // MARK: - 投屏方法
  
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
  
  //MARK: - 遥控按键
  func sendRCKey(rcKey: RCKeyPacket) {
    netService.sendTcpData(data: rcKey.encodedData)
  }
  
  //MARK: - 空鼠按键
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
  func setWifiName(name:String) {
    self.wifiName = name
  }
}

struct Log: Identifiable {
  var id: UUID = .init()
    
  var content: String
}
