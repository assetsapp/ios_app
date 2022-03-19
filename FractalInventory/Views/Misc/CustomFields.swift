//
//  CustomFields.swift
//  FractalInventory
//
//  Created by Miguel Cruz on 08/12/21.
//

import SwiftUI
import Foundation

struct CustomFields: View {
    @Binding var customFields: responseObj
    @Binding var customFieldsValues: [String]
    @Binding var showCustomFields: Bool
    @State var tabIndex: Int = 0
    @State var showWebBrowser: Bool = false
    @State var showAssetPhoto: Bool = false
    @State var fromModule: String = "references"
    @State var imageSelected: UIImage = UIImage(systemName: "photo")!
    @State var isNewImageSelected: Bool = false
    @Binding var customFieldsImages: [AssetPhoto]
    @Binding var customFieldsImagesData: [ImageCustomField]
    @ObservedObject var webViewStateModel: WebViewStateModel = WebViewStateModel()
    @AppStorage(Settings.apiHostKey) var apiHost = "http://159.203.41.87:3001"
    @State var fieldSelectedIndex = -1
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button("Close") {
                    showCustomFields.toggle()
                }
            }.padding(.trailing)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(Array(customFields.tabs.enumerated()), id: \.offset) { index, tab in
                        Button(action: { tabIndex = index }) {
                            VStack {
                                Text(tab.tabName.uppercased())
                                    .foregroundColor(Color.black.opacity(0.6))
                                    .fontWeight(.bold)
                                    .frame(minWidth: 0, maxWidth: .infinity)
                                Capsule()
                                    .fill(tabIndex == index ? Color.orange : Color.white.opacity(0))
                                    .frame(minWidth: 0, maxWidth: .infinity)
                                    .frame(height: 3)
                                    .padding(.top, -5)
                            }
                            .padding(.top)
                            .padding(.horizontal)
                        }
                    }
                }
            }
            
            Spacer()
            
            ZStack {
                ForEach(Array(customFields.tabs.enumerated()), id: \.offset) { index, tab in
                    
                        VStack(alignment: .leading) {
                            ScrollView(.vertical, showsIndicators: false) {
                            ForEach(Array(getTabCustomFields(customFields: customFields.customFields, tabId: tab.tabId).enumerated()), id: \.offset) { cfIndex, customField in
                                
                                if ["singleLine", "multiLine"].contains(customField.content) {
                                    HStack {
                                        Text(customField.fieldName)
                                            .fontWeight(.semibold)
                                            .padding(.top, 4)
                                        Spacer()
                                    }
                                    TextField("Insert value...", text: $customFieldsValues[customField.fieldIndex])
                                        .foregroundColor(Color.black.opacity(0.6))
                                        .padding(.top, -3)
                                } else if ["fileUpload"].contains(customField.content) && fromModule == "assets" {
                                    HStack {
                                        Text(customField.fieldName)
                                            .fontWeight(.semibold)
                                            .padding(.top, 4)
                                        Spacer()
                                    }
                                    Button(action: {
                                        webViewStateModel.pageTitle = getFileUrl(fileId: customField.fileId, fileExt: customField.fileExt)
                                        showWebBrowser.toggle()
                                    }) {
                                        Text(customField.fileName)
                                            .foregroundColor(Color.blue)
                                            .underline()
                                    }
                                } else if ["imageUpload"].contains(customField.content) && fromModule == "assets" {
                                    
                                    HStack {
                                        Text(customField.fieldName)
                                            .fontWeight(.semibold)
                                            .padding(.top, 4)
                                        
                                        Spacer()
                                        
                                        Button("(Update)") {
                                            fieldSelectedIndex = customField.fieldIndex
                                        }
                                    }
                                    if customField.fileName != "" && customField.initialValue != "" && !customFieldsImagesData[customField.fieldIndex].isNewImage {
                                        Button(action: {
                                            webViewStateModel.pageTitle = getFileUrl(fileId: customField.fileName, fileExt: customField.initialValue)
                                            showWebBrowser.toggle()
                                        }) {
                                            LoadImage(fileExt: customField.initialValue, id: customField.fileName, folder: "customFields", applyFrame: false)
                                                .frame(width: 200)
                                        }
                                    } else {
                                        if customFieldsImagesData[customField.fieldIndex].isNewImage {
                                            Image(uiImage: customFieldsImagesData[customField.fieldIndex].image)
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 200)
                                        } else {
                                            LoadImage(fileExt: customField.initialValue, id: customField.fileName, folder: "customFields", applyFrame: false)
                                                .frame(width: 200)
                                        }
                                    }
                                }
                            }
                            Spacer()
                        }
                        .onChange(of: fieldSelectedIndex, perform: { value in
                            if fieldSelectedIndex > -1 {
                                showAssetPhoto.toggle()
                            }
                        })
                        .sheet(isPresented: $showWebBrowser) {
                            WKView(webViewStateModel: webViewStateModel)
                        }
                        .sheet(isPresented: $showAssetPhoto, onDismiss: { fieldSelectedIndex = -1 }) {
                            if fieldSelectedIndex > -1 {
                                AssetPhoto(imageSelected: $customFieldsImagesData[fieldSelectedIndex].image, isNewImageSelected: $customFieldsImagesData[fieldSelectedIndex].isNewImage, showAssetPhoto: $showAssetPhoto)
                            }
                        }
                        .padding(.top, 10)
                        .padding(.horizontal, 15)
                        .opacity(tabIndex == index ? 1 : 0)
                    }
                }
            }
        }.padding()
    }
    
    func getTabCustomFields(customFields: [customField], tabId: String) -> [customField] {
        print("CF > CF> > >")
        print("didTriggerKeyChangedState >>> \(customFields)")
        print("tabId 0 >>> \(tabId)")
        return customFields.filter { $0.tabId == tabId }
    }
    
    func getFileUrl(fileId: String, fileExt: String) -> String {
        return "\(apiHost)/uploads/customFields/\(fileId).\(fileExt)"
    }
}

struct ImageCustomField {
    let id: String
    var image: UIImage
    let index: Int
    var isNewImage: Bool
    var isModalOpen: Bool
}

struct CustomFields_Previews: PreviewProvider {
    @State static var resp = responseObj()
    @State static var customFieldsImages: [AssetPhoto] = []
    @State static var customFieldsImagesData: [ImageCustomField] = []

    static var previews: some View {
        CustomFields(customFields: $resp, customFieldsValues: .constant([]), showCustomFields: .constant(true), customFieldsImages: $customFieldsImages, customFieldsImagesData: $customFieldsImagesData)
    }
}
