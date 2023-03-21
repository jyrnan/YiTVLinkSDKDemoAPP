//
//  YiTVLinkSDKDemoAPPApp.swift
//  YiTVLinkSDKDemoAPP
//
//  Created by jyrnan on 2023/2/14.
//

import SwiftUI
import YiTVLinkSDK


@main
struct YiTVLinkSDKDemoAPPApp: App {
    @StateObject var vm: AppViewModel = AppViewModel.mock
    var body: some Scene {
        WindowGroup {
            ContentView(vm: vm)
        }
    }
}
