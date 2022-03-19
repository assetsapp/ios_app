//
//  AssetPhoto.swift
//  FractalInventory
//
//  Created by Miguel Cruz on 24/10/21.
//

import SwiftUI

struct AssetPhoto: View {
    @State var photoType: Int = 0
    @State var showImage: Bool = false
    @State var showImagePicker: Bool = false
    @State var sourceType: UIImagePickerController.SourceType = .camera
    @Binding var imageSelected: UIImage
    @Binding var isNewImageSelected: Bool
    @Binding var showAssetPhoto: Bool

    var body: some View {
        VStack {
            HStack {
                Button("Clear") {
                    isNewImageSelected = false
                    imageSelected = UIImage(systemName: "photo")!
                }
                Spacer()
                Button("Close") {
                    showAssetPhoto = false
                }
            }
            .padding()
            HStack {
                Picker("Mode", selection: $photoType) {
                    Text("Camera").tag(0)
                    Text("Library").tag(1)
                }
                .onChange(of: photoType, perform: { value in
                    sourceType = value == 0 ? .camera : .photoLibrary
                })
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 130)
                Spacer()
                Button(action: { showImagePicker.toggle() } ) {
                    Text("Get Photo")
                }
                .sheet(isPresented: $showImagePicker) {
                    ImagePicker(imageSelected: $imageSelected, sourceType: $sourceType, isNewImageSelected: $isNewImageSelected)
                }
            }
            .padding()
            
            AssetImage(showImage: $showImage, imageSelected: $imageSelected, isNewImageSelected: $isNewImageSelected)
            
            Spacer()
        }
    }
}


struct AssetImage: View {
    @Binding var showImage: Bool
    @Binding var imageSelected: UIImage
    @Binding var isNewImageSelected: Bool
    
    var body: some View {
        VStack {
            Image(uiImage: imageSelected)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .cornerRadius(15)
                .frame(width: UIScreen.main.bounds.width - 20, height: UIScreen.main.bounds.height / 2)
                .shadow(color: Color.gray, radius: 20, x: 20, y: 20)
                .padding()
        }
    }
}

struct AssetPhoto_Previews: PreviewProvider {
    @State static var imageSelected: UIImage = UIImage(systemName: "photo")!
    
    static var previews: some View {
        AssetPhoto(imageSelected: $imageSelected, isNewImageSelected: .constant(true), showAssetPhoto: .constant(true))
    }
}
