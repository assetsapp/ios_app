//
//  CSLDelegates.swift
//  FractalInventory
//
//  Created by Miguel Cruz on 31/08/21.
//

import Foundation
import SwiftUI
struct CSLDelegates: UIViewControllerRepresentable {
    let vc = CSLViewModel()
    @ObservedObject var cslvalues: CSLValues
  
    func makeUIViewController(context: Context) -> CSLViewModel {
        return vc
    }
  
    func updateUIViewController(_ uiViewController: CSLViewModel, context: Context) { }
    func makeCoordinator() -> Coordinator {
        let cc = Coordinator()
        cc.cslvalues = cslvalues
        return cc
    }
    
    class Coordinator: CSLViewModel {
        @ObservedObject var cslvalues: CSLValues = CSLValues()
        
        override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?)   {
            print("init nibName style")
            super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
            CSLRfidAppEngine.shared().reader.delegate = self
            CSLRfidAppEngine.shared().reader.readerDelegate = self
            print("INICIALIZADO Y CON DELEGATES SET!!!!!!!!!!!!!!!!!!")
        }

        // note slightly new syntax for 2017
        required init?(coder aDecoder: NSCoder) {
            print("init coder style")
            super.init(coder: aDecoder)
        }
        
        override func didReceiveTagResponsePacket(_ sender: CSLBleReader?, tagReceived tag: CSLBleTag?) {
            if self.cslvalues.isGeiger && self.cslvalues.geigerEPC == tag?.epc {
                DispatchQueue.main.async(execute: {
                    self.cslvalues.geigerValue = tag?.rssi ?? 0
                })
            } else {
                DispatchQueue.main.async(execute: {
                    let _epc = tag?.epc ?? "noepc"
                    let _rssi = tag?.rssi ?? 0
                    if !self.cslvalues.readings.contains(where: { $0.epc == _epc }) && _epc != "" && _epc.count == 24 {
                        CSLRfidAppEngine.shared().soundAlert(1005)
                        self.cslvalues.addEpc(reading: EpcModel(epc: _epc, rssi: String(_rssi), timestamp: self.cslvalues.getFullDate()))
                    }
                })
            }
        }
        
        override func didTriggerKeyChangedState(_ sender: CSLBleReader!, keyState state: Bool) {
            DispatchQueue.main.async(execute: {
                print("> > > >")
                print("didTriggerKeyChangedState >>> \(state)")
                self.cslvalues.isTriggerApplied = state
            })
        }
        
        override func didReceiveBatteryLevelIndicator(_ sender: CSLBleReader!, batteryPercentage battPct: Int32) {
            DispatchQueue.main.async {
                print("> > > > Delegate *******")
                self.cslvalues.batteryLevel = battPct
                self.cslvalues.deviceName = CSLRfidAppEngine.shared().reader.deviceName
                self.cslvalues.deviceSN = CSLRfidAppEngine.shared().readerInfo.deviceSerialNumber
                print("didReceiveBatteryLevelIndicator 0 >> \(battPct) <<")
                print("didReceiveBatteryLevelIndicator 1 >> \(self.cslvalues.batteryLevel) <<")
            }
        }
        
        override func didReceiveBarcodeData(_ sender: CSLBleReader!, scannedBarcode barcode: CSLReaderBarcode!) {
            DispatchQueue.main.async(execute: {
                print("> > > > DELEGATE")
                print("didReceiveBarcodeData")
                let _barcode = barcode?.barcodeValue ?? "nobarcode"
                if self.cslvalues.isSingleBarcode {
                    self.cslvalues.singleBarcode = _barcode
                } else {
                    self.cslvalues.addEpc(reading: EpcModel(epc: _barcode, rssi: "", timestamp: self.cslvalues.getFullDate()))
                }
                print("Value >> \(_barcode)")
            })
        }
        
        override func didReceiveTagAccessData(_ sender: CSLBleReader!, tagReceived tag: CSLBleTag!) {
            print("> > > >")
            print("didReceiveTagAccessData")
        }
        
        override func viewWillDisappear(_ animated: Bool) {
//            remove delegate assignment so that trigger key will not triggered when out of this page
            CSLRfidAppEngine.shared().reader.delegate = nil
            CSLRfidAppEngine.shared().reader.readerDelegate = nil
            print("**************** Delegates Dettached")
        }
    }
}
