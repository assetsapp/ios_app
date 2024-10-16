//
//  TaggingView.swift
//  FractalInventory
//
//  Created by Miguel Cruz on 28/08/21.
//

import SwiftUI

struct cfi {
    var fieldId: String
    @State var fieldValue: String = ""
}

struct TaggingView: View {
    @ObservedObject var cslvalues: CSLValues
    @State var reference: ReferenceModel
    @State var location: LocationModel
    @State private var inventoryButton: String = "Start"
    @State private var barcodeMode: Bool = false
    @State var isInventoryStarted: Bool = false
    @State var customFields: responseObj
    @State var customFieldsValues: [String] = []
    @State var serialNumber: String = ""
    @State var isSingle: Bool = true
    @State var locationPath: String = "Location Path"
    @State var isSaveModalPresent: Bool = false
    @State var isRemoveExistingModalResult: Bool = false
    @State var removedExistingCount: Int = 0
    @State var isSavedAssetsPresent: Bool = false
    @State var isTryingSaveEmptyPresent: Bool = false
    @State var savedAssetsCount: Int = 0
    let workModeManager = WorkModeManager()
    @StateObject var zebraSingleton = ZebraSingleton.shared
    @State private var errorMessage: String = ""
    

    @State var imageSelected: UIImage = UIImage(systemName: "photo")!
    @State var isNewImageSelected: Bool = false
    
    @State var assignedEmployee: EmployeeModel = EmployeeModel(_id: "", name: "", lastName: "", email: "", employee_id: "")
    
