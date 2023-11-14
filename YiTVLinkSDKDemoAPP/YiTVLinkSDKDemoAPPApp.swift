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
    @Environment(\.scenePhase) private var scenePhase
    var body: some Scene {
        WindowGroup {
            ContentView(vm: vm)
        }
        .onChange(of: scenePhase) { phase in
            if phase == .background {
//                vm.netService.stopFileSharing()
            }
        }
    }
}
