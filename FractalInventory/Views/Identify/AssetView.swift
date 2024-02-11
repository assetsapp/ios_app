//
//  AssetView.swift
//  FractalInventory
//
//  Created by Miguel Cruz on 30/11/21.
//

import SwiftUI

struct AssetView: View {
    @ObservedObject var cslvalues: CSLValues
    @State var asset: RealAssetModelWithLocation
    @State var imageSelected: UIImage = UIImage(systemName: "photo")!
    @State var isNewImageSelected: Bool = false
    @State var customFields: responseObj = responseObj()
    @State var customFieldsValues: [String] = []
    @State var barcodeMode: Bool = false
    @State var serialNumber: String = ""
    @State var EPC: String = ""
    @State var showAssetPhoto: Bool = true
    @State var originalEPC: String = ""
    @State var inventoryButton: String = "Start"
    @State var isInventoryStarted: Bool = false
    @State var updateEPC: Bool = false
    @State var showUpdateModal: Bool = false
    @State var showDuplicatedEPCModal: Bool = false
    @State var customFieldsImages: [AssetPhoto] = []
    @State var customFieldsImagesData: [ImageCustomField] = []
    @StateObject var zebraSingleton = ZebraSingleton.shared
    let workModeManager = WorkModeManager()
    
    var body: some View {
        VStack {
            ScrollView {
                AssetInfo(asset: $asset, showAssetPhoto: $showAssetPhoto)
                
                AssetActions(asset: $asset, imageSelected: $imageSelected, isNewImageSelected: $isNewImageSelected, customFields: $customFields, customFieldsValues: $customFieldsValues, customFieldsImages: $customFieldsImages, customFieldsImagesData: $customFieldsImagesData)
                
                AssetOtherFields(cslvalues: cslvalues, asset: $asset, serialNumber: $serialNumber, EPC: $EPC, barcodeMode: $barcodeMode, updateEPC: $updateEPC, inventoryButton: $inventoryButton, isInventoryStarted: $isInventoryStarted, _onInvetory: onInventory)
                
                Spacer()
            }
        }
        .alert(isPresented: $showUpdateModal, content: {
            Alert(
                title: Text("Asset successfully updated"),
                dismissButton: .cancel(Text("OK"), action: { showAssetPhoto = true })
            )
        })
        .navigationBarItems(trailing:
                                HStack {
            Button("Update") { validateEPC() }
                .alert(isPresented: $showDuplicatedEPCModal, content: {
                    Alert(
                        title: Text("New EPC already exists, please read a different one"),
                        dismissButton: .cancel(Text("OK"), action: {})
                    )
                })
        }
        )
        .onAppear {
            serialNumber = asset.serial ?? ""
            EPC = asset.EPC ?? ""
            originalEPC = asset.EPC ?? ""
            
            switch workModeManager.workMode {
            case .online:
                cslvalues.isLoading = true
                ApiReferences().getCustomFields(id: asset._id, collection: "assets") { customField in
                    self.customFields = customField
                    
                    for field in customField.customFields {
                        customFieldsValues.append(field.initialValue)
                        
                        @State var image = UIImage(systemName: "photo")!
                        @State var isNewImage = false
                        @State var isModalOpen = false
                        let imageObj = ImageCustomField(id: field.fileId, image: image, index: field.fieldIndex, isNewImage: isNewImage, isModalOpen: isModalOpen)
                        customFieldsImagesData.append(imageObj)
                        
                    }
                    cslvalues.isLoading = false
                }
            case .offline:
                break 
            }
            zebraSingleton.startInventory(power: 270)
            zebraSingleton.onTagAdded = { tag in
                print("ZebraTag: \(tag)")
                self.cslvalues.addEpc(reading: tag)
            }
        }
        .onChange(of: cslvalues.isTriggerApplied) { isTriggerApplied in
            if (!isInventoryStarted) {
                onInventory()
            }
        }
        .environmentObject(zebraSingleton)
    }
    
    func onInventory() {
        if inventoryButton == "Start" {
            if !CSLHelper.isDeviceConnected() {
                cslvalues.showNonConnected = true
                isInventoryStarted = false
                return
            }
            inventoryButton = "Stop"
            if barcodeMode {
                CSLHelper.onStartBarcodeInventory()
            } else {
                if updateEPC || cslvalues.isGeiger {
                    CSLHelper.onClear(cslvalues: cslvalues)
                    CSLHelper.onStartRFIDInventory()
                }
            }
        } else {
            if barcodeMode {
                CSLHelper.onStopBarcodeInventory()
                inventoryButton = "Start"
            } else {
                if CSLHelper.onStopRFIDInventory() {
                    CSLRfidAppEngine.shared().reader.setPowerMode(true)
                    inventoryButton = "Start"
                } else {
                    inventoryButton = "Stop"
                }
            }
        }
    }
    