    var body: some View {
        VStack {
            if !errorMessage.isEmpty {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.white)
                        .padding(.trailing, 5)
                    
                    Text(errorMessage)
                        .foregroundColor(.white)
                        .font(.headline)
                        .lineLimit(nil)
                        .multilineTextAlignment(.leading)
                }
                .padding()
                .background(Color.red)
                .cornerRadius(8)
                .shadow(color: Color.red.opacity(0.6), radius: 5, x: 0, y: 5)
                .padding(.horizontal, 16)
            }
            ScrollView(.vertical, showsIndicators: false) {
                CardView(cslvalues: cslvalues, reference: $reference, location: $location, isSingle: $isSingle, inventoryButton: $inventoryButton, isInventoryStarted: $isInventoryStarted, barcodeMode: $barcodeMode, customFields: $customFields, _onInvetory: onInventory, validateEPC: validateEPC, customFieldsValues: $customFieldsValues, serialNumber: $serialNumber, locationPath: $locationPath, isRemoveExistingModalResult: $isRemoveExistingModalResult, removedExistingCount: $removedExistingCount, isSavedAssetsPresent: $isSavedAssetsPresent, savedAssetsCount: $savedAssetsCount, imageSelected: $imageSelected, isNewImageSelected: $isNewImageSelected, assignedEmployee: $assignedEmployee)
            }
           
                
        }
        .onAppear {
            if CSLHelper.isDeviceConnected() {
                CSLHelper.onLoadInventory()
                CSLHelper.onClear(cslvalues: cslvalues)
            }
            switch workModeManager.workMode {
            case .online:
                ApiReferences().getCustomFields(id: reference._id, collection: "references") { customField in
                    self.customFields = customField
                    
                    for field in customField.customFields {
                        customFieldsValues.append(field.initialValue)
                    }
                }
            case .offline:
                break
            }
            cslvalues.readings = []
            zebraSingleton.startInventory(power: 10)
            zebraSingleton.onTagAdded = { tag in
                if tag.epc.count == 24 {
                    self.cslvalues.addEpc(reading: tag)
                }
            }
        }
        .onDisappear {
            CSLHelper.onExitInventory()
        }
        .onChange(of: cslvalues.isTriggerApplied) { isTriggerApplied in
            print("TRIGGER IN TAGGIN!!!!! \(String(isTriggerApplied))")
            if (!isInventoryStarted) {
                onInventory()
            }
        }
        .navigationBarTitle("Tagging")
        .navigationViewStyle(StackNavigationViewStyle())
        .navigationBarItems(trailing:
            HStack {
                Button("Save") { isSaveModalPresent = true }
                .padding(.leading, 10)
                .alert(isPresented: $isSaveModalPresent, content: {
                    if cslvalues.readings.count > 0 {
                        return Alert(
                            title: Text("Save Asset"),
                            message: Text("Do you want to proceed?"),
                            primaryButton: .default(Text("OK"), action: { onSave(epcsarray: cslvalues.readings) }),
                            secondaryButton: .cancel(Text("Cancel"))
                        )
                    } else {
                        return Alert(
                            title: Text("Error: Empty or Duplicate EPC"),
                            dismissButton: .cancel(Text("OK"), action: { })
                        )
                    }
                })
            }
        )
        

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
                CSLHelper.onStartRFIDInventory()
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
    
    @AppStorage(Settings.userIdKey) var userId = "app"
    @AppStorage(Settings.userNameKey) var userName = "Guest"
    @AppStorage(Settings.userLastNameKey) var userLastName = "User"
    
    func onSave(epcsarray: [EpcModel]) {
        switch workModeManager.workMode {
        case .online:
            onlineTagging(epcsarray)
        case .offline:
            offlineTagging(epcsarray)
        }
    }
    
    private func onlineTagging(_ epcsarray: [EpcModel]) {
        if (cslvalues.readings.count == 0) {
            isTryingSaveEmptyPresent = true
            return
        }
        
        var _epcs: [String] = []
        for read in epcsarray {
            _epcs.append(read.epc)
        }
        let paramsRepeat: [String: Any] = ["fieldValues": _epcs]
        
        ApiAssets().validateEPCS(params: paramsRepeat) { _existingEPCS in
            removedExistingCount = _existingEPCS.count
            for epc in _existingEPCS {
                cslvalues.removeEpc(epc: epc.EPC)
            }
            
            if (cslvalues.readings.count == 0) {
                isTryingSaveEmptyPresent = true
                isSaveModalPresent = true
                return
            }
            
            let params: [String: Any] = [
                "name": reference.name ?? "",
                "brand": reference.brand ?? "",
                "model": reference.model ?? "",
                "serial": serialNumber,
                "EPC": getEpcs(),
                "location": location._id,
                "locationPath": filterOutLocationPath(),
                "creationUserFullName":"\(userName) \(userLastName)",
                "labeling_user": "\(userName) \(userLastName)",
                "customFieldsTab": "pending",
                "referenceId": reference._id,
                "tabs": getTabsJson(),
                "customFields": getCustomFieldsJson(),
                "customFieldsValues": customFieldsValues,
                "assigned": assignedEmployee._id,
                "assignedTo": "\(assignedEmployee.name) \(assignedEmployee.lastName) <\(assignedEmployee.email)>"
            ]
            
            cslvalues.isLoading = true
            if !isNewImageSelected {
                ApiReferences().postAssets(params: params) { result in
                    switch result {
                    case .success(let savedAssets):
                        savedAssetsCount = savedAssets.count
                        isSavedAssetsPresent = true
                    case .failure(_ ):
                        isSavedAssetsPresent = false
                    }
                    cslvalues.isLoading = false
                }
            } else {
                ApiFile().postImage(image: imageSelected) { result in
                    switch result {
                    case .success(let uploadFile):
                        let fileparams: [String: Any] = [
                            "filename": uploadFile.filename,
                            "path": uploadFile.path
                        ]
                        let fileassetsparams = params.merging(fileparams) { (_, new) in new }
                        ApiReferences().postAssets(params: fileassetsparams) { result in
                            switch result {
                            case .success(let savedAssets):
                                savedAssetsCount = savedAssets.count
                                isSavedAssetsPresent = true
                            case .failure(_ ):
                                break
                            }
                        }
                    case .failure(_ ):
                        print("error")
                        
                    }
                    cslvalues.isLoading = false
                }
            }
        }
    }
    
    private func offlineTagging(_ epcsarray: [EpcModel]) {
        workModeManager.tag(asset: reference,
                            location: location,
                            locationPath: filterOutLocationPath(),
                            epc: getEpcs(),
                            userId: userId,
                            serialNumber: serialNumber,
                            tabs: getTabsJson(),
                            customFields: getCustomFieldsJson(),
                            customFieldsValues: customFieldsValues,
                            employee: assignedEmployee,
                            image: isNewImageSelected ? (imageSelected.jpegData(compressionQuality: 1.0)) : nil) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(_ ):
                    savedAssetsCount = epcsarray.count
                    isSavedAssetsPresent = true
                    // Limpiamos el mensaje de error si se guarda exitosamente
                    errorMessage = ""
                case .failure(let error):
                    if let nsError = error as NSError?, nsError.code == 409 {
                        errorMessage = "Error: Duplicate EPC"
                        // Elimina el EPC duplicado de la lista
                        if let duplicateEpc = epcsarray.first?.epc {
                            cslvalues.removeEpc(epc: duplicateEpc)
                        }
                    } else {
                        errorMessage = error.localizedDescription
                    }
                    isSavedAssetsPresent = false
                }
                // Asegúrate de desactivar el estado de carga en el hilo principal
                cslvalues.isLoading = false
            }
        }
    }
    
    func filterOutLocationPath() -> String {
        let locArray = locationPath.components(separatedBy: " / ")
        let locStr = locArray.joined(separator: "/")
        return locStr.count > 0 ? String(locStr.suffix(locStr.count - 1)) : ""
    }
    
    func getEpcs() -> [String] {
        if (cslvalues.readings.count > 0) {
            if (isSingle) {
                return [cslvalues.readings[0].epc]
            } else {
                var epcs = [String]()
                for reading in cslvalues.readings {
                    epcs.append(reading.epc)
                }
                print("getEpcs: \(epcs)") // Log
                return epcs;
            }
        } else {
            return []
        }
    }
    
    func getTabsJson() -> [[String: Any]] {
        var _tabs = [[String: Any]]()
        
        for tab in customFields.tabs {
            let _tab: [String: Any] = [
                "columns": tab.columns,
                "tabId": tab.tabId,
                "tabName": tab.tabName
            ]
            _tabs.append(_tab)
        }
        
        return _tabs
    }
    
    func getCustomFieldsJson() -> [[String: Any]] {
        var _customFields = [[String: Any]]()
        
        for customField in customFields.customFields {
            let _customField: [String: Any] = [
                "columnPosition": customField.columnPosition,
                "content": customField.content,
                "fieldId": customField.fieldId,
                "options": customField.options,
                "columns": customField.columns,
                "tabId": customField.tabId,
                "tabName": customField.tabName,
                "fieldName": customField.fieldName,
                "fieldIndex": customField.fieldIndex
            ]
            _customFields.append(_customField)
        }
        
        return _customFields
    }
    
    func validateEPC(epcsarray: [EpcModel]) {
        var _epcs: [String] = []
        for read in epcsarray {
            _epcs.append(read.epc)
        }
        let params: [String: Any] = ["fieldValues": _epcs]
        
        ApiAssets().validateEPCS(params: params) { _existingEPCS in
            for epc in _existingEPCS {
                cslvalues.removeEpc(epc: epc.EPC)
            }
            removedExistingCount = _existingEPCS.count
            isRemoveExistingModalResult = true
        }
    }
}

