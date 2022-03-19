//
//  RawRfidView.swift
//  FractalInventory
//
//  Created by Miguel Cruz on 31/08/21.
//

import SwiftUI

struct RawRfidView: View {
    @ObservedObject var cslvalues: CSLValues
    @State private var inventoryButton: String = "Start"
    @State private var isInventoryStarted: Bool = false
    @State private var barcodeMode: Bool = false
    
    var body: some View {
            VStack(alignment: .leading) {
                ReaderInfoView(cslvalues: cslvalues, inventoryButton: $inventoryButton, barcodeMode: $barcodeMode)
                
                ReadingsInfo(cslvalues: cslvalues, isInventoryStarted: $isInventoryStarted, inventoryButton: $inventoryButton, barcodeMode: $barcodeMode, _onInvetory: onInventory)

                Spacer()
            }
            .padding()
            .onAppear {
                CSLHelper.onLoadInventory()
                CSLHelper.onClear(cslvalues: cslvalues)
            }
            .onDisappear {
                CSLHelper.onExitInventory()
            }
            .onChange(of: cslvalues.isTriggerApplied) { isTriggerApplied in
                if (!isInventoryStarted) {
                    onInventory()
                }
            }
            .navigationBarTitle("Raw Readings", displayMode: .inline)
        
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
}

struct ReaderInfoView: View {
    @ObservedObject var cslvalues: CSLValues
    @Binding var inventoryButton: String
    @Binding var barcodeMode: Bool
    @State var powerLevel: Double = 30

    var body: some View {
        VStack(alignment: .leading) {
            Text("RFID Reader:")
                .foregroundColor(.secondary)
            VStack(alignment: .leading) {
                HStack {
                    Text("Name:")
                    Spacer()
                    Text(cslvalues.deviceName)
                }
                HStack {
                    Text("SN:")
                    Spacer()
                    Text(cslvalues.deviceSN)
                }
                HStack {
                    Text("Battery level:")
                    Spacer()
                    Text("\(cslvalues.batteryLevel)%")
                }
                Toggle("Barcode Mode:", isOn: $barcodeMode)
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                    .onChange(of: barcodeMode, perform: { barcode in
                        CSLRfidAppEngine.shared().soundAlert(kSystemSoundID_Vibrate)
                        CSLRfidAppEngine.shared().isBarcodeMode = barcode
                        CSLHelper.onClear(cslvalues: cslvalues)
                    })
                    .disabled(inventoryButton == "Stop")
                VStack {
                    Slider(value: $powerLevel, in: 0...30, step: 1)
                        .accentColor(Color.green)
                        .onChange(of: powerLevel, perform: { power in
                            print("UPDATE POWERLEVEL")
                            CSLRfidAppEngine.shared().reader.selectAntennaPort(0)
                            CSLRfidAppEngine.shared().reader.setPower(power)
                        })
                        .disabled(inventoryButton == "Stop")
                    Text("Power Level: \(powerLevel, specifier: "%.0f")")
                }.padding(.top)
                
            }
            .padding()
            .frame(width: UIScreen.main.bounds.width - 40)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .padding(.horizontal, 40)
    }
}

struct ReadingsInfo: View {
    @ObservedObject var cslvalues: CSLValues
    @Binding var isInventoryStarted: Bool
    @Binding var inventoryButton: String
    @Binding var barcodeMode: Bool
    var _onInvetory: () -> Void
    var epclist: EpcsArray = EpcsArray()
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Readings:")
                    .foregroundColor(.secondary)
                Spacer()
                Rectangle()
                    .frame(width: 30, height: 30, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                    .cornerRadius(30)
                    .padding(.trailing)
                    .foregroundColor(inventoryButton == "Stop" ? Color.green : Color.gray)
            }
            VStack(alignment: .leading) {
                Toggle("\(inventoryButton) Inventory:", isOn: $isInventoryStarted)
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                    .onChange(of: isInventoryStarted, perform: { scan in
                        _onInvetory()
                    })
                    .disabled(cslvalues.isTriggerApplied)
                HStack {
                    Button(action: { CSLHelper.onClear(cslvalues: cslvalues) }) {
                        Text("Clear")
                    }
                    Spacer()
                    Text("Total: \(cslvalues.readings.count)")
                }
                .padding(.top)
                ScrollView {
                    ForEach(cslvalues.readings, id: \.self) { tag in
                        HStack {
                            ReadingSubview(cslvalues: cslvalues, reading: EpcModel(epc: tag.epc, rssi: tag.rssi, timestamp: tag.timestamp), barcodeMode: barcodeMode)
                            Spacer()
                        }
                    }
                }
                .frame(maxHeight: 300)
                .padding(.top)
                
            }
            .padding()
            .frame(width: UIScreen.main.bounds.width - 40)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .padding(.horizontal, 40)
        .padding(.top)
    }
}

struct RawRfidView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            RawRfidView(cslvalues: CSLValues())
        }
    }
}