    func onUpdate() {
        let params: [String: Any] = [
            "serial": serialNumber,
            "EPC": EPC
        ]
        let modifiedCustomFields = filterModifiedCustomFields()
        
        if !isNewImageSelected {
            cslvalues.isLoading = true
            ApiAssets().updateAsset(assetId: asset._id, params: params) { result in
                if modifiedCustomFields.count > 0 {
                    ApiReferences().updateCustomFields(id: asset._id, updatedCustomFields: modifiedCustomFields) {
                        showUpdateModal.toggle()
                    }
                } else {
                    showUpdateModal.toggle()
                }
                cslvalues.isLoading = false
            }
        } else {
            showAssetPhoto = false
            cslvalues.isLoading = true
            ApiFile().postImage(image: imageSelected, _id: asset._id) { uploadFile in
                let fileparams: [String: Any] = [
                    "fileExt": "jpeg"
                ]
                let fileassetsparams = params.merging(fileparams) { (_, new) in new }
                ApiAssets().updateAsset(assetId: asset._id, params: fileassetsparams) { result in
                    if modifiedCustomFields.count > 0 {
                        ApiReferences().updateCustomFields(id: asset._id, updatedCustomFields: modifiedCustomFields) {
                            showUpdateModal.toggle()
                        }
                    } else {
                        showUpdateModal.toggle()
                    }
                }
                cslvalues.isLoading = false
            }
        }
    }
    
    func onUpdateOffline() {
        cslvalues.isLoading = true
        let imageData = isNewImageSelected ? imageSelected.jpegData(compressionQuality: 0.2) : nil
        DataManager().update(asset: asset._id, epc: EPC, serialNumber: serialNumber, image: imageData) { result in
            switch result {
            case .success(_ ):
                showUpdateModal.toggle()
            case .failure(let error):
                print("Error: ", error.localizedDescription)
            }
            cslvalues.isLoading = false
        }
    }
    
    func validateEPC() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        if EPC != originalEPC {
            switch workModeManager.workMode {
            case .online:
                validateEPCOnline()
            case .offline:
                validateEPCOffline()
            }
        } else {
            switch workModeManager.workMode {
            case .online:
                onUpdate()
            case .offline:
                onUpdateOffline()
            }
        }
    }
    
    private func validateEPCOnline() {
        let params: [String: Any] = ["fieldValues": [EPC]]
        ApiAssets().validateEPCS(params: params) { _existingEPCS in
            if _existingEPCS.count > 0 {
                showDuplicatedEPCModal.toggle()
            } else {
                onUpdate()
            }
        }
    }
    
    private func validateEPCOffline() {
        DataManager().getAsset(EPC: EPC) { result in
            var isDuplicated = false
            switch result {
            case .success(let data):
                isDuplicated = data != nil
            case .failure(let error):
                print("Error: ", error.localizedDescription)
            }
            
            if isDuplicated {
                showDuplicatedEPCModal.toggle()
            } else {
                onUpdateOffline()
            }
        }
    }
    
    func filterModifiedCustomFields() -> [String] {
        var modifiedCustomFields: [String] = []
        for customField in customFields.customFields {
            let updatedValue = customFieldsValues[customField.fieldIndex]
            if customField.initialValue != updatedValue {
                let updatedField = "\(customField.tabId)||\(customField.columnPosition)||\(customField.fieldId)||initialValue||\(updatedValue)"
                modifiedCustomFields.append(updatedField)
            }
        }
        for customImage in customFieldsImagesData {
            if customImage.isNewImage {
                let targetIndex = customImage.index
                let foundCustomField = customFields.customFields[targetIndex]
                let newFileName = foundCustomField.fileName != "" ? foundCustomField.fileName : UUID().uuidString
                let updatedFileName = "\(foundCustomField.tabId)||\(foundCustomField.columnPosition)||\(foundCustomField.fieldId)||fileName||\(newFileName)"
                let updatedFileExt = "\(foundCustomField.tabId)||\(foundCustomField.columnPosition)||\(foundCustomField.fieldId)||initialValue||jpeg"
                modifiedCustomFields.append(updatedFileName)
                modifiedCustomFields.append(updatedFileExt)
                ApiFile().postImage(image: customImage.image, _id: newFileName, folder: "customFields") { _ in }
            }
        }
        
        return modifiedCustomFields
    }
}

