//
//  ImagePicker.swift
//  FractalInventory
//
//  Created by Miguel Cruz on 24/10/21.
//

import Foundation
import SwiftUI

struct ImagePicker: UIViewControllerRepresentable {
  
  @Environment(\.presentationMode) var presentationMode
  @Binding var imageSelected: UIImage
  @Binding var sourceType: UIImagePickerController.SourceType
  @Binding var isNewImageSelected: Bool
  
  func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
    let picker = UIImagePickerController()
    picker.delegate = context.coordinator
    picker.sourceType = sourceType
    
    return picker
  }
  
  func updateUIViewController(_ uiViewController: UIViewControllerType, context: UIViewControllerRepresentableContext<ImagePicker>) {}
  
  func makeCoordinator() -> ImagePickerCoordinator {
    return ImagePickerCoordinator(parent: self)
  }
  
  class ImagePickerCoordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    let parent: ImagePicker
    
    init(parent: ImagePicker) {
      self.parent = parent
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
      if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
        // select the image for our app
        parent.imageSelected = image
        // dismiss the screen
        parent.isNewImageSelected = true
        parent.presentationMode.wrappedValue.dismiss()
      }
    }
  }
  
}