struct CardView: View {
    @ObservedObject var cslvalues: CSLValues
    @Binding var reference: ReferenceModel
    @Binding var location: LocationModel
    @Binding var isSingle: Bool
    @Binding var inventoryButton: String
    @Binding var isInventoryStarted: Bool
    @Binding var barcodeMode: Bool
    @Binding var customFields: responseObj
    var _onInvetory: () -> Void
    var validateEPC: ([EpcModel]) -> Void
    @Binding var customFieldsValues: [String]
    @State var showCustomFields: Bool = false
    @State var showAssetPhoto: Bool = false
    @Binding var serialNumber: String
    @Binding var locationPath: String
    @Binding var isRemoveExistingModalResult: Bool
    @Binding var removedExistingCount: Int
    @Binding var isSavedAssetsPresent: Bool
    @Binding var savedAssetsCount: Int
    @Binding var imageSelected: UIImage
    @Binding var isNewImageSelected: Bool
    @State var customFieldsImages: [AssetPhoto] = []
    @State var customFieldsImagesData: [ImageCustomField] = []
    @Binding var assignedEmployee: EmployeeModel
    
    var body: some View {
        
        VStack(alignment: .leading) {
            GeneralInformation(reference: $reference)
            
            HStack {
                Button("Asset Photo") {
                    showAssetPhoto.toggle()
                }.foregroundColor(.white) // Color del texto
                    .padding(8)
                    .background(Color.blue.opacity(0.8)) // Fondo azul del botón
                    .cornerRadius(6)
                    .font(.system(size: 14, weight: .bold))
                .sheet(isPresented: $showAssetPhoto) {
                    AssetPhoto(imageSelected: $imageSelected, isNewImageSelected: $isNewImageSelected, showAssetPhoto: $showAssetPhoto)
                }
                Spacer()
                Button("Custom Fields") {
                    showCustomFields.toggle()
                }.foregroundColor(.white)
                    .padding(8)
                    .background(Color.blue.opacity(0.8))
                    .cornerRadius(6)
                    .font(.system(size: 14, weight: .bold))
                .sheet(isPresented: $showCustomFields) {
                    CustomFields(customFields: $customFields, customFieldsValues: $customFieldsValues, showCustomFields: $showCustomFields, customFieldsImages: $customFieldsImages, customFieldsImagesData: $customFieldsImagesData)
                }
            }
            .padding(.trailing, 50)
            .padding(.leading, 50)
            .padding(.top, 5)
            
            MainView(location: $location, cslvalues: cslvalues, isSingle: $isSingle, inventoryButton: $inventoryButton, isInventoryStarted: $isInventoryStarted, barcodeMode: $barcodeMode, serialNumber: $serialNumber, locationPath: $locationPath, isRemoveExistingModalResult: $isRemoveExistingModalResult, removedExistingCount: $removedExistingCount, isSavedAssetsPresent: $isSavedAssetsPresent, savedAssetsCount: $savedAssetsCount, _onInvetory: _onInvetory, validateEPC: validateEPC, assignedEmployee: $assignedEmployee)
        }
    }
}