struct AssetInfo: View {
    @Binding var asset: RealAssetModelWithLocation
    @Binding var showAssetPhoto: Bool
    @State var showAssetSheet: Bool = false
    
    var body: some View {
        HStack {
            VStack {
                Text(asset.name)
                    .font(.title)
                    .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                    .fixedSize(horizontal: false, vertical: /*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/)
                    .padding(.top)
                Text(asset.brand ?? "")
                    .foregroundColor(.secondary)
                    .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                    .fixedSize(horizontal: false, vertical: /*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/)
                Text(asset.model ?? "")
                    .foregroundColor(.secondary)
                    .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                    .fixedSize(horizontal: false, vertical: /*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/)
                if showAssetPhoto {
                    if asset.fileExt != "" {
                        Button (action: { showAssetSheet.toggle() }) {
                            LoadImage(fileExt: asset.fileExt ?? "", id: asset._id, folder: "assets", sizeFraction: 4)
                        }
                        .sheet(isPresented: $showAssetSheet) {
                            VStack {
                                HStack {
                                    Spacer()
                                    Button("Close") {
                                        showAssetSheet.toggle()
                                    }
                                }.padding(.trailing)
                                
                                LoadImage(fileExt: asset.fileExt ?? "", id: asset._id, folder: "assets", sizeFraction: 1)
                            }
                        }
                    } else {
                        LoadImage(fileExt: asset.fileExt ?? "", id: asset._id, folder: "assets", sizeFraction: 4)
                    }
                }
            }
        }
    }
}

struct AssetActions: View {
    @Binding var asset: RealAssetModelWithLocation
    @State var showAssetPhoto: Bool = false
    @State var showCustomFields: Bool = false
    @Binding var imageSelected: UIImage
    @Binding var isNewImageSelected: Bool
    @Binding var customFields: responseObj
    @Binding var customFieldsValues: [String]
    @Binding var customFieldsImages: [AssetPhoto]
    @Binding var customFieldsImagesData: [ImageCustomField]
    
    var body: some View {
        HStack {
            Button("Asset Photo") {
                showAssetPhoto.toggle()
            }
            .sheet(isPresented: $showAssetPhoto) {
                AssetPhoto(imageSelected: $imageSelected, isNewImageSelected: $isNewImageSelected, showAssetPhoto: $showAssetPhoto)
            }
            Spacer()
            Button("Custom Fields") {
                showCustomFields.toggle()
            }
            .sheet(isPresented: $showCustomFields) {
                CustomFields(customFields: $customFields, customFieldsValues: $customFieldsValues, showCustomFields: $showCustomFields, fromModule: "assets", customFieldsImages: $customFieldsImages, customFieldsImagesData: $customFieldsImagesData)
            }
        }
        .padding(.trailing, 50)
        .padding(.leading, 50)
        .padding(.top, 5)
    }
}

struct AssetOtherFields: View {
    @ObservedObject var cslvalues: CSLValues
    @Binding var asset: RealAssetModelWithLocation
    @Binding var serialNumber: String
    @Binding var EPC: String
    @Binding var barcodeMode: Bool
    @Binding var updateEPC: Bool
    @State var showGeiger: Bool = false
    @Binding var inventoryButton: String
    @Binding var isInventoryStarted: Bool
    @State var powerLevel: Double = 10
    @State var maxPowerLevel: Double = 30
    @State var geigerLevel: Double = 0
    @EnvironmentObject var zebraSingleton: ZebraSingleton
    var _onInvetory: () -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Asset location:")
                .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                .foregroundColor(.secondary)
                .padding(.top)
            Text(asset.locationPath ?? "")
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: /*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/)
                .padding(.top, 2)
            Text("Serial Number:")
                .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                .foregroundColor(.secondary)
                .padding(.top)
            TextField("Insert Serial Number", text: $serialNumber, onEditingChanged: { (editingChanged) in
                if editingChanged {
                    cslvalues.isSingleBarcode = true
                    CSLRfidAppEngine.shared().soundAlert(kSystemSoundID_Vibrate)
                    CSLRfidAppEngine.shared().isBarcodeMode = true
                    barcodeMode = true
                } else {
                    cslvalues.isSingleBarcode = false
                    CSLRfidAppEngine.shared().soundAlert(kSystemSoundID_Vibrate)
                    CSLRfidAppEngine.shared().isBarcodeMode = false
                    barcodeMode = false
                    cslvalues.singleBarcode = ""
                }
            })
            .padding(.top, -3)
            .padding(.bottom)
            
            VStack(alignment: .leading) {
                Button("Geiger") {
                    showGeiger.toggle()
                    cslvalues.isGeiger = true
                    cslvalues.geigerEPC = EPC
                    cslvalues.geigerValue = 0
                    geigerLevel = 0
                }
                .sheet(isPresented: $showGeiger, onDismiss: {
                    cslvalues.isGeiger = false
                    cslvalues.geigerEPC = ""
                    cslvalues.geigerValue = 0
                    geigerLevel = 0
                }) {
                    VStack {
                        HStack {
                            Spacer()
                            
                            Button("Close") {
                                cslvalues.isGeiger = false
                                cslvalues.geigerEPC = ""
                                cslvalues.geigerValue = 0
                                geigerLevel = 0
                                showGeiger.toggle()
                            }
                        }.padding()
                        
                        HStack {
                            Text("Geiger")
                                .fontWeight(.bold)
                                .font(.title)
                                .foregroundColor(.primary)
                                .padding()
                        }
                        
                        Text("Looking for this EPC:")
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .padding(.top)
                        Text(EPC)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .padding()
                        
                        VStack {
                            Slider(value: $powerLevel, in: 0...maxPowerLevel, step: 1)
                                .accentColor(Color.green)
                                .onChange(of: powerLevel, perform: { power in
                                    Utils.updateAntennaPower(power: power)
                                })
                                .disabled(inventoryButton == "Stop")
                            Text("Power Level: \(powerLevel, specifier: "%.0f")")
                        }
                        .padding()
                        .padding(.bottom)
                        
                        VStack {
                            Slider(value: $geigerLevel, in: 0...100, step: 1)
                                .padding()
                                .accentColor(Color.blue)
                                .onChange(of: cslvalues.geigerValue, perform: { newValue in
                                    geigerLevel = Double(newValue)
                                    if newValue > 100 {
                                        CSLRfidAppEngine.shared().soundAlert(1005)
                                    }
                                })
                                .disabled(true)
                            Text("Geiger Intensity: \(geigerLevel, specifier: "%.0f")")
                                .fontWeight(.bold)
                                .font(.title3)
                        }
                        .padding()
                        .frame(width: UIScreen.main.bounds.width - 40)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        
                        Spacer()
                    }
                }
                HStack {
                    Toggle("Update EPC", isOn: $updateEPC)
                        .toggleStyle(SwitchToggleStyle(tint: .orange))
                        .frame(width: 150)
                    Spacer()
                    Toggle("\(inventoryButton) RFID:", isOn: $isInventoryStarted)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                        .onChange(of: isInventoryStarted, perform: { scan in
                            _onInvetory()
                        })
                        .frame(width: 150)
                        .disabled(cslvalues.isTriggerApplied || !updateEPC)
                }
                Text("EPC:")
                    .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                    .foregroundColor(.secondary)
                Text(EPC)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .padding(.top, 1)
                    .onChange(of: cslvalues.readings.count) { _ in
                        if (cslvalues.readings.count > 0 && !cslvalues.isGeiger) {
                            EPC = cslvalues.readings[0].epc
                        }
                    }
                VStack {
                    Slider(value: $powerLevel, in: 0...maxPowerLevel, step: 1)
                        .accentColor(Color.green)
                        .onChange(of: powerLevel, perform: { power in
                            Utils.updateAntennaPower(power: power)
                        })
                        .disabled(inventoryButton == "Stop")
                    Text("Power Level: \(powerLevel, specifier: "%.0f")")
                    Button(action: {
                        zebraSingleton.restartInventory(power: Int16(powerLevel))
                    }) {
                        Text("Update Power")
                    }
                }
                .padding(.vertical)
            }
            .padding()
            .frame(width: UIScreen.main.bounds.width - 40)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .onChange(of: cslvalues.singleBarcode) { barcode in
            serialNumber += barcode
        }
        .onAppear {
            maxPowerLevel = zebraSingleton.getMaxPower()
        }
        .padding(.horizontal, 40)
    }
}

struct AssetView_Previews: PreviewProvider {
    static var _asset = RealAssetModelWithLocation(_id: "id", brand: "brand", model: "model", name: "name", EPC: "EPC-content", serial: "serial", locationPath: "locPath", status: "st")
    static var sn = ""
    static var epc = ""
    static var previews: some View {
        AssetView(cslvalues: CSLValues(), asset: _asset, customFields: responseObj(), serialNumber: sn, EPC: epc)
    }
}
