//
//  CSLValues.swift
//  FractalInventory
//
//  Created by Miguel Cruz on 04/09/21.
//

import Foundation

class CSLValues: ObservableObject {
    @Published var batteryLevel: Int32
    @Published var readings: [EpcModel]
    @Published var connectedDeviceName: String
    @Published var connectedDeviceSN: String
    @Published var isTriggerApplied: Bool
    @Published var deviceWidth: CGFloat
    @Published var deviceHeight: CGFloat
    @Published var deviceName: String
    @Published var deviceSN: String
    @Published var isIpad: Bool
    @Published var isSingleBarcode: Bool
    @Published var singleBarcode: String
    @Published var isGeiger: Bool
    @Published var geigerEPC: String
    @Published var geigerValue: UInt8
    @Published var isLoading: Bool
    @Published var showNonConnected: Bool
    @Published var appVersion: String

    init() {
        self.batteryLevel = 0
        self.readings = []
        self.connectedDeviceName = ""
        self.connectedDeviceSN = ""
        self.deviceName = ""
        self.deviceSN = ""
        self.isTriggerApplied = false
        self.deviceWidth = UIScreen.main.bounds.width
        self.deviceHeight = UIScreen.main.bounds.height
        self.isIpad = UIScreen.main.bounds.width > 400
        self.isSingleBarcode = false
        self.singleBarcode = ""
        self.isGeiger = false
        self.geigerEPC = ""
        self.geigerValue = 0
        self.isLoading = false
        self.showNonConnected = false
        self.appVersion = "v0.310322"
    }
    
    // Note: For RawRFID readings, this function/array is also used to store barcodes
    func addEpc(reading: EpcModel) {
        if !readings.contains(where: { $0.epc == reading.epc }) {
            readings.insert(EpcModel(epc: reading.epc, rssi: String(reading.rssi), timestamp: reading.timestamp), at: 0)
            CSLRfidAppEngine.shared().soundAlert(1005)
        }
        print("/////////////////Tag Found EPC = \(reading.epc)")
        print("/////////////////Tag Found RSSI = \(reading.rssi)")
        print("*******************\(readings.count)")
    }
    
    func removeEpc(epc: String) {
        if let index = readings.firstIndex(where: { $0.epc == epc }) {
            readings.remove(at: index)
        }
    }
}
