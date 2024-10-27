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
            VStack {
                List {
                    ForEach(vm.fileURLs, id: \.path) { file in
                        NavigationLink {
                            FileView(url: file)
                        } label: {
                            Text(file.lastPathComponent)
                               
                        }
                        .swipeActions(edge: .leading) {
                            Button(action: {
                                vm.shareFile(fileURL: file)

                            }, label: { Image(systemName: "square.and.arrow.up") })
                            
//                            Button(action: {
//                                vm.sharePicture(fileURL: file)
//
//                            }, label: { Image(systemName: "photo") })
//
//                            Button(action: {
//                                vm.shareMovie(fileURL: file)
//                            }, label: { Image(systemName: "play.fill") })
//
//                            Button(action: {
//                                vm.shareAPK(fileURL: file)
//                            }, label: { Image(systemName: "applescript") })
                        }
                    }
                    .onDelete(perform: vm.deleteFile)
                }

                LogView(vm: vm)
            }

            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        vm.stopLocalServer()
                    }, label: {
                        Image(systemName: "stop.fill")
                    })
                    .disabled(!vm.isSharing)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        vm.startLocalServer()
                    }, label: {
                        Image(systemName: "play.fill")
                    })
                    .disabled(vm.isSharing)
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
        }
        .tabItem { Label("File", systemImage: "square.and.arrow.up.fill") }
        .sheet(isPresented: $isShowDocumentPickerView) {
            DocumentPickerView(vm: vm, isShowDocumentPickerView: $isShowDocumentPickerView)
        }
        .task {
            vm.startLocalServer()
        }
    }
}

#Preview {
    FileShareView(vm: AppViewModel.preview)
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
