//
//  ReadersList.swift
//  FractalInventory
//
//  Created by Miguel Cruz on 29/08/21.
//

import SwiftUI

struct Settings {
    static let apiHostKey = "apiHost"
    static let apiDBKey = "apiDB"
    static let userIdKey = "userId"
    static let userNameKey = "userName"
    static let userLastNameKey = "userLastName"
    static let userTokenKey = "userToken"
    static let userFileExt = "userFileExt"
}

struct SettingsView: View {
    @ObservedObject var cslvalues: CSLValues
    @StateObject var zebraSingleton = ZebraSingleton.shared
    @Binding var isUserLoggedOut: Bool
    
    var body: some View {
        VStack {
            let workMode = WorkModeManager().workMode
            SettingsViewContent(cslvalues: cslvalues, workingModeIsOffline: workMode.isOffline, isUserLoggedOut: $isUserLoggedOut, workingMode: workMode)
        }
        .navigationBarTitle("Settings", displayMode: .inline)
        .navigationViewStyle(StackNavigationViewStyle())
        .environmentObject(zebraSingleton)
    }
}

struct SettingsViewContent: View {
    @EnvironmentObject var zebraSingleton: ZebraSingleton
    @ObservedObject var cslvalues: CSLValues
    @State var deviceFoundCount: Int = -1
    @State var deviceListName: [String] = []
    @State var connectToReader: Bool = false
    @State var selectedDeviceName: String = ""
    @State var selectedDeviceIndex: Int = -1
    @State var startScanning: Bool = false
    @State var isDeviceConnected: Bool = false
    @State var connectedDeviceName: String = ""
    @State var batteryLevel: String = "" //rename rfid device
    @State var deviceSerialNumber: String = ""
    @State var disconnectDevice: Bool = false
    @State var presentSuccessOfflineAlert = false
    @State var presentSuccessOnlineAlert = false
    @State var presentstartOfflineAlert = false
    @State var workingModeIsOffline: Bool
    @State var assetsSaved: Int = 0
    @State var error: WMError?
    @State var isToggleForAError = false
    @Binding var isUserLoggedOut: Bool
    @State var workingMode: WorkMode {
        didSet {
            workingModeIsOffline = workingMode == .offline
        }
    }
    @State var startScanningZebra: Bool = false
    @State var connectZebraToReader: Bool = false
    @State var disconnectZebraDevice: Bool = false
    
    let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    let devName = "CS108ReaderF76D81"
    let workModeManager = WorkModeManager()
    
