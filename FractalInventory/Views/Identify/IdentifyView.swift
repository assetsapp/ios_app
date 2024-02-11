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
    
    var body: some View {
        VStack {
            IdentifyReadings(
                cslvalues: cslvalues,
                isTriggerApplied: cslvalues.isTriggerApplied,
                isInventoryStarted: $isInventoryStarted,
                inventoryButton: $inventoryButton,
                barcodeMode: $barcodeMode,
                _onInvetory: onInventory,
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
            zebraSingleton.onTagAdded = { tag in
                self.cslvalues.addEpc(reading: tag)
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
}
struct IdentifyReadings: View {
    @EnvironmentObject var zebraSingleton: ZebraSingleton
    @ObservedObject var cslvalues: CSLValues
    let isTriggerApplied: Bool
    @Binding var isInventoryStarted: Bool
    @Binding var inventoryButton: String
    @Binding var barcodeMode: Bool
    @State var powerLevel: Double = 30
    @State var maxPowerLevel: Double = 30
    var _onInvetory: () -> Void
    // var epclist: EpcsArray = EpcsArray()
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
                HStack {
                    Button(action: onClear) {
                        Text("Clear")
                    }
                    Spacer()
                    Text("Total: \(cslvalues.readings.count)")
                }
                .padding(.top)
                ScrollView {
                    LazyVStack {
                        ForEach(cslvalues.readings, id: \.self) { tag in
                            HStack {
                                IdentifyReadingSubview(reading: tag, remove: {
                                    cslvalues.removeEpc(epc: tag.epc)
                                })
                                Spacer()
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
            let maxPower = zebraSingleton.getMaxPower()
            powerLevel = maxPower
            maxPowerLevel = maxPower
            zebraSingleton.startInventory(power: Int16(maxPower))
        }
        .padding(.horizontal, 40)
        .padding(.top)
    }
}
struct IdentifyView_Previews: PreviewProvider {
    static var previews: some View {
        IdentifyView(cslvalues: CSLValues())
    }
}
