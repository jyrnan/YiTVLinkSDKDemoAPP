//
//  ActionView.swift
//  YiTVLinkTestApp
//
//  Created by jyrnan on 2023/1/12.
//

import SwiftUI
import YiTVLinkSDK

struct ActionView: View {
  @ObservedObject var vm: AppViewModel
  @State var rcKey: RCKeyPacket.Key = .rck_home
  var isTvConnected: Bool { vm.hasConnectedToDevice != nil }
    
  var body: some View {
    NavigationView {
      VStack {
        ScrollView {
          VStack {
            HStack {
              Image(systemName: isTvConnected ? "4k.tv.fill" : "4k.tv")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .imageScale(.large)
                .foregroundColor(isTvConnected ? .accentColor : .gray)
                .frame(width: 48, height: 48)
                        
              Text("\(vm.hasConnectedToDevice?.devName ?? "没有电视连接")")
                .padding()
            }
            Button(role: .destructive, action: {vm.disconnectCurrentDevice()}, label: {Text("断开当前设备连接")})
              .padding()
              .disabled(!isTvConnected)
              .buttonStyle(.borderedProminent)
            
          }
                  
          HStack {
            Button(action: { vm.testSendTcpData() }, label: { Text("发送TCP数据").lineLimit(1) })
              .padding()
              .disabled(!isTvConnected)
              .buttonStyle(.borderedProminent)
                
            Button(action: { vm.testSendGenneralCommand() }, label: { Text("发送UDP命令").lineLimit(1) })
              .padding()
              .disabled(!isTvConnected)
              .buttonStyle(.borderedProminent)
          }
          
          // MARK: - 遥控按键
          VStack {
            Button(action: {
              vm.sendRCKey(rcKey: RCKeyPacket(key: .rck_up))
            }, label: { Text("遥控上键").lineLimit(1) })
              .padding()
              .disabled(!isTvConnected)
              .buttonStyle(.borderedProminent)
            
            HStack {
              Button(action: { vm.sendRCKey(rcKey: RCKeyPacket(key: .rck_left)) }, label: { Text("遥控左键").lineLimit(1) })
                .padding()
                .disabled(!isTvConnected)
                .buttonStyle(.borderedProminent)
                  
              Button(action: { vm.sendRCKey(rcKey: RCKeyPacket(key: .rck_right)) }, label: { Text("遥控右键").lineLimit(1) })
                .padding()
                .disabled(!isTvConnected)
                .buttonStyle(.borderedProminent)
            }
            
            Button(action: {vm.sendRCKey(rcKey: RCKeyPacket(key: .rck_down))  }, label: { Text("遥控下键").lineLimit(1) })
              .padding()
              .disabled(!isTvConnected)
              .buttonStyle(.borderedProminent)
          }
          
          HStack{
            Picker("RemoteKey", selection: $rcKey) {
              ForEach(RCKeyPacket.Key.allCases, id: \.self) { rcKey in
                let keyString = String(describing: rcKey)
                Text(keyString)
                  .tag(rcKey)
              }
              
            }
            Button(action: {
              vm.sendRCKey(rcKey: RCKeyPacket(key: rcKey))
            }, label: { Text("发送").lineLimit(1) })
              .padding()
//              .disabled(!isTvConnected)
              .buttonStyle(.borderedProminent)
          }
          
          VStack {
            Button(action: {
              vm.sendMouseEvent(event: MouseEventPacket(motion: .move, x: 0, y: -5, w: 0))
            }, label: { Text("空鼠上键").lineLimit(1) })
              .padding()
              .disabled(!isTvConnected)
              .buttonStyle(.borderedProminent)
            
            HStack {
              Button(action: {
                vm.sendMouseEvent(event: MouseEventPacket(motion: .move, x: -5, y: 0, w: 0))
              }, label: { Text("空鼠左键").lineLimit(1) })
                .padding()
                .disabled(!isTvConnected)
                .buttonStyle(.borderedProminent)
                  
              Button(action: { vm.sendMouseEvent(event: MouseEventPacket(motion: .move, x: 5, y: 0, w: 0)) }, label: { Text("空鼠右键").lineLimit(1) })
                .padding()
                .disabled(!isTvConnected)
                .buttonStyle(.borderedProminent)
            }
            
            Button(action: {vm.sendMouseEvent(event: MouseEventPacket(motion: .move, x: 0, y: 5, w: 0)) }, label: { Text("空鼠下键").lineLimit(1) })
              .padding()
              .disabled(!isTvConnected)
              .buttonStyle(.borderedProminent)
          }
          
        }
        .navigationTitle("Actions")
        
        Text(vm.logs.last?.content ?? "No log").padding()
      }
    }
    .tabItem { Label("Action", systemImage: "play.fill") }
  }
}

struct ActionView_Previews: PreviewProvider {
  static var previews: some View {
    ActionView(vm: AppViewModel.mock)
  }
}
