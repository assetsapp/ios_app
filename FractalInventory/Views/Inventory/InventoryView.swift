//
//  InventoryView.swift
//  FractalInventory
//
//  Created by Miguel Cruz on 25/09/21.
//

import SwiftUI

enum InventoryType: String {
    case root = "0"
    case subLevels = "1"
}

struct InventoryView: View {
    
    @ObservedObject var cslvalues: CSLValues
    @State var assets: [AssetModel] = []
    @State var filterStatus: [String] = ["found", "missing", "external"]
    @State var locationPath: String = ""
    @State var location: String
    @State var locationName: String = ""
    @State var showFound: Bool = true
    @State var showMissing: Bool = true
    @State var showExternal: Bool = true
    @State var showFilters: Bool = false
    @State var showRFIDSection: Bool = false
    @State var epcType: Int = 0
    @State private var inventoryButton: String = "Start"
    @State var isInventoryStarted: Bool = false
    @State private var barcodeMode: Bool = false
    @State var powerLevel: Double = 30
    @State var localEPCs: [String] = []
    @State var showSession: Bool = false
    @State var inventorySession: String = ""
    @State var inventoryName: String = ""
    @State var inventoryUpdates: [String] = []
    @State var isExistingSession: Bool = false
    @State var closeInventorySessionModal: Bool = false
    @State var showResetModal: Bool = false
    @State var type: InventoryType = .root
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    var body: some View {
        VStack {
            VStack {
                // MARK: Inventory Session
                if inventorySession != "" {
                    VStack {
                        HStack {
                            Text("Session Information")
                                .fontWeight(.semibold)
                            Spacer()
                            Button(action: { showSession.toggle() }) {
                                Image(systemName: "chevron.\(showSession ? "up" : "down")")
                            }
                        }
                        .padding(.top, 2)
                        if showSession {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Session Id:")
                                    Text(inventorySession)
                                        .foregroundColor(.secondary)
                                    Text("Session Name:")
                                    Text(inventoryName)
                                        .foregroundColor(.secondary)
                                    
                                    HStack {
                                        Spacer()
                                        Button(action: { closeInventorySessionModal.toggle() }) {
                                            HStack {
                                                Text("Close Session")
                                                Image(systemName: "lock")
                                            }
                                            .padding(.top, 3)
                                        }
                                        .alert(isPresented: $closeInventorySessionModal, content: {
                                            Alert(
                                                title: Text("Inventory Session"),
                                                message: Text("Do you want to close the session?"),
                                                primaryButton: .default(Text("OK"), action: { updateInventory(closeInventory: true) }),
                                                secondaryButton: .cancel(Text("Cancel"))
                                            )
                                        })
                                    }
                                }
                                Spacer()
                            }
                            .padding(.top, 2)
                            .transition(.move(edge: .leading))
                            .animation(.spring())
                        }
                    }
                    .padding()
                    .frame(width: UIScreen.main.bounds.width - 40)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                
                VStack {
                    HStack {
                        VStack(alignment: .leading) {
                            Group {
                                Text("Inventory ") + Text("\(assets.count) ").bold() + Text("asset\(assets.count > 1 ? "s" : "") in:")
                            }
                            Text(locationPath)
                                .foregroundColor(.secondary)
                                .padding(.top, 1)
                        }
                        Spacer()
                    }
                    HStack {
                        Text("Missing:")
                        Text("\(getStatusCount(type: "missing"))")
                            .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                            .foregroundColor(.red)
                        Spacer()
                        Text("Found:")
                        Text("\(getStatusCount(type: "found"))")
                            .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                            .foregroundColor(.green)
                        Spacer()
                        Text("External:")
                        Text("\(getStatusCount(type: "external"))")
                            .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                            .foregroundColor(.orange)
                    }.padding(.top, 2)
                    HStack {
                        Text("Show filters")
                            .fontWeight(.semibold)
                        Spacer()
                        Button(action: { showFilters.toggle() }) {
                            Image(systemName: "chevron.\(showFilters ? "up" : "down")")
                        }
                    }
                    .padding(.top, 2)
                    if showFilters {
                        VStack {
                            Toggle("Found (\(getStatusCount(type: "found")))", isOn: $showFound)
                                .toggleStyle(SwitchToggleStyle(tint: .green))
                                .onChange(of: showFound, perform: { value in
                                    setFilterStatus(status: "found", value: value)
                                })
                            Toggle("Missing (\(getStatusCount(type: "missing")))", isOn: $showMissing)
                                .toggleStyle(SwitchToggleStyle(tint: .red))
                                .onChange(of: showMissing, perform: { value in
                                    setFilterStatus(status: "missing", value: value)
                                })
                            Toggle("External (\(getStatusCount(type: "external")))", isOn: $showExternal)
                                .toggleStyle(SwitchToggleStyle(tint: .orange))
                                .onChange(of: showExternal, perform: { value in
                                    setFilterStatus(status: "external", value: value)
                                })
                            HStack {
                                Text("EPC:")
                                Picker("Mode", selection: $epcType) {
                                    Text("All").tag(0)
                                    Text("RFID").tag(1)
                                    Text("Virtual").tag(2)
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .padding(.leading)
                            }
                        }
                        .transition(.move(edge: .bottom))
                        .animation(.spring())
                    }
                }
                .padding()
                .frame(width: UIScreen.main.bounds.width - 40)
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            .padding(.top)
            
            VStack {
                VStack {
                    HStack {
                        Text("RFID Antenna")
                            .fontWeight(.semibold)
                        Spacer()
                        Button(action: { showRFIDSection.toggle() }) {
                            Image(systemName: "chevron.\(showRFIDSection ? "up" : "down")")
                        }
                    }
                    .padding(.top, 2)
                    if showRFIDSection {
                        VStack {
                            VStack {
                                Slider(value: $powerLevel, in: 0...30, step: 1)
                                    .accentColor(Color.green)
                                    .onChange(of: powerLevel, perform: { power in
                                        CSLRfidAppEngine.shared().reader.selectAntennaPort(0)
                                        CSLRfidAppEngine.shared().reader.setPower(power)
                                    })
                                    .disabled(inventoryButton == "Stop")
                                Text("Power Level: \(powerLevel, specifier: "%.0f")")
                            }
                            Toggle("\(inventoryButton) RFID:", isOn: $isInventoryStarted)
                                .toggleStyle(SwitchToggleStyle(tint: .blue))
                                .onChange(of: isInventoryStarted, perform: { scan in
                                    onInventory()
                                })
                                .disabled(cslvalues.isTriggerApplied)
                        }
                        .transition(.move(edge: .bottom))
                        .animation(.spring())
                    }
                }
                .padding()
                .frame(width: UIScreen.main.bounds.width - 40)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                HStack(alignment: .center) {
                    Text("EPC Readings (\(cslvalues.readings.count)):")
                        .foregroundColor(.secondary)
                    Spacer()
                    Rectangle()
                        .frame(width: 30, height: 30, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                        .cornerRadius(30)
                        .foregroundColor(inventoryButton == "Stop" ? Color.green : Color.gray)
                }.padding(.horizontal, 30)
            }
            
            ScrollView {
                LazyVStack {
                    ForEach(getAssetsToShow(), id: \.self) { asset in
                        AssetSubview(asset: asset, locationId: location, locationPath: locationPath, assets: $assets, inventoryUpdates: $inventoryUpdates, sessionId: inventorySession)
                            .padding(.top, -7)
                    }
                }
                .padding(.top)
            }
            .cornerRadius(10)
            Spacer()
        }
        .onAppear {
            resetInventory()
            cslvalues.isLoading = true
            if isExistingSession {
                ApiInventorySessions().getInventorySessionAssets(sessionId: inventorySession) { _assets in
                    self.assets = _assets
                    cslvalues.isLoading = false
                }
            } else {
                ApiAssets().getInventoryAssets(location: location, locationName: locationName, sessionId: inventorySession, inventoryName: inventoryName, type: type) { _assets in
                    self.assets = _assets
                    cslvalues.isLoading = false
                }
            }
        }
        .onDisappear {
            if inventorySession != "" {
                updateInventory()
            }
        }
        .onChange(of: cslvalues.isTriggerApplied) { isTriggerApplied in
            print("TRIGGER IN INVENTORY!!!!! \(String(isTriggerApplied))")
            if (!isInventoryStarted) {
                onInventory()
            }
        }
        .onChange(of: cslvalues.readings.count) { _ in
            onNewReading()
        }
        .navigationBarTitle("Inventory")
        .navigationViewStyle(StackNavigationViewStyle())
        .navigationBarItems(trailing:
                                HStack {
            Button("Reset") {
                showResetModal.toggle()
            }
            .alert(isPresented: $showResetModal, content: {
                Alert(
                    title: Text("Inventory"),
                    message: Text("Do you want to reset Inventory?"),
                    primaryButton: .default(Text("OK"), action: { resetInventory() }),
                    secondaryButton: .cancel(Text("Cancel"))
                )
            })
        }
        )
    }
    
    // MARK: FUNCTIONS
    func getStatusCount(type: String) -> Int {
        return assets.filter { $0.status == type }.count
    }
    
    func getAssetsToShow() -> [AssetModel] {
        let filteredAssets = assets.filter { filterStatus.contains($0.status ?? "") }
        if epcType == 1 {
            return filteredAssets.filter { ($0.EPC ?? "").count == 24 } // Add hex validation, not only length
        } else if epcType == 2 {
            return filteredAssets.filter { ($0.EPC ?? "").count != 24 } // Add hex validation, not only length
        } else {
            return filteredAssets
        }
    }
    
    func setFilterStatus(status: String, value: Bool) {
        if value {
            if !filterStatus.contains(status) {
                filterStatus.append(status)
            }
        } else {
            if let index = filterStatus.firstIndex(of: status) {
                filterStatus.remove(at: index)
            }
        }
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
    
    func onNewReading() {
        for read in cslvalues.readings {
            if !localEPCs.contains(read.epc) {
                localEPCs.append(read.epc)
                let foundAssetIndex = assets.firstIndex { $0.EPC == read.epc } ?? -1
                if foundAssetIndex >= 0 {
                    assets[foundAssetIndex].status = "found"
                    let foundEPC = assets[foundAssetIndex].EPC
                    inventoryUpdates.append(foundEPC ?? "")
                } else {
                    ApiAssets().getAsset(EPC: read.epc) { _asset in
                        if _asset.count > 0 {
                            let external = _asset[0]
                            let externalAsset = AssetModel(_id: external._id, brand: external.brand ?? "", model: external.model ?? "", name: external.name, EPC: external.EPC ?? "", serial: external.serial ?? "", location: location , status: "external", locationPath: external.locationPath ?? "")
                            assets.append(externalAsset)
                        }
                    }
                }
            }
        }
    }
    
    func resetInventory() {
        localEPCs = []
        var resetAssets: [AssetModel] = []
        for asset in assets {
            if asset.status != "external" {
                var assetCopy = asset
                if assetCopy.status == "found" {
                    assetCopy.status = "missing"
                }
                resetAssets.append(assetCopy)
            }
        }
        assets = resetAssets
        
        if CSLHelper.isDeviceConnected() {
            CSLHelper.onClear(cslvalues: cslvalues)
            CSLRfidAppEngine.shared().reader.selectAntennaPort(0)
            CSLRfidAppEngine.shared().reader.setPower(powerLevel)
        }
    }
    
    func updateInventory(closeInventory: Bool = false) {
        let params: [String: Any] = [
            "foundEPCS": inventoryUpdates,
            "sessionId": inventorySession,
            "closeInventory": closeInventory
        ]
        
        ApiInventorySessions().updateAssetsInInventorySession(params: params) { _ in
            if closeInventory {
                self.presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

struct InventoryView_Previews: PreviewProvider {
    static var assets: [AssetModel] = [
        AssetModel(_id: "abcde00", brand: "Apple", model: "Macbook Pro", name: "Laptop", EPC: "ABCDEF0123456789ABCD0001", serial: "qwerty", location: "", status: "missing"),
        AssetModel(_id: "abcde01", brand: "LG", model: "OLED", name: "Television", EPC: "ABCDEF0123456789ABCD0002", serial: "qwerty2", location: "", status: "missing"),
        AssetModel(_id: "abcde02", brand: "EPSON", model: "Rainbow", name: "Projector", EPC: "virtualEPC0005", serial: "qwerty4", location: "", status: "external"),
        AssetModel(_id: "abcde03", brand: "Samsung", model: "Wide", name: "Monitor", EPC: "ABCDEF0123456789ABCD0003", serial: "qwerty3", location: "", status: "found"),
        AssetModel(_id: "abcde04", brand: "Sony", model: "Bravia", name: "TV", EPC: "ABCDEF0123456789ABCD0004", serial: "qwerty4", location: "", status: "missing")
    ]
    static var location: String = "606b5e811b8b9f390457a5ff"
    
    static var previews: some View {
        NavigationView {
            InventoryView(cslvalues: CSLValues(), assets: assets, location: location)
        }
    }
}
