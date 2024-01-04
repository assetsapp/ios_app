//
//  IdentifyView.swift
//  FractalInventory
//
//  Created by Miguel Cruz on 31/08/21.
//

import SwiftUI

struct IdentifyView: View {
    @ObservedObject var cslvalues: CSLValues
    @State private var inventoryButton: String = "Start"
    @State private var isInventoryStarted: Bool = false
    @State private var barcodeMode: Bool = false
    @State private var navigateToValidateView: Bool = false
    @State var showFirstReadModal: Bool = false
    
    var body: some View {
        
        VStack {
            IdentifyReadings(cslvalues: cslvalues, isInventoryStarted: $isInventoryStarted, inventoryButton: $inventoryButton, barcodeMode: $barcodeMode, _onInvetory: onInventory)
            
            NavigationLink(destination: ValidatedView(cslvalues: cslvalues), isActive: $navigateToValidateView) {
                EmptyView()
            }
            
            Spacer()
        }
        .onAppear {
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
    /// Obtener el Nivel de Poder del Device
    func getPowerLevel() -> Int {
        /// Validar si existe un dispositivo Zebra conectado
        let currentID = ZebraSingleton.shared.currentReaderID
        if  currentID != -1 {
            let antenaConfiguration = ZebraSingleton.shared.antenaConfiguration
            let capabilities = ZebraSingleton.shared.antenaCapabilities
            let currentPower = antenaConfiguration?.getPower()
            let minPower = capabilities?.getMinPower()
            let maxPower = capabilities?.getMaxPower() ?? 0
            let step = capabilities?.getPowerStep()
            return Int(maxPower)
        } else {
            return 30
        }
    }
    func updateAntenaRFID() {
        
    }
}

struct IdentifyReadings: View {
    @ObservedObject var cslvalues: CSLValues
    @Binding var isInventoryStarted: Bool
    @Binding var inventoryButton: String
    @Binding var barcodeMode: Bool
    @State var powerLevel: Double = (ZebraSingleton.shared.currentReaderID != -1) ? 100 : -1
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
                            IdentifyReadingSubview(cslvalues: cslvalues, reading: EpcModel(epc: tag.epc, rssi: tag.rssi, timestamp: tag.timestamp))
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


struct IdentifyView_Previews: PreviewProvider {
    static var previews: some View {
        IdentifyView(cslvalues: CSLValues())
    }
}
