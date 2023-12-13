//
//  ZebraSingleton.swift
//  FractalInventory
//
//  Created by Miguel Mexicano Herrera on 12/12/23.
//

import Foundation
import BugfenderSDK
class ZebraSingleton: NSObject {
    static var shared: ZebraSingleton = {
        let instance = ZebraSingleton()
        return instance
    }()
    private let apiInstance: srfidISdkApi = srfidSdkFactory.createRfidSdkApiInstance()
    private var available_readers: NSMutableArray? = NSMutableArray()
    private var active_readers: NSMutableArray? = NSMutableArray()
    @Published var listDevices: [RFIDDevice] = []
    @Published var batteryLevel: String = ""
    @Published var serialNumber: String = ""
    @Published var antenaPower: Double = 0
    @Published var isDeviceConnectedZebra: Bool = false
    @Published var selectedZebraDevice: RFIDDevice = .empty
    @Published var currentReaderID: Int32 = -1
    
    private override init() {
        super.init()
        apiInstance.srfidSetDelegate(self)
        setupSDK()
    }
    func setupSDK() {
        apiInstance.srfidSubsribe(forEvents: Int32(SRFID_EVENT_MASK_READ | SRFID_EVENT_MASK_STATUS))
        apiInstance.srfidSubsribe(forEvents: Int32(SRFID_EVENT_MASK_BATTERY | SRFID_EVENT_MASK_TRIGGER))
        apiInstance.srfidSetOperationalMode(Int32(SRFID_OPMODE_MFI))
        apiInstance.srfidSubsribe(forEvents: Int32(SRFID_EVENT_MASK_READ))
        apiInstance.srfidSubsribe(forEvents: Int32(SRFID_EVENT_MASK_STATUS))
        
        apiInstance.srfidSubsribe(forEvents: Int32(SRFID_EVENT_READER_APPEARANCE | SRFID_EVENT_READER_DISAPPEARANCE))
        apiInstance.srfidEnableAvailableReadersDetection(true)
        
        apiInstance.srfidSubsribe(forEvents: Int32(SRFID_EVENT_SESSION_ESTABLISHMENT | SRFID_EVENT_SESSION_TERMINATION))
        apiInstance.srfidEnableAutomaticSessionReestablishment(true)
        apiInstance.srfidSubsribe(forEvents: Int32(SRFID_EVENT_MASK_BATTERY))
        
        bfprint("setupSDK Start")
        available_readers = NSMutableArray()
        active_readers = NSMutableArray()
        apiInstance.srfidGetAvailableReadersList(&available_readers)
        apiInstance.srfidGetActiveReadersList(&active_readers)
        bfprint("setupSDK available_readers count: = \(available_readers?.count ?? 0)")
        bfprint("setupSDK active_readers count: = \(active_readers?.count ?? 0)")
        updateList(readers: available_readers)
        updateList(readers: active_readers)
        bfprint("setupSDK End")
    }
    func rapidRead(readerID: Int32) {
        var start_trigger_cfg: srfidStartTriggerConfig? = srfidStartTriggerConfig()
        var stop_trigger_cfg: srfidStopTriggerConfig? = srfidStopTriggerConfig()
        let report_cfg: srfidReportConfig = srfidReportConfig()
        let access_cfg: srfidAccessConfig = srfidAccessConfig()
        var error_response: NSString? = nil
        
        start_trigger_cfg?.setStartOnHandheldTrigger(false)
        start_trigger_cfg?.setStartDelay(0)
        start_trigger_cfg?.setRepeatMonitoring(false)
        
        stop_trigger_cfg?.setStopOnHandheldTrigger(false)
        stop_trigger_cfg?.setStopOnTimeout(false)
        stop_trigger_cfg?.setStopOnTagCount(false)
        stop_trigger_cfg?.setStopOnInventoryCount(false)
        stop_trigger_cfg?.setStopOnAccessCount(false)
        var result = apiInstance.srfidGetStartTriggerConfiguration(readerID, aStartTriggeConfig: &start_trigger_cfg, aStatusMessage: &error_response)
        if result == SRFID_RESULT_SUCCESS {
            print("Start trigger configuration has been set")
        } else {
            print("Failed to set start trigger parameters")
        }
        result = apiInstance.srfidGetStopTriggerConfiguration(readerID, aStopTriggeConfig: &stop_trigger_cfg, aStatusMessage: &error_response)
        if result == SRFID_RESULT_SUCCESS {
            print("Stop trigger configuration has been set")
        } else {
            print("Failed to set stop trigger parameters")
        }
        error_response = nil
        report_cfg.setIncPC(true)
        report_cfg.setIncPhase(true)
        report_cfg.setIncChannelIndex(true)
        report_cfg.setIncRSSI(true)
        report_cfg.setIncTagSeenCount(false)
        report_cfg.setIncFirstSeenTime(false)
        report_cfg.setIncLastSeenTime(false)
        
        access_cfg.setPower(270)
        access_cfg.setDoSelect(false)
        
        result = apiInstance.srfidStartRapidRead(readerID, aReportConfig: report_cfg, aAccessConfig: access_cfg, aStatusMessage: &error_response)
        if result == SRFID_RESULT_SUCCESS {
            print("Request succeed")
            let seconds = 60.0
            DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
                self.apiInstance.srfidStopRapidRead(readerID, aStatusMessage: nil)
            }
        } else if result == SRFID_RESULT_RESPONSE_ERROR {
            print("Error response from RFID reader: \(error_response ?? "")")
        } else {
            print("Request failed")
        }
    }
    private func updateList(readers: NSMutableArray?) {
        (readers ?? []).forEach { item in
            if let device = item as? srfidReaderInfo {
                guard !listDevices.contains(where: { $0.id == device.getReaderID() }) else {
                    bfprint("device exist: \(device.getReaderID())")
                    return
                }
                listDevices.append(RFIDDevice(id: device.getReaderID(),
                                              name: device.getReaderName(),
                                              type: device.isActive() ? .active : .available))
                bfprint("RFID reader is \(device.isActive() ? "active" : "available"): ID = \(device.getReaderID()) name = \(device.getReaderName() ?? "")")
            } else {
                bfprint("srfidReaderInfo nil")
            }
        }
    }
    func establishCommunication(readerID: Int32) {
        bfprint("establishCommunication: ID = \(readerID)")
        apiInstance.srfidEstablishCommunicationSession(readerID)
    }
    func endCommunication(readerID: Int32) {
        bfprint("endCommunication: ID = \(readerID)")
        apiInstance.srfidTerminateCommunicationSession(readerID)
    }
    
    private func connect(readerID: Int32) {
        bfprint("connect: ID = \(readerID)")
        //let password = "ascii password"
        let result = apiInstance.srfidEstablishAsciiConnection(readerID, aPassword: nil)
        if result == SRFID_RESULT_SUCCESS {
            self.isDeviceConnectedZebra = true
            bfprint("ASCII connection has been established")
            batteryStatus(readerID: readerID)
            getCapabilities(readerID: readerID)
            rapidRead(readerID: readerID)
            currentReaderID = readerID
            antenaConfiguration(readerID: readerID)
        } else if SRFID_RESULT_WRONG_ASCII_PASSWORD == result {
            bfprint("Incorrect ASCII connection password")
        } else {
            bfprint("Failed to establish ASCII connection")
        }
    }
    func getCapabilities(readerID: Int32) {
        var capabilities: srfidReaderCapabilitiesInfo? = srfidReaderCapabilitiesInfo()
        var error_response: NSString?
        let result: SRFID_RESULT = apiInstance.srfidGetReaderCapabilitiesInfo(readerID, aReaderCapabilitiesInfo: &capabilities, aStatusMessage: &error_response)
        if SRFID_RESULT_SUCCESS == result {
            guard let capabilities = capabilities else {
                return
            }
            serialNumber = "Serial number: \(capabilities.getSerialNumber() ?? "")"
            bfprint("Serial number: \(capabilities.getSerialNumber() ?? "")")
            bfprint("Model: \(capabilities.getModel() ?? "")")
            bfprint("Manufacturer: \(capabilities.getManufacturer() ?? "")")
            bfprint("Manufacturing date: \(capabilities.getManufacturingDate() ?? "")")
            bfprint("Scanner name: \(capabilities.getScannerName() ?? "")")
            bfprint("Ascii version: \(capabilities.getAsciiVersion() ?? "")")
            bfprint("Air version: \(capabilities.getAirProtocolVersion() ?? "")")
            bfprint("Bluetooth address: \(capabilities.getBDAddress() ?? "")")
            bfprint("Select filters number: \(capabilities.getSelectFilterNum())")
            bfprint("Max access sequence: \(capabilities.getMaxAccessSequence())")
            bfprint("Power level: min = \(capabilities.getMinPower()); max = \(capabilities.getMaxPower()); step = \(capabilities.getPowerStep())")
        } else if SRFID_RESULT_RESPONSE_ERROR == result {
            bfprint("getCapabilities: Error response from RFID reader: \(error_response ?? "")")
        } else if SRFID_RESULT_RESPONSE_TIMEOUT == result {
            bfprint("getCapabilities: Timeout occurs during communication with RFID reader")
        } else if SRFID_RESULT_READER_NOT_AVAILABLE == result {
            bfprint("getCapabilities: RFID reader with id = %d is not available \(readerID)")
        } else {
            bfprint("getCapabilities: Request failed")
        }
    }
    func batteryStatus(readerID: Int32) {
        let result = apiInstance.srfidRequestBatteryStatus(readerID)
        if SRFID_RESULT_SUCCESS == result {
            bfprint("batteryStatus: Request succeed")
        } else {
            bfprint("batteryStatus: Request failed")
        }
    }
    func antenaConfiguration(readerID: Int32) {
        var antenna_cfg: srfidAntennaConfiguration? = srfidAntennaConfiguration()
        var error_response: NSString?
        let result = apiInstance.srfidGetAntennaConfiguration(readerID, aAntennaConfiguration: &antenna_cfg, aStatusMessage: &error_response)
        if SRFID_RESULT_SUCCESS == result {
            guard let antenna_cfg = antenna_cfg else {
                return
            }
            let power: Double = Double(antenna_cfg.getPower())
            let linkProfileIdx = antenna_cfg.getLinkProfileIdx()
            let antenaTari = antenna_cfg.getTari()
            let prefilters = antenna_cfg.getDoSelect()
            bfprint("antenaConfiguration: Antenna power level: \(power/10.0)")
            antenaPower = power/10.0
            bfprint("antenaConfiguration: Antenna RF mode index: \(linkProfileIdx)")
            bfprint("antenaConfiguration: Antenna tari: \(antenaTari)")
            bfprint("antenaConfiguration: Antenna pre-filters application \(prefilters == false ? "No" : "Si")")
        } else if SRFID_RESULT_RESPONSE_ERROR == result {
            bfprint("antenaConfiguration: Error response from RFID reader: \(error_response ?? "")")
        } else if SRFID_RESULT_RESPONSE_TIMEOUT == result {
            bfprint("antenaConfiguration: Timeout occurs during communication with RFID reader")
        } else if SRFID_RESULT_READER_NOT_AVAILABLE == result {
            bfprint("antenaConfiguration: RFID reader with id = %d is not available \(readerID)")
        } else {
            bfprint("antenaConfiguration: Request failed")
        }
    }
    /// Metodo para obtener el perfil
    /// RfMode, Min Tari, Max Tari, step Tari
    func getProfile(readerID: Int32) -> srfidLinkProfile? {
        var profiles: NSMutableArray?
        var error_response: NSString?
        let result = apiInstance.srfidGetSupportedLinkProfiles(readerID, aLinkProfilesList: &profiles, aStatusMessage: &error_response)
        if SRFID_RESULT_SUCCESS == result {
            if let profiles = profiles, profiles.count > 0 {
                let profile = profiles.lastObject as? srfidLinkProfile
                return profile
            }
        } else {
            bfprint("getProfile: Request failed")
        }
        return nil
    }
}
extension ZebraSingleton: ObservableObject {
}
extension ZebraSingleton: srfidISdkApiDelegate {
    func srfidEventReaderAppeared(_ availableReader: srfidReaderInfo!) {
        listDevices.removeAll()
        bfprint("RFID reader has appeared: ID = \(availableReader.getReaderID()) name = \(availableReader.getReaderName() ?? "")")
        apiInstance.srfidGetAvailableReadersList(&available_readers)
        apiInstance.srfidGetActiveReadersList(&active_readers)
        bfprint("available_readers count: = \(available_readers?.count ?? 0)")
        bfprint("active_readers count: = \(active_readers?.count ?? 0)")
        updateList(readers: available_readers)
        updateList(readers: active_readers)
    }
    
