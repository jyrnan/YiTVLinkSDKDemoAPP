//
//  AppViewModel.swift
//  YiTVLinkTestApp
//
//  Created by jyrnan on 2023/1/12.
//

import SwiftUI
import YiTVLinkSDK

class AppViewModel: ObservableObject, YMLListener {
    static var mock: AppViewModel {
        AppViewModel(service: YMLNetwork.shared)
    }
            
    private init(service: YMLNetwork) {
        self.netService = service
    }
    
    var netService: YMLNetwork = .shared
    
    init() {}
    
    @Published var devices: [DeviceInfo] = []
    @Published var logs: [Log] = [Log(content: "Sample string")]
    @Published var hasConnectedToDevice: DeviceInfo?
    
    var willConnectToDevice: DeviceInfo?
    
    let testData: Data = "Test Data".data(using: .utf8)!
    
    // MARK: - ListenerProtocol
    
    func deliver(data: Data) {
        if let str = String(data: data, encoding: .utf8), str.count != 0 {
            updateLog(with: str)
            print(str.count)
        }
        else {
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
        
       self.setConnectedDevice(device: nil)
        updateLog(with: error.localizedDescription)
    }
    
    func seachDevice() {
        netService.searchDeviceInfo(searchListener: self)
    }
    
    func connectTo(_ device: DeviceInfo) {
        guard device != hasConnectedToDevice else {return}
        willConnectToDevice = device
        
        if hasConnectedToDevice != nil {
            netService.closeTcpChannel()}
        
        netService.receiveTcpData(TCPListener: self)
        
        _ = netService.createUdpChannel(info: device)
        _ = netService.createTcpChannel(info: device)
    }
    
    func disconnectCurrentDevice() {
        
        netService.closeTcpChannel()
        setConnectedDevice(device: nil)
    }
    
    func testSendTcpData() {
        netService.sendTcpData(data: testData)
    }
    
    func testSendGenneralCommand() {
        _ = netService.sendGeneralCommand(command: RemoteControl(cmd: .CTRL_TYPE_MOUSE, keyData: KEYData()))
    }
    
    private func updateLog(with string: String) {
        let time = Date.now
        let timeStr = time.formatted(date: .omitted, time: .shortened)
        
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
}

struct Log: Identifiable {
    var id: UUID = .init()
    
    var content: String
}