struct MainView: View {
    @State var isDummy: Bool = false
    @State var cont: Int = 0
    @Binding var location: LocationModel
    @ObservedObject var epcs: EpcsArray = EpcsArray()
    @ObservedObject var cslvalues: CSLValues
    @Binding var isSingle: Bool
    @Binding var inventoryButton: String
    @Binding var isInventoryStarted: Bool
    @Binding var barcodeMode: Bool
    @State var isKeeping: Bool = false
    @Binding var serialNumber: String
    @State var powerLevel: Double = 10
    @State var maxPowerLevel: Double = 30
    @Binding var locationPath: String
    @State var isRemoveExistingModalPresent: Bool = false
    @Binding var isRemoveExistingModalResult: Bool
    @Binding var removedExistingCount: Int
    @Binding var isSavedAssetsPresent: Bool
    @Binding var savedAssetsCount: Int
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    var _onInvetory: () -> Void
    var validateEPC: ([EpcModel]) -> Void
    @Binding var assignedEmployee: EmployeeModel
    @State var showEmployeesModal: Bool = false
    @EnvironmentObject var zebraSingleton: ZebraSingleton
    
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                Text("Asset will be created in:")
                    .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                    .foregroundColor(.secondary)
                    .padding(.top)
                Text(locationPath)
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
                VStack(alignment: .leading) {
                    HStack {
                        Text("Employee Assigned:")
                            .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                            .foregroundColor(.secondary)
                        Button("Assign") {
                            showEmployeesModal.toggle()
                        }.foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.4))
                            .cornerRadius(6)
                            .font(.system(size: 14, weight: .bold))
                        .sheet(isPresented: $showEmployeesModal) {
                            EmployeeView(cslvalues: cslvalues, isModal: true, showModal: $showEmployeesModal, selectedEmployee: $assignedEmployee)
                        }
                        Spacer()
                        Button("Clear") {
                            assignedEmployee = EmployeeModel(_id: "", name: "", lastName: "", email: "", employee_id: "")
                        }.foregroundColor(.white)
                            .padding(8)
                            .background(Color.red.opacity(0.8))
                            .cornerRadius(6)
                            .font(.system(size: 14, weight: .bold))
                    }
                    Text(getEmployeeAssignedText())
                        .foregroundColor(.secondary)
                        .padding(.top, -3)
                }
                .padding(.top)
            }
            .onAppear() {
                maxPowerLevel = zebraSingleton.getMaxPower()
            }
            .onChange(of: cslvalues.singleBarcode) { barcode in
                serialNumber += barcode
            }
            .padding(.horizontal, 40)
            
            VStack(alignment: .leading) {
                Text("Actions:")
                    .foregroundColor(.secondary)
                VStack(alignment: .leading) {
                    Toggle("Single Asset", isOn: $isSingle)
                        .toggleStyle(SwitchToggleStyle(tint: .orange))
                    Toggle("Keep info", isOn: $isKeeping)
                        .toggleStyle(SwitchToggleStyle(tint: .orange))
                    Toggle("\(inventoryButton) RFID:", isOn: $isInventoryStarted)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                        .onChange(of: isInventoryStarted, perform: { scan in
                            _onInvetory()
                        })
                        .disabled(cslvalues.isTriggerApplied)
                }
                .padding()
                .frame(width: UIScreen.main.bounds.width - 40)
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            .padding(.top, 15)
            .padding(.horizontal, 40)
            
            VStack(alignment: .leading) {
                HStack(alignment: .center) {
                    Text("EPC Readings (\(cslvalues.readings.count)):")
                        .foregroundColor(.secondary)
                    Spacer()
                    Rectangle()
                        .frame(width: 30, height: 30, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                        .cornerRadius(30)
                        .padding(.trailing)
                        .foregroundColor(inventoryButton == "Stop" ? Color.green : Color.gray)
                }
                VStack(alignment: .leading) {
                    HStack {
                        Spacer()
                        Button(action: {
                            isRemoveExistingModalPresent.toggle()
                        }) {
                            Text("Remove EPCs")
                               
                        }.foregroundColor(.white)
                            .padding(8)
                            .background(Color.red.opacity(0.8))
                            .cornerRadius(6)
                            .font(.system(size: 14, weight: .bold))
                        .alert(isPresented: $isRemoveExistingModalPresent, content: {
                            Alert(
                                title: Text("Remove Existing"),
                                message: Text("Are you sure to remove existing EPCs?"),
                                primaryButton: .default(Text("OK"), action: { validateEPC(cslvalues.readings) }),
                                secondaryButton: .cancel(Text("Cancel"))
                            )
                        })
                        Button(action:{
                            self.presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("Exit")
                        }.foregroundColor(.white)
                            .padding(8)
                            .background(Color.red.opacity(0.8))
                            .cornerRadius(6)
                            .font(.system(size: 14, weight: .bold))
                        .alert(isPresented: $isSavedAssetsPresent, content: {
                            Alert(
                                title: Text(getSavedMessage()),
                                dismissButton: .default(Text("OK"), action: {
                                    savedAssetsCount = 0
                                    removedExistingCount = 0
                                    if !isKeeping {
                                        self.presentationMode.wrappedValue.dismiss()
                                    } else {
                                        CSLHelper.onClear(cslvalues: cslvalues)
                                        serialNumber = ""
                                    }
                                })
                            )
                        })
                    }
                    VStack {
                        if isDummy {
                            Button("Add EPC") {
                                addEPC()
                            }
                            .padding(.top, 2)
                        }
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
                    .padding(.top)
                    .padding(.bottom)
                    ScrollView {
                        ForEach(getFilteredEpcs(epcarray: cslvalues.readings), id: \.self) { tag in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(tag.epc)
                                        .fontWeight(.semibold)
                                        .padding(.top, 5)
                                    Text("RSSI: \(tag.rssi)")
                                        .font(.caption)
                                    Text(tag.timestamp)
                                        .font(.caption)
                                }
                                Spacer()
                                Button(action:{ cslvalues.removeEpc(epc: tag.epc) }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.horizontal, 5)
                            Divider()
                        }
                    }
                    .frame(minHeight: 200)
                    .frame(maxHeight: 800)
                }
                .padding()
                .frame(width: UIScreen.main.bounds.width - 40)
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            .padding(.top, 25)
            .padding(.horizontal, 40)
            
            Spacer()
            
        }
    }
    func addEPC() {
        let array = ["057454000000000000006F23", "474D30304B0181021000234F", "474130304B0181021000234F", "057454000000000000007237"]
        let epc = array[cont]
        let epcModel = EpcModel(epc: epc, rssi: "", timestamp: Utils.getFullDate())
        self.cslvalues.addEpc(reading: epcModel)
        if cont < array.count - 1 {
            cont += 1
        }
    }
    // MARK: FUNCTIONS
    func getFilteredEpcs(epcarray: [EpcModel]) -> [EpcModel] {
        if (isSingle) {
            if (epcarray.count > 0) {
                return [epcarray[0]]
            } else {
                return []
            }
        } else {
            return epcarray
        }
    }
    
    func getSavedMessage() -> String {
        if isSingle {
            return "Asset successfully saved"
        } else {
            return "Successfully saved [\(savedAssetsCount)]   assets. [\(removedExistingCount)] EPCs repeated"
        }
    }
    
    func getEmployeeAssignedText() -> String {
        if assignedEmployee.name == "" && assignedEmployee.lastName == "" {
            return "<No employee selected>"
        } else {
            return "\(assignedEmployee.name) \(assignedEmployee.lastName)"
        }
    }
}

struct GeneralInformation: View {
    @Binding var reference: ReferenceModel
    var body: some View {
        HStack {
            Spacer()
            VStack {
                Text(reference.name ?? "")
                    .font(.title)
                    .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                    .fixedSize(horizontal: false, vertical: /*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/)
                    .padding(.top)
                    .padding(.leading)
                    .padding(.trailing)
                Text(reference.brand ?? "")
                    .foregroundColor(.secondary)
                    .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                    .fixedSize(horizontal: false, vertical: /*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/)
                    .padding(.leading)
                    .padding(.trailing)
                Text(reference.model ?? "")
                    .foregroundColor(.secondary)
                    .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                    .fixedSize(horizontal: false, vertical: /*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/)
                    .padding(.leading)
                    .padding(.trailing)
                LoadImage(fileExt: reference.fileExt ?? "", id: reference._id)
            }
            Spacer()
        }
    }
}

struct TaggingView_Previews: PreviewProvider {
    static var url = "https://cdn.pocket-lint.com/r/s/970x/assets/images/152137-laptops-review-apple-macbook-pro-2020-review-image1-pbzm4ejvvs.jpg"
    static var reference: ReferenceModel = ReferenceModel(_id: "614950025c9d393fe941f320", brand: "Apple", model: "Macbook Pro", name: "Laptop", fileExt: "")
    static var epcs = EpcsArray()
    static var customFields = responseObj()
    static var locationPath = "Mexico / CDMX / Santa Fe / Punta / Floor 14 / Quebec"
    static var locationId = "606b5e811b8b9f390457a5ff"
    static var location: LocationModel = LocationModel(_id: locationId, name: "Quebec", type: "City", level: 2, childrenNumber: 5, assetsNumber: 15, canTag: true, canInventory: true, path: locationPath)
    
    static var previews: some View {
        NavigationView {
            TaggingView(cslvalues: CSLValues(), reference: reference, location: location, customFields: customFields)
        }
    }
}
