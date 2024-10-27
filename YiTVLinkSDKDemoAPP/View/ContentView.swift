//
//  ContentView.swift
//  YiTVLinkSDKDemoAPP
//
//  Created by jyrnan on 2024/7/8.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var vm: AppViewModel
    
    var body: some View {
        TabView {
            DeviceView(vm: vm)
            FileShareView(vm: vm)
            
        }
    }
}

#Preview {
    ContentView(vm: .preview)
}
