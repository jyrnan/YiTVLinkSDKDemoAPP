//
//  FileShareView.swift
//  YiTVLinkSDKDemoAPP
//
//  Created by jyrnan on 2023/3/28.
//

import SwiftUI
import YiTVLinkSDK

struct FileShareView: View {
  @ObservedObject var vm: AppViewModel

  @State var isShowDocumentPickerView: Bool = false

  var body: some View {
    NavigationView {
      VStack{
        List {
          ForEach(vm.fileURLs, id: \.path) { file in
            NavigationLink {
              FileView(url: file)
            } label: {
              Text(file.lastPathComponent)
            }.swipeActions(edge: .leading) {
              Button(action: {
                
                vm.sharePicture(fileURL: file)

              }, label: { Image(systemName: "square.and.arrow.up") })
              
              Button(action: {
                vm.shareMovie(fileURL: file)
              }, label: { Image(systemName: "play.fill") })
              
              Button(action: {
                vm.shareAPK(fileURL: file)
              }, label: { Image(systemName: "applescript") })
            }
          }
          .onDelete(perform: vm.deleteFile)
        }
        .toolbar {
          ToolbarItem(placement: .bottomBar) {
  //            Text(ProcessInfo().hostName + ":\(vm.netService.fileServer.port)")
          }
          ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: {
              vm.netService.startFileSharing()
//              vm.isSharing = true
              
            }, label:{
              Image(systemName: "play.rectangle.on.rectangle")
              .foregroundColor(vm.isSharing ? .accentColor : .gray)
            })
              .padding()
          }
          ToolbarItem(placement: .navigationBarTrailing) {
            Button {
              isShowDocumentPickerView = true
            } label: {
              Image(systemName: "plus")
                .padding(0)
            }
          }
        }
        .navigationTitle("FileShare")
        Text(vm.logs.last?.content ?? "No log").padding()
      }
    }
    .tabItem { Label("File", systemImage: "square.and.arrow.up.fill") }
    .sheet(isPresented: $isShowDocumentPickerView) {
      DocumentPickerView(vm: vm, isShowDocumentPickerView: $isShowDocumentPickerView)
    }
  }
}

struct FileServerView_Previews: PreviewProvider {
  static var previews: some View {
    FileShareView(vm: AppViewModel.mock)
  }
}

import QuickLook

struct FileView: UIViewControllerRepresentable {
  let url: URL
  typealias UIViewControllerType = QLPreviewController

  func makeUIViewController(context: Context) -> QLPreviewController {
    let controller = QLPreviewController()
    controller.dataSource = context.coordinator
    controller.delegate = context.coordinator
    return controller
  }

  func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {}

  func makeCoordinator() -> Coordinator {
    return Coordinator(parent: self)
  }

  class Coordinator: NSObject, QLPreviewControllerDataSource, QLPreviewControllerDelegate {
    let parent: FileView

    init(parent: FileView) {
      self.parent = parent
    }

    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
      return 1
    }

    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
      return parent.url as QLPreviewItem
    }

    func previewController(_ controller: QLPreviewController, editingModeFor previewItem: QLPreviewItem) -> QLPreviewItemEditingMode {
      return .disabled
    }
  }
}
