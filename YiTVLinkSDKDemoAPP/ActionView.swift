//
//  ActionView.swift
//  YiTVLinkTestApp
//
//  Created by jyrnan on 2023/1/12.
//

import SwiftUI

struct ActionView: View {
    @ObservedObject var vm: AppViewModel
    var isTvConnected: Bool {vm.hasConnectedToDevice != nil}
    
    var body: some View {
        NavigationView{
            VStack {
                VStack{
                    Image(systemName: isTvConnected ? "4k.tv.fill" : "4k.tv")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .imageScale(.large)
                        .foregroundColor(isTvConnected ? .accentColor : .gray)
                        .frame(width: 160, height: 160)
                    if isTvConnected {
                        Text("当前连接电视").padding()
                    }
                    Text("\(vm.hasConnectedToDevice?.devName ?? "没有电视连接")")
                        .padding()
                }
                .padding()
                
                Spacer()
                
                VStack {
                    Button("测试发送TCP数据", action: {vm.testSendTcpData()})
                        .padding()
                        .disabled(!isTvConnected)
                    Button("测试发送UDP命令", action: {vm.testSendGenneralCommand()})
                        .padding()
                        .disabled(!isTvConnected)
                    Button("断开当前设备连接", action: {vm.disconnectCurrentDevice()})
                        .padding()
                        .buttonStyle(.borderedProminent)
                        .disabled(!isTvConnected)
                }
            }
            .padding()
            .navigationTitle("Actions")
        }
        .tabItem{Label("Action", systemImage: "playpause.circle")}
    }
}

struct ActionView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(vm: AppViewModel.mock)
        
    }
}
