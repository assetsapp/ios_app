//
//  CSLHelper.swift
//  FractalInventory
//
//  Created by Miguel Cruz on 30/08/21.
//

import Foundation
import SwiftUI

class CSLHelper {
    @State private static var transport: MQTTCFSocketTransport?
    @State private static var session: MQTTSession?
    @State private static var inventoryButton: String = "Start"
    @State private static var _cslvalues: CSLValues?
    
    static func getDeviceCount() -> Int {
        return CSLRfidAppEngine.shared().reader.bleDeviceList.count
    }
    
    static func getDeviceListNames() -> [String] {
        return CSLRfidAppEngine.shared().reader.deviceListName as NSArray as! [String]
    }
    
    static func deviceScanStart() {
        CSLRfidAppEngine.shared().reader.startScanDevice()
    }
    
    static func deviceScanStop() {
        CSLRfidAppEngine.shared().reader.stopScanDevice()
    }

    static func connectToDevice(deviceIndex: Int) {
        //stop scanning for device
        CSLRfidAppEngine.shared().reader.stopScanDevice()
        //connect to device selected
        CSLRfidAppEngine.shared().reader.connectDevice(CSLRfidAppEngine.shared()?.reader.bleDeviceList[deviceIndex] as! CBPeripheral?)
        
        for _ in 0..<COMMAND_TIMEOUT_5S {
            //receive data or time out in 5 seconds
            if CSLRfidAppEngine.shared().reader.connectStatus == STATUS.CONNECTED {
                break
            }
            RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.001))
        }
        
        if CSLRfidAppEngine.shared().reader.connectStatus != STATUS.CONNECTED {
            print("Failed to connect to reader.")
        } else {
            
            //set device name to singleton object
            CSLRfidAppEngine.shared().reader.deviceName = CSLRfidAppEngine.shared().reader.deviceListName[deviceIndex] as? String
            var btFwVersion: NSString?
            var slVersion: NSString?
            var rfidBoardSn: NSString?
            var pcbBoardVersion: NSString?
            var rfidFwVersion: NSString?
            var appVersion: String?
            
            let btFwVersionPtr = AutoreleasingUnsafeMutablePointer<NSString?>?.init(&btFwVersion)
            let slVersionPtr = AutoreleasingUnsafeMutablePointer<NSString?>?.init(&slVersion)
            let rfidBoardSnPtr = AutoreleasingUnsafeMutablePointer<NSString?>?.init(&rfidBoardSn)
            let pcbBoardVersionPtr = AutoreleasingUnsafeMutablePointer<NSString?>?.init(&pcbBoardVersion)
            let rfidFwVersionPtr = AutoreleasingUnsafeMutablePointer<NSString?>?.init(&rfidFwVersion)
            
            //Configure reader
            CSLRfidAppEngine.shared().reader.barcodeReader(true)
            CSLRfidAppEngine.shared().reader.power(onRfid: false)
            CSLRfidAppEngine.shared().reader.power(onRfid: true)
            if CSLRfidAppEngine.shared().reader.getBtFirmwareVersion(btFwVersionPtr) {
                CSLRfidAppEngine.shared().readerInfo.btFirmwareVersion = btFwVersionPtr?.pointee as String?
            }
            if CSLRfidAppEngine.shared().reader.getSilLabIcVersion(slVersionPtr) {
                CSLRfidAppEngine.shared().readerInfo.siLabICFirmwareVersion = slVersionPtr?.pointee as String?
            }
            if CSLRfidAppEngine.shared().reader.getRfidBrdSerialNumber(rfidBoardSnPtr) {
                CSLRfidAppEngine.shared().readerInfo.deviceSerialNumber = rfidBoardSnPtr?.pointee as String?
            }
            if CSLRfidAppEngine.shared().reader.getPcBBoardVersion(pcbBoardVersionPtr) {
                CSLRfidAppEngine.shared().readerInfo.pcbBoardVersion = pcbBoardVersionPtr?.pointee as String?
            }
            
            CSLRfidAppEngine.shared().reader.batteryInfo.setPcbVersion(pcbBoardVersionPtr?.pointee?.doubleValue ?? 0.0)
            
            CSLRfidAppEngine.shared().reader.sendAbortCommand()
            
            if CSLRfidAppEngine.shared().reader.getRfidFwVersionNumber(rfidFwVersionPtr) {
                CSLRfidAppEngine.shared().readerInfo.rfidFirmwareVersion = rfidFwVersionPtr?.pointee as String?
            }
            
            
            if let object = Bundle.main.infoDictionary?["CFBundleShortVersionString"], let object1 = Bundle.main.infoDictionary?[kCFBundleVersionKey as String] {
                appVersion = "v\(object) Build \(object1)"
            }
            CSLRfidAppEngine.shared().readerInfo.appVersion = appVersion
            
            
            var OEMData: UInt32 = 0
            
            //device country code
            CSLRfidAppEngine.shared().reader.readOEMData(CSLRfidAppEngine.shared().reader, atAddr: 0x00000002, forData: &OEMData)
            CSLRfidAppEngine.shared().readerInfo.countryCode = OEMData
            print(String(format: "OEM data address 0x%08X: 0x%08X", 0x02, OEMData))
            //special country version
            CSLRfidAppEngine.shared().reader.readOEMData(CSLRfidAppEngine.shared().reader, atAddr: 0x0000008e, forData: &OEMData)
            CSLRfidAppEngine.shared().readerInfo.specialCountryVerison = OEMData
            print(String(format: "OEM data address 0x%08X: 0x%08X", 0x8e, OEMData))
            //freqency modification flag
            CSLRfidAppEngine.shared().reader.readOEMData(CSLRfidAppEngine.shared().reader, atAddr: 0x0000008f, forData: &OEMData)
            CSLRfidAppEngine.shared().readerInfo.freqModFlag = OEMData
            print(String(format: "OEM data address 0x%08X: 0x%08X", 0x8f, OEMData))
            //model code
            CSLRfidAppEngine.shared().reader.readOEMData(CSLRfidAppEngine.shared().reader, atAddr: 0x000000a4, forData: &OEMData)
            CSLRfidAppEngine.shared().readerInfo.modelCode = OEMData
            print(String(format: "OEM data address 0x%08X: 0x%08X", 0xa4, OEMData))
            //hopping/fixed frequency
            CSLRfidAppEngine.shared().reader.readOEMData(CSLRfidAppEngine.shared().reader, atAddr: 0x0000009d, forData: &OEMData)
            CSLRfidAppEngine.shared().readerInfo.isFxied = OEMData
            print(String(format: "OEM data address 0x%08X: 0x%08X", 0x9d, OEMData))
            
            CSLRfidAppEngine.shared().readerRegionFrequency = CSLReaderFrequency(
                oemData: CSLRfidAppEngine.shared().readerInfo.countryCode,
                specialCountryVerison: CSLRfidAppEngine.shared().readerInfo.specialCountryVerison,
                freqModFlag: CSLRfidAppEngine.shared().readerInfo.freqModFlag,
                modelCode: CSLRfidAppEngine.shared().readerInfo.modelCode,
                isFixed: CSLRfidAppEngine.shared().readerInfo.isFxied)
            
            if CSLRfidAppEngine.shared().readerRegionFrequency.tableOfFrequencies[CSLRfidAppEngine.shared().settings.region!] == nil {
                //the region being stored is not valid, reset to default region and frequency channel
                CSLRfidAppEngine.shared().settings.region = CSLRfidAppEngine.shared().readerRegionFrequency.regionList[0] as? String
                CSLRfidAppEngine.shared().settings.channel = "0"
                CSLRfidAppEngine.shared().saveSettingsToUserDefaults()
            }
            
            
            
            
            let fw = CSLRfidAppEngine.shared().readerInfo.btFirmwareVersion as String
            if fw.count >= 5 {
                if (fw.prefix(1) == "3") {
                    //if BT firmware version is greater than v3, it is connecting to CS463
                    CSLRfidAppEngine.shared().reader.readerModelNumber = READERTYPE.CS463
                } else {
                    CSLRfidAppEngine.shared().reader.readerModelNumber = READERTYPE.CS108
                    CSLRfidAppEngine.shared().reader.startBatteryAutoReporting()
                }
            }
            
            //set low power mode
            CSLRfidAppEngine.shared().reader.setPowerMode(true)
            
            print("Reader successfully connected!!!")
        }

    }
    
    static func disconnectFromDevice() {
        if (isDeviceConnected()) {
            CSLRfidAppEngine.shared().reader.barcodeReader(false)
            CSLRfidAppEngine.shared().reader.power(onRfid: false)
            CSLRfidAppEngine.shared().reader.disconnectDevice()
        }
    }
    
    static func reloadSettingsFromDefaults() {
        CSLRfidAppEngine.shared().reloadSettingsFromUserDefaults()
        // Remove tag buffer
        CSLRfidAppEngine.shared().reader.filteredBuffer = nil
        CSLRfidAppEngine.shared().reader.filteredBuffer = NSMutableArray.init()
        // Refresh MQTT (All previous connections will drop) and temperature tag settings
        CSLRfidAppEngine.shared().mqttSettings = CSLMQTTSettings()
        CSLRfidAppEngine.shared().reloadMQTTSettingsFromUserDefaults()
        CSLRfidAppEngine.shared().temperatureSettings = CSLTemperatureTagSettings()
        CSLRfidAppEngine.shared().reloadTemperatureTagSettingsFromUserDefaults()
        CSLRfidAppEngine.shared().settings = CSLReaderSettings()
        CSLRfidAppEngine.shared().reloadSettingsFromUserDefaults()
    }
    
    static func isDeviceConnected() -> Bool {
        return CSLRfidAppEngine.shared().reader.connectStatus == STATUS.CONNECTED
    }
    
    static func getConnectedDeviceName() -> String {
        if isDeviceConnected() {
            return CSLRfidAppEngine.shared().reader.deviceName
        } else {
            return "N/A"
        }
    }
    
    static func getDeviceModelNumber() -> READERTYPE {
        return CSLRfidAppEngine.shared().reader.readerModelNumber
    }
    
    static func getBaterryLevel() -> String {
        let batteryPercentage = CSLRfidAppEngine.shared().readerInfo.batteryPercentage
        if isDeviceConnected() {
            if getDeviceModelNumber() == READERTYPE.CS108 {
                if batteryPercentage < 0 || batteryPercentage > 100 {
                    return "N/A"
                } else {
                    return String(format: "Battery: %d%%", CSLRfidAppEngine.shared().readerInfo.batteryPercentage)
                }
            }
        } else {
            return "Not connected"
        }
        return ""
    }
    
    static func getDeviceSerialNumber() -> String {
        if isDeviceConnected() {
            return CSLRfidAppEngine.shared().readerInfo.deviceSerialNumber
        } else {
            return "N/A"
        }
    }
    
    static func getDBL() -> String {
        return String(CSLRfidAppEngine.shared().readerInfo.batteryPercentage)
    }
    
    static func onLoadInventory() {
        if !CSLHelper.isDeviceConnected() {
            return
        }
        CSLRfidAppEngine.shared().reader.selectAntennaPort(0)
        CSLRfidAppEngine.shared().reader.setAntennaConfig(true, inventoryMode: 0, inventoryAlgo: 0, startQ: 0, profileMode: 0, profile: 0, frequencyMode: 0, frequencyChannel: 0, isEASEnabled: false)
        CSLRfidAppEngine.shared().reader.setPower(30)
        CSLRfidAppEngine.shared().reader.setAntennaDwell(2000)
        CSLRfidAppEngine.shared().reader.setAntennaInventoryCount(0)
        return
        var isMQTTConnected = false
        
        CSLRfidAppEngine.shared().reader.filteredBuffer.removeAllObjects()
        if CSLRfidAppEngine.shared().mqttSettings.isMQTTEnabled {
            self.transport = MQTTCFSocketTransport()
            transport?.host = CSLRfidAppEngine.shared().mqttSettings.brokerAddress
            transport?.port = UInt32(CSLRfidAppEngine.shared().mqttSettings.brokerPort)
            transport?.tls = CSLRfidAppEngine.shared().mqttSettings.isTLSEnabled

            session = MQTTSession()
            session?.transport = transport
            session?.userName = CSLRfidAppEngine.shared().mqttSettings.userName
            session?.password = CSLRfidAppEngine.shared().mqttSettings.password
            session?.keepAliveInterval = 60
            session?.clientId = CSLRfidAppEngine.shared().mqttSettings.clientId
            session?.willFlag = true
            session?.willMsg = "offline".data(using: .utf8)
            session?.willTopic = "devices/\(CSLRfidAppEngine.shared().mqttSettings.clientId)/messages/events/"
            session?.willQoS = MQTTQosLevel(rawValue: UInt8(CSLRfidAppEngine.shared().mqttSettings.qoS))!
            session?.willRetainFlag = CSLRfidAppEngine.shared().mqttSettings.retained


            session?.connect(connectHandler: { error in
                if error == nil {
                    print("Connected to MQTT Broker")
                    let alert = UIAlertController(title: "MQTT broker", message: "Connected", preferredStyle: .alert)
                    let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alert.addAction(ok)
                    isMQTTConnected = true
                } else {
                    print("Fail connecting to MQTT Broker")
                    let alert = UIAlertController(title: "MQTT broker", message: "Error: \(error.debugDescription)", preferredStyle: .alert)
                    let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alert.addAction(ok)
                    isMQTTConnected = false
                }
            })
        }
    }
    
    static func onExitInventory() {
        if !CSLHelper.isDeviceConnected() {
            return
        }
        CSLRfidAppEngine.shared().isBarcodeMode = false
    }
    
    static func onStartBarcodeInventory() {
        CSLRfidAppEngine.shared().soundAlert(1033)
        CSLRfidAppEngine.shared().reader.startBarcodeReading()
    }
    
    static func onStopBarcodeInventory() {
        CSLRfidAppEngine.shared().soundAlert(1033)
        CSLRfidAppEngine.shared().reader.stopBarcodeReading()
    }
    
    static func onStartRFIDInventory() {
        CSLRfidAppEngine.shared().soundAlert(1033)
        CSLRfidAppEngine.shared().reader.setPowerMode(false)
        CSLRfidAppEngine.shared().reader.startInventory()
    }
    
    static func onStopRFIDInventory() -> Bool {
        CSLRfidAppEngine.shared().soundAlert(1033)
        return CSLRfidAppEngine.shared().reader.stopInventory()
    }
    
    static func onClear(cslvalues: CSLValues) {
        if CSLHelper.isDeviceConnected() {
            CSLRfidAppEngine.shared().reader.filteredBuffer.removeAllObjects()            
        }
        cslvalues.readings = []
    }
    
}