    func srfidEventReaderDisappeared(_ readerID: Int32) {
        bfprint("RFID reader has disappeared: ID = \(readerID)")
    }
    
    func srfidEventCommunicationSessionEstablished(_ activeReader: srfidReaderInfo!) {
        let readerID = activeReader.getReaderID()
        bfprint("RFID reader has connected: ID = \(readerID) name = \(activeReader.getReaderName() ?? "")")
        self.connect(readerID: readerID)
    }
    
    func srfidEventCommunicationSessionTerminated(_ readerID: Int32) {
        bfprint("RFID reader has disconnected: ID = \(readerID)")
        self.isDeviceConnectedZebra = false
        serialNumber = ""
        batteryLevel = ""
    }
    
    func srfidEventReadNotify(_ readerID: Int32, aTagData tagData: srfidTagData!) {
        print("Tag data received from RFID reader with ID = \(readerID)")
        print("Tag id: \(tagData.getTagId() ?? "")")
    }
    
    func srfidEventStatusNotify(_ readerID: Int32, aEvent event: SRFID_EVENT_STATUS, aNotification notificationData: Any!) {
        let status = event == SRFID_EVENT_STATUS_OPERATION_START ? "started" : "stopped"
        print("Radio operation has \(status)")
    }
    
    func srfidEventProximityNotify(_ readerID: Int32, aProximityPercent proximityPercent: Int32) {
    }
    
    func srfidEventMultiProximityNotify(_ readerID: Int32, aTagData tagData: srfidTagData!) {
    }
    
    func srfidEventTriggerNotify(_ readerID: Int32, aTriggerEvent triggerEvent: SRFID_TRIGGEREVENT) {
    }
    
    func srfidEventBatteryNotity(_ readerID: Int32, aBatteryEvent batteryEvent: srfidBatteryEvent!) {
        bfprint("Battery status event received from RFID reader with ID = \(readerID)")
        bfprint("Battery level: \(batteryEvent.getPowerLevel())")
        batteryLevel = "\(batteryEvent.getPowerLevel())"
        bfprint("Charging: \(batteryEvent.getIsCharging() == false ? "NO" : "SI")")
        bfprint("Event cause: \(batteryEvent.getCause() ?? "")")
    }
}
