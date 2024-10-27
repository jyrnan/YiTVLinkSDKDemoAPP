//
//  DeviceView.swift
//  YiTVLinkTestApp
//
//  Created by jyrnan on 2023/1/12.
//

import SwiftUI
import YiTVLinkSDK

struct DeviceView: View {
    @ObservedObject var vm: AppViewModel
    
    var body: some View {
        NavigationView{
            VStack {
                List(vm.devices) {device in
                    deviceView(device: device)
                        .onTapGesture {
                          Task.detached {
                            await vm.connectTo(device)
                          }
                            
                        }
                }
                .refreshable {
                    await vm.seachDevice()
                  vm.getWifiName()
                }
                
                if vm.hasConnectedToDevice != nil {
                    Text("connected to: \(vm.hasConnectedToDevice!.devName)")
                }
                LogView(vm: vm)
            }
            .navigationTitle(Text("Devices"))
            .toolbar {
              ToolbarItem(placement: .navigationBarTrailing) {
                HStack{
                  Image(systemName: vm.wifiName.isEmpty ? "wifi.slash" : "wifi")
                  Text(vm.wifiName)
                }
              }
              ToolbarItem(placement: .navigationBarLeading) {
                Button {
                  let device = DeviceInfo()
                  device.localIp = "192.168.1.104"
                  device.devName = "MockTCPServer"
                  vm.devices.append(device)
//                  vm.connectTo(device)
                } label: {
                  Text("MockTCP")
                }

              }
            }
            
        }
        .tabItem{Label("Device", systemImage: "4k.tv")}
    }
    
    @ViewBuilder
    func deviceView(device: DeviceInfo) -> some View {
//        let isConnected = device == vm.hasConnectedToDevice
        HStack{
            Image(systemName: device == vm.hasConnectedToDevice ? "4k.tv.fill" : "4k.tv")
                .font(.title)
                .foregroundColor(device == vm.hasConnectedToDevice ? .red : .primary)
            VStack{
                Text(device.devName)
                    .bold()
        
                Text("IP: \(device.localIp)")
            }
        }
        
    }
}

#Preview {
    DeviceView(vm: AppViewModel.preview)
}
