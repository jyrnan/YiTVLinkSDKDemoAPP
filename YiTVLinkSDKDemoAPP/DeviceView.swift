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
                            vm.connectTo(device)
                        }
                }
                .refreshable {
                    vm.seachDevice()
                }
                
                if vm.hasConnectedToDevice != nil {
                    Text("connected to: \(vm.hasConnectedToDevice!.devName)")
                }
                Text("下拉刷新设备").padding()
            }
            .navigationTitle(Text("Devices"))
            
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

struct DeviceView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(vm: AppViewModel.mock)
    }
}
