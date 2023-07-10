//
//  DocumentPickerView.swift
//  YiTVLinkSDKDemoAPP
//
//  Created by jyrnan on 2023/3/29.
//

import SwiftUI
import YiTVLinkSDK
import UniformTypeIdentifiers

extension UTType {
  public static var apk: UTType {
    UTType(importedAs: "com.app.apk")
  }
}

struct DocumentPickerView: UIViewControllerRepresentable {
  @ObservedObject var vm: AppViewModel
  @Binding var isShowDocumentPickerView: Bool

  func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
    /// 添加.data类型就可以支持所有的文件类型？！
    let controller = UIDocumentPickerViewController(forOpeningContentTypes: [.text, .pdf, .jpeg, .png, .mpeg4Movie, .data])
    controller.allowsMultipleSelection = true
    controller.shouldShowFileExtensions = true
    controller.delegate = context.coordinator
    return controller
  }
  
  func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
    
  }
  
  func makeCoordinator() -> DocumentPickerCoordinator {
    return DocumentPickerCoordinator(isShowDocumentPickerView: $isShowDocumentPickerView, vm: vm)
  }
    
}

class DocumentPickerCoordinator: NSObject, UIDocumentPickerDelegate {
  @ObservedObject var vm: AppViewModel
  @Binding var isShowDocumentPickerView: Bool
  
  init(isShowDocumentPickerView: Binding<Bool>, vm: AppViewModel) {
    self._isShowDocumentPickerView = isShowDocumentPickerView
    self.vm = vm
  }
  
  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    guard let url = urls.first else {return}
    
    print(urls)
    let localURLs = urls.compactMap{copyDocumentsToLocalDirectory(pickedURL: $0)}
    print(localURLs)
    vm.fileURLs.append(contentsOf: localURLs)
  }
  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    isShowDocumentPickerView = false
  }
}

struct DocumentPickerView_Previews: PreviewProvider {
    static var previews: some View {
      DocumentPickerView(vm: AppViewModel.mock, isShowDocumentPickerView: .constant(true))
    }
}

extension DocumentPickerCoordinator {
  func copyDocumentsToLocalDirectory(pickedURL: URL) -> URL? {
    guard let rootUrl = try? URL.serverRoot() else {
              return nil
          }
          do {
              var destinationDocumentsURL: URL = rootUrl
              
              destinationDocumentsURL = destinationDocumentsURL
                  .appendingPathComponent(pickedURL.lastPathComponent)
              var isDir: ObjCBool = false
              if FileManager.default.fileExists(atPath: destinationDocumentsURL.path, isDirectory: &isDir) {
                  try FileManager.default.removeItem(at: destinationDocumentsURL)
              }
              guard pickedURL.startAccessingSecurityScopedResource() else {print("problem");return nil}
              defer {
                  pickedURL.stopAccessingSecurityScopedResource()
              }
              try FileManager.default.copyItem(at: pickedURL, to: destinationDocumentsURL)
              print(FileManager.default.fileExists(atPath: destinationDocumentsURL.path))
              return destinationDocumentsURL
          } catch  {
              print(error)
          }
          return nil
      }
}
