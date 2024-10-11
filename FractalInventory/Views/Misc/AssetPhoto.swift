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
        GeometryReader { geometry in
            VStack {
                ScrollView {
                    HStack {
                        Button("Clear") {
                            isNewImageSelected = false
                            imageSelected = UIImage(systemName: "photo")!
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(8)
                        .background(Color.red.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(6)
                        .shadow(radius: 2)
                        .font(.system(size: 14))
                        Spacer()
                        Button("Save Image") {
                            showAssetPhoto = false
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(8)
                        .background(Color.green.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(6)
                        .shadow(radius: 2)
                        .font(.system(size: 14))
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
                        .frame(width: geometry.size.width / 3)
                        Spacer()
                        Button(action: { showImagePicker.toggle() } ) {
                            Text("Get Photo")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.vertical, 6) // Reduce el padding vertical para hacerlo más pequeño
                                .padding(.horizontal, 12) // Reduce el padding horizontal para ajustar el ancho
                                .background(Color.blue)
                                .cornerRadius(8)
                                .shadow(color: Color.gray.opacity(0.5), radius: 3, x: 0, y: 2)
                        }
                        .sheet(isPresented: $showImagePicker) {
                            ImagePicker(imageSelected: $imageSelected, sourceType: $sourceType, isNewImageSelected: $isNewImageSelected)
                        }
                    }
                    .padding()
                    Spacer()
                    AssetImage(showImage: $showImage, imageSelected: $imageSelected, isNewImageSelected: $isNewImageSelected)
                        .frame(width: min(geometry.size.width - 40, 300),height: min(geometry.size.height * 0.4, 300))
                        .padding()
                    Spacer()
                }
            }
        }}
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
                .frame(maxWidth: UIScreen.main.bounds.width * 0.8, maxHeight: UIScreen.main.bounds.height * 0.5)
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


