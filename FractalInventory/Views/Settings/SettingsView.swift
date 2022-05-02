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
    @Binding var isUserLoggedOut: Bool
    
    
    var body: some View {
        VStack {
            let workMode = WorkModeManager().workMode
            SettingsViewContent(cslvalues: cslvalues, workingModeIsOffline: workMode.isOffline, isUserLoggedOut: $isUserLoggedOut, workingMode: workMode)
        }
        .navigationBarTitle("Settings", displayMode: .inline)
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct SettingsViewContent: View {
    @ObservedObject var cslvalues: CSLValues
    @State var deviceFoundCount: Int = -1
    @State var deviceListName: [String] = []
    @State var connectToReader: Bool = false
    @State var selectedDeviceName: String = ""
    @State var selectedDeviceIndex: Int = -1
    @State var startScanning: Bool = false
    @State var isDeviceConnected: Bool = false
    @State var connectedDeviceName: String = ""
    @State var batteryLevel: String = ""
    @State var deviceSerialNumber: String = ""
    @State var disconnectDevice: Bool = false
    @State var presentSuccessOfflineAlert = false
    @State var presentSuccessOnlineAlert = false
    @State var workingModeIsOffline: Bool
    @State var assetsSaved: Int = 0
    @State var error: WMError?
    @Binding var isUserLoggedOut: Bool
    @State var workingMode: WorkMode {
        didSet {
            workingModeIsOffline = workingMode == .offline
        }
    }
    
    
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
                            if (scan) {
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
                
                // Work mode section
                Section(header: Text("working mode")) {
                    Toggle(isOn: $workingModeIsOffline) {
                        Text(workingModeIsOffline ? "Offline" : "Online")
                            .foregroundColor(workingModeIsOffline ? .red : .green)
                        
                    }
                    .onChange(of: workingModeIsOffline, perform: { loadData in
                        if loadData {
                            startOfflineWorkingMode()
                        } else {
                            endOfflineWorkingMode()
                        }
                    })
                    if workingModeIsOffline {
                        Text("Last update:  \(workModeManager.offlineStartDateFormatted)")
                        Text("Saved assets:  \(assetsSaved)")
                        
                    }
                }.alert(isPresented: $presentSuccessOfflineAlert) {
                    Alert(
                        title: Text("success"),
                        message: Text("Offline mode enabled successfully"),
                        dismissButton: .default(Text("Ok"), action: {
                            
                        })
                    )
                }
                .alert(isPresented: $presentSuccessOnlineAlert) {
                    Alert(
                        title: Text("success"),
                        message: Text("Online mode enabled successfully,\n\(assetsSaved) items have been synchronized."),
                        dismissButton: .default(Text("Ok"), action: {
                            assetsSaved = 0
                        })
                    )
                }
                // Termina seccion de modo offline
            }
        }.alert(item: $error, content: { error in
            Alert(
                title: Text(error.title),
                message: Text(error.description),
                primaryButton: .default(Text("Ok"), action: {
                        
                    }),
                    secondaryButton: .default(Text("Retry"), action: {
                        self.endOfflineWorkingMode()
                    })
                
            )
        })
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
            cslvalues.isLoading = false
            switch result {
            case .success(let workMode):
                presentSuccessOfflineAlert = true
                workingMode = workMode
            case .failure(let error):
                workingMode = .online
                self.error = error
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
