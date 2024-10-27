//
//  LogView.swift
//  YiTVLinkTestApp
//
//  Created by jyrnan on 2023/1/12.
//

import SwiftUI

struct LogView: View {
    @ObservedObject var vm: AppViewModel
    
    var body: some View {
        VStack{
            Divider()
            TextEditor(text: $vm.logString)
                .font(.callout)
        }
    }
}

#Preview {
    LogView(vm: AppViewModel.preview)
}