    var body: some View {
        VStack {
            Form {
                Section(header: Text("Connection")) {
                    ConnectionsSubview(cslvalues: cslvalues, isUserLoggedOut: $isUserLoggedOut)
                }
                
                Section(header: Text("CSL RFID Handheld scan")) {
                    Toggle("Start Device Scanning", isOn: $startScanning)
                        .onChange(of: startScanning, perform: { scan in
                            if zebraSingleton.isDeviceConnectedZebra {
                                print("El lector Zebra ya está conectado. No se puede iniciar el escaneo CSL.")
                                startScanning = false
                                return
                            }
                            if scan {
                                CSLHelper.deviceScanStart()
                            } else {
                                CSLHelper.deviceScanStop()
                                deviceListName = []
                            }
                        })
                    if (startScanning) {
                        Text("Bellow will appear available devices")
                        List {
                            ForEach(Array(deviceListName.enumerated()), id: \.offset) { index, device in
                                Button(action: {
                                    selectedDeviceName = device
                                    selectedDeviceIndex = index
                                    connectToReader = true
                                }) {
                                    Text("Device Name: \(device)")
                                        .padding()
                                }
                            }
                        }
                    }
                }
                .disabled(isDeviceConnected)
                .alert(isPresented: $connectToReader ) {
                    Alert(
                        title: Text("Connect to reader"),
                        message: Text("You'll connect to \(selectedDeviceName)"),
                        primaryButton: .default(Text("OK")) {
                            cslvalues.isLoading = true
                            startScanning = false
                            CSLHelper.connectToDevice(deviceIndex: selectedDeviceIndex)
                        },
                        secondaryButton: .default(Text("Cancel")) {
                            selectedDeviceName = ""
                            selectedDeviceIndex = -1
                        }
                    )
                }
                .onChange(of: isDeviceConnected, perform: { value in
                    if value {
                        cslvalues.isLoading = false
                    }
                })
                
                if (isDeviceConnected) {
                    Section(header: Text("CSL RFID Handheld connected")) {
                        Text("Device: \(connectedDeviceName)")
                        Text("SN: \(deviceSerialNumber)")
                        Text("Battery: \(batteryLevel)")
                        HStack {
                            Spacer()
                            Button(action: { disconnectDevice = true }) {
                                Text("Disconnect Device")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .alert(isPresented: $disconnectDevice) {
                        Alert(
                            title: Text("Disconnect from reader"),
                            message: Text("You'll disconnect from \(connectedDeviceName) "),
                            primaryButton: .default(Text("OK")) {
                                CSLHelper.disconnectFromDevice()
                            },
                            secondaryButton: .default(Text("Cancel")) {
                                disconnectDevice = false
                            }
                        )
                    }
                }
                /// Zebra section
            Section(header: Text("ZEBRA RFID Handheld scan")) {
                Toggle("Start Device Scanning", isOn: $startScanningZebra)
                    .onChange(of: startScanningZebra, perform: { scan in
                        if isDeviceConnected {
                            print("El lector CSL ya está conectado. No se puede iniciar el escaneo Zebra.")
                            startScanningZebra = false
                            return
                        }
                        if scan {
                            startScannigZebra()
                        } else {
                            stopScanningZebra()
                            zebraSingleton.listDevices = []
                        }
                    })
           
                    if (startScanningZebra) {
                        Text("Bellow will appear available devices")
                        List {
                            ForEach(Array(zebraSingleton.listDevices.enumerated()), id: \.offset) { index, device in
                                Button(action: {
                                    zebraSingleton.selectedZebraDevice = device
                                    // if device.type == .available {
                                        connectZebraToReader = true
                                    // }
                                }) {
                                    Text("Device Name: \(device.name) - \(device.type.toString)")
                                        .padding()
                                }
                            }
                        }
                    }
                }
                .disabled(zebraSingleton.isDeviceConnectedZebra)
                .alert(isPresented: $connectZebraToReader ) {
                    Alert(
                        title: Text("Connect to reader"),
                        message: Text("You'll connect to \(zebraSingleton.selectedZebraDevice.id)"),
                        primaryButton: .default(Text("OK")) {
                            startScanningZebra = false
                            zebraSingleton.establishCommunication(readerID: zebraSingleton.selectedZebraDevice.id)
                        },
                        secondaryButton: .default(Text("Cancel")) {
                            startScanningZebra = false
                            zebraSingleton.selectedZebraDevice = .empty
                            connectZebraToReader = false
                        }
                    )
                }
                .onChange(of: zebraSingleton.isDeviceConnectedZebra, perform: { value in
                    if value {
                       
                    }
                })
                
                if (zebraSingleton.isDeviceConnectedZebra) {
                    Section(header: Text("Zebra RFID Handle connected")) {
                        Text("Device: \(ZebraSingleton.shared.selectedZebraDevice.name)")
                        Text("SN: \(ZebraSingleton.shared.serialNumber)")
                        Text("Battery: \(ZebraSingleton.shared.batteryLevel)")
                        HStack {
                            Spacer()
                            Button(action: { disconnectZebraDevice = true }) {
                                Text("Disconnect Device")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .alert(isPresented: $disconnectZebraDevice) {
                        Alert(
                            title: Text("Disconnect from reader"),
                            message: Text("You'll disconnect from \(ZebraSingleton.shared.selectedZebraDevice.name) "),
                            primaryButton: .default(Text("OK")) {
                                ZebraSingleton.shared.endCommunication(readerID: ZebraSingleton.shared.selectedZebraDevice.id)
                            },
                            secondaryButton: .default(Text("Cancel")) {
                                disconnectDevice = false
                            }
                        )
                    }
                }
                
                // Work mode section
                Section(header: Text("working mode")) {
                    Toggle(isOn: $workingModeIsOffline) {
                        Text(workingModeIsOffline ? "Offline" : "Online")
                            .foregroundColor(workingModeIsOffline ? .red : .green)
                        
                    }
                    .onChange(of: workingModeIsOffline, perform: { loadData in
                        if isToggleForAError {
                            isToggleForAError = false
                            return
                        }
                        switch workModeManager.workMode {
                        case .online:
                            presentstartOfflineAlert = true
                        case .offline:
                            endOfflineWorkingMode()
                        }
                    })
                    if workingModeIsOffline {
                        Text("Last update:  \(workModeManager.offlineStartDateFormatted)")
                        Text("Saved assets:  \(assetsSaved)")
                    }
                }            }
        }.alert(item: $error, content: { error in
            Alert(
                title: Text(error.title),
                message: Text(error.description),
                primaryButton: .default(Text("Ok"), action: {
                    isToggleForAError = false
                }),
                secondaryButton: .default(Text("Retry"), action: {
                    switch workingMode {
                    case .online:
                        self.startOfflineWorkingMode()
                    case .offline:
                        self.endOfflineWorkingMode()
                    }
                })
            )
        })
        Text("")
            .alert(isPresented: $presentSuccessOfflineAlert) {
                Alert(
                    title: Text("success"),
                    message: Text("Offline mode enabled successfully"),
                    dismissButton: .default(Text("Ok"), action: {
                        
                    })
                )
            }
        Text("")
            .alert(isPresented: $presentSuccessOnlineAlert) {
                Alert(
                    title: Text("success"),
                    message: Text("Online mode enabled successfully,\n\(assetsSaved) items have been synchronized."),
                    dismissButton: .default(Text("Ok"), action: {
                        assetsSaved = 0
                    })
                )
            }
        Text("")
            .alert(isPresented: $presentstartOfflineAlert) {
                Alert(
                    title: Text("Offline Mode"),
                    message: Text("The download of the catalogs will begin, it is important to check that your internet connection"),
                    dismissButton: .default(Text("Ok"), action: {
                        startOfflineWorkingMode()
                    })
                )
            }
            .onAppear {
                isDeviceConnected = CSLHelper.isDeviceConnected()
            }
            .onDisappear {
                CSLHelper.deviceScanStop()
            }
            .onReceive(timer) { _ in
                getDeviceInfo()
                getAssetsCount()
            }
    }
    func startScannigZebra() {
        ZebraSingleton.shared.setupSDK()
    }
    func stopScanningZebra() {
    }
    func getDeviceInfo() {
        deviceFoundCount = CSLHelper.getDeviceCount()
        deviceListName = CSLHelper.getDeviceListNames()
        isDeviceConnected = CSLHelper.isDeviceConnected()
        if (isDeviceConnected) {
            connectedDeviceName = CSLHelper.getConnectedDeviceName()
            deviceSerialNumber = CSLHelper.getDeviceSerialNumber()
            batteryLevel = String(cslvalues.batteryLevel)
        } else {
            connectedDeviceName = ""
            deviceSerialNumber = ""
            batteryLevel = ""
        }
    }
    
    private func getAssetsCount() {
        if workModeManager.workMode == .offline {
            workModeManager.getAssets { result in
                switch result {
                case .success(let assets):
                    self.assetsSaved = assets.count
                case .failure(_ ):
                    break
                }
            }
        }
    }
    
    private func startOfflineWorkingMode() {
        cslvalues.isLoading = true
        workModeManager.startOfflineMode { result in 
            switch result {
            case .success(let workMode):
                presentSuccessOfflineAlert = false
                presentSuccessOfflineAlert = true
                workingMode = workMode
                cslvalues.isLoading = false
            case .failure(let error):
                print("****\n-->startOfflineWorkingMode error\n**** ")
                workingMode = .online
                self.error = error
                self.isToggleForAError = true
                cslvalues.isLoading = false
            }
        }
    }
    
    private func endOfflineWorkingMode() {
        cslvalues.isLoading = true
        workModeManager.startOnlineMode { result in
            cslvalues.isLoading = false
            switch result {
            case .success(let data):
                presentSuccessOnlineAlert = true
                workingMode = data.workMode
            case .failure(let error):
                workingMode = .offline
                self.error = error
                self.isToggleForAError = true
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsView(cslvalues: CSLValues(), isUserLoggedOut: .constant(true))
        }
    }
}
