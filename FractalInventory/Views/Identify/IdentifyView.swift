//
//  IdentifyView.swift
//  FractalInventory
//
//  Created by Miguel Cruz on 31/08/21.
//

import SwiftUI

struct IdentifyView: View {
    @ObservedObject var cslvalues: CSLValues
    @StateObject var zebraSingleton: ZebraSingleton = ZebraSingleton.shared
    @State private var inventoryButton: String = "Start"
    @State private var isInventoryStarted: Bool = false
    @State private var barcodeMode: Bool = false
    @State private var navigateToValidateView: Bool = false
    @State var showFirstReadModal: Bool = false
    @State var zebraTagList: [String] = []
    
    var body: some View {
        
        VStack {
            IdentifyReadings(
                cslvalues: cslvalues,
                isTriggerApplied: cslvalues.isTriggerApplied,
                isInventoryStarted: $isInventoryStarted,
                inventoryButton: $inventoryButton,
                barcodeMode: $barcodeMode,
                _onInvetory: onInventory,
                zebraTagList: $zebraTagList,
                onClear: {
                    CSLHelper.onClear(cslvalues: cslvalues)
                }
            )
            
            NavigationLink(destination: ValidatedView(cslvalues: cslvalues), isActive: $navigateToValidateView) {
                EmptyView()
            }
            
            Spacer()
        }
        .onAppear {
            zebraSingleton.startInventory()
            zebraSingleton.onTagAdded = { tag in
                if zebraTagList.first(where: { $0 == tag}) == nil {
                    zebraTagList.append(tag)
                }
            }
        }
        .onChange(of: cslvalues.isTriggerApplied) { isTriggerApplied in
            print("TRIGGER IN INVENTORY!!!!! \(String(isTriggerApplied))")
            if (!isInventoryStarted) {
                onInventory()
            }
        }
        .navigationBarTitle("Identify", displayMode: .inline)
        .navigationBarItems(trailing:
                                HStack {
            Button("Validate") {
                if cslvalues.readings.count > 0 {
                    navigateToValidateView.toggle()
                } else {
                    showFirstReadModal.toggle()
                }
                
            }
            .disabled(inventoryButton == "Stop")
            .alert(isPresented: $showFirstReadModal, content: {
                Alert(
                    title: Text("First read EPCs"),
                    dismissButton: .cancel(Text("OK"), action: {})
                )
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
    func updateAntenaRFID() {
        
    }
}
struct IdentifyReadings: View {
    @EnvironmentObject var zebraSingleton: ZebraSingleton
    @ObservedObject var cslvalues: CSLValues
    let isTriggerApplied: Bool
    @Binding var isInventoryStarted: Bool
    @Binding var inventoryButton: String
    @Binding var barcodeMode: Bool
    @State var powerLevel: Double = 30
    var _onInvetory: () -> Void
    // var epclist: EpcsArray = EpcsArray()
    @Binding var zebraTagList: [String]
    let onClear: (() -> Void)
    
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
                    .disabled(isTriggerApplied)
                VStack {
                    Slider(value: $powerLevel, in: 0...zebraSingleton.getMaxPower(), step: 1)
                        .accentColor(Color.green)
                        .onChange(of: powerLevel, perform: { power in
                            updateAntenaPower(power: power)
                        })
                        .disabled(inventoryButton == "Stop")
                    Text("Power Level: \(powerLevel, specifier: "%.0f")")
                }
                HStack {
                    Button(action: onClear) {
                        Text("Clear")
                    }
                    Spacer()
                    Text("Total: \(getCount())")
                }
                .padding(.top)
                ScrollView {
                    if zebraSingleton.isAvailable() {
                        LazyVStack {
                            ForEach(zebraTagList, id: \.self) { tag in
                                HStack {
                                    IdentifyReadingSubview(reading: EpcModel(epc: tag, rssi: "", timestamp: ""), remove: {
                                        removeTag(tag: tag)
                                    })
                                    Spacer()
                                }
                            }
                        }
                    } else {
                        LazyVStack {
                            ForEach(cslvalues.readings, id: \.self) { tag in
                                HStack {
                                    let epcModel = EpcModel(epc: tag.epc, rssi: tag.rssi, timestamp: tag.timestamp)
                                    IdentifyReadingSubview(reading: epcModel, remove: {
                                        cslvalues.removeEpc(epc: tag.epc)
                                    })
                                    Spacer()
                                }
                            }
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
        .onAppear {
            powerLevel = zebraSingleton.getMaxPower()
        }
        .padding(.horizontal, 40)
        .padding(.top)
    }
    private func removeTag(tag: String) {
        if let index = zebraTagList.firstIndex(where: { $0 == tag }) {
            zebraTagList.remove(at: index)
        }
    }
    private func getCount() -> Int {
        if zebraSingleton.isAvailable() {
            return cslvalues.readings.count
        } else {
            return zebraTagList.count
        }
    }
    private func updateAntenaPower(power: Double) {
        if zebraSingleton.isAvailable() {
            zebraSingleton.updateAntennaPower(power: power)
        } else {
            CSLRfidAppEngine.shared().reader.selectAntennaPort(0)
            CSLRfidAppEngine.shared().reader.setPower(power)
        }
    }
}
struct IdentifyView_Previews: PreviewProvider {
    static var previews: some View {
        IdentifyView(cslvalues: CSLValues())
    }
}
