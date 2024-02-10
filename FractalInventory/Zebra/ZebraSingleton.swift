//
//  ZebraSingleton.swift
//  FractalInventory
//
//  Created by Miguel Mexicano Herrera on 12/12/23.
//
/// Nota: Los NSMutableArrays siempre deben inicializarse para obtener el valor
import Foundation
import BugfenderSDK
final class ZebraSingleton: NSObject {
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
    @Published var antennaConfiguration: srfidAntennaConfiguration?
    @Published var antennaCapabilities: srfidReaderCapabilitiesInfo?
    var isScanning: Bool = false
    
    var onTagAdded: ((EpcModel) -> Void) = { _ in }
    
    // MARK: Inicialización y setup
    private override init() {
        super.init()
        apiInstance.srfidSetDelegate(self)
        setupSDK()
    }
    func subscribeReadEvent() {
        apiInstance.srfidSubsribe(forEvents: Int32(SRFID_EVENT_MASK_READ))
        apiInstance.srfidSubsribe(forEvents: Int32(SRFID_EVENT_MASK_STATUS))
    }
    /// Configuración inicial del dispositivo
    func setupSDK() {
        subscribeReadEvent()
        apiInstance.srfidSubsribe(forEvents: Int32(SRFID_EVENT_MASK_BATTERY | SRFID_EVENT_MASK_TRIGGER))
        apiInstance.srfidSetOperationalMode(Int32(SRFID_OPMODE_MFI))
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
        bfprint("setupSDK End")
    }
    // MARK: Funciones para Listar Devices
    /// Función para saber si hay un dispositivo conectado
    func isAvailable() -> Bool {
        return currentReaderID != -1
    }
    /// Actualizar lista de dispositivos
    /// - Parameter readers: listas de dispositivos disponibles y activos.
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
    // MARK: Funciones para Conectar
    /// Establecer la comunicación con un RFID
    func establishCommunication(readerID: Int32) {
        bfprint("establishCommunication: ID = \(readerID)")
        apiInstance.srfidEstablishCommunicationSession(readerID)
    }
    /// Conectar con un RFID
    /// - Parameter readerID: id del dispositivo a conectar.
    private func connect(readerID: Int32) {
        let result = apiInstance.srfidEstablishAsciiConnection(readerID, aPassword: nil)
        if result == SRFID_RESULT_SUCCESS {
            currentReaderID = readerID
            self.isDeviceConnectedZebra = true
            requestBatteryStatus(readerID: readerID)
            antennaCapabilities = getCapabilities(readerID: readerID)
            antennaConfiguration = antenaConfiguration(readerID: readerID)
        } else if SRFID_RESULT_WRONG_ASCII_PASSWORD == result {
            bfprint("Incorrect ASCII connection password")
        } else {
            bfprint("Failed to establish ASCII connection")
        }
    }
    // MARK: Funciones para Desconectar
    /// Terminar la comunicación con un RFID
    func endCommunication(readerID: Int32) {
        bfprint("endCommunication: ID = \(readerID)")
        apiInstance.srfidTerminateCommunicationSession(readerID)
    }
    //MARK: Funciones de Lectura
    /// Lectura Rapida
    /// - Parameter readerID: id del dispositivo para lectura rápida.
    func rapidRead(readerID: Int32) {
        var start_trigger_cfg: srfidStartTriggerConfig? = srfidStartTriggerConfig()
        var stop_trigger_cfg: srfidStopTriggerConfig? = srfidStopTriggerConfig()
        let report_cfg: srfidReportConfig = srfidReportConfig()
        let access_cfg: srfidAccessConfig = srfidAccessConfig()
        var error_response: NSString? = nil
        /// Start
        start_trigger_cfg?.setStartOnHandheldTrigger(false)
        start_trigger_cfg?.setStartDelay(0)
        start_trigger_cfg?.setRepeatMonitoring(false)
        /// Stop
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
    func startInventory() {
        startInventory(readerID: currentReaderID)
    }
    func startInventory(readerID: Int32) {
        subscribeReadEvent()
        var error_response: NSString? = nil
        /// Start
        let start_trigger_cfg = startTriggerInventory()
        var result = apiInstance.srfidSetStartTriggerConfiguration(readerID, aStartTriggeConfig: start_trigger_cfg, aStatusMessage: &error_response)
        if result == SRFID_RESULT_SUCCESS {
            print("Start trigger configuration has been set")
        } else {
            print("Failed to set start trigger parameters")
        }
        /// Stop
        var stop_trigger_cfg = stopTriggerInventory()
        result = apiInstance.srfidGetStopTriggerConfiguration(readerID, aStopTriggeConfig: &stop_trigger_cfg, aStatusMessage: &error_response)
        if result == SRFID_RESULT_SUCCESS {
            print("Stop trigger configuration has been set")
        } else {
            print("Failed to set stop trigger parameters")
        }
        /// Report Configuration
        let report_cfg = reportConfigurationInventory()
        /// Access Configuration
        let access_cfg: srfidAccessConfig = srfidAccessConfig()
        access_cfg.setPower(270)
        access_cfg.setDoSelect(false)
        /// Start inventory
        result = apiInstance.srfidStartInventory(readerID, aMemoryBank: SRFID_MEMORYBANK_EPC, aReportConfig: report_cfg, aAccessConfig: access_cfg, aStatusMessage: &error_response)
        switch result {
        case SRFID_RESULT_SUCCESS:
            print("Request succeed")
            let seconds = 60.0
            DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
                self.apiInstance.srfidStopRapidRead(readerID, aStatusMessage: nil)
            }
        case SRFID_RESULT_RESPONSE_ERROR:
            print("Error response from RFID reader: \(error_response ?? "")")
        default:
            print("Request failed")
        }
    }
    func stopTriggerInventory() -> srfidStopTriggerConfig? {
        let stop_trigger_cfg: srfidStopTriggerConfig = srfidStopTriggerConfig()
        stop_trigger_cfg.setStopOnHandheldTrigger(true)
        stop_trigger_cfg.setTriggerType(SRFID_TRIGGERTYPE_RELEASE)
        stop_trigger_cfg.setStopOnTimeout(true)
        stop_trigger_cfg.setStopTimout(25*1000)
        stop_trigger_cfg.setStopOnTagCount(false)
        stop_trigger_cfg.setStopOnInventoryCount(false)
        stop_trigger_cfg.setStopOnAccessCount(false)
        return stop_trigger_cfg
    }
    func startTriggerInventory() -> srfidStartTriggerConfig {
        let start_trigger_cfg: srfidStartTriggerConfig = srfidStartTriggerConfig()
        start_trigger_cfg.setStartOnHandheldTrigger(true)
        start_trigger_cfg.setTriggerType(SRFID_TRIGGERTYPE_PRESS)
        start_trigger_cfg.setStartDelay(0)
        start_trigger_cfg.setRepeatMonitoring(true)
        return start_trigger_cfg
    }
    func reportConfigurationInventory() -> srfidReportConfig {
        let report_cfg: srfidReportConfig = srfidReportConfig()
        report_cfg.setIncPC(false)
        report_cfg.setIncPhase(false)
        report_cfg.setIncChannelIndex(true)
        report_cfg.setIncRSSI(true)
        report_cfg.setIncTagSeenCount(false)
        report_cfg.setIncFirstSeenTime(false)
        report_cfg.setIncLastSeenTime(false)
        return report_cfg
    }
    func startScanning(readerID: Int32) {
        let start_trigger_cfg = srfidStartTriggerConfig()
        let stop_trigger_cfg = srfidStopTriggerConfig()
        let report_cfg: srfidReportConfig = srfidReportConfig()
        let access_cfg: srfidAccessConfig = srfidAccessConfig()
        var error_response: NSString?
        var result = apiInstance.srfidStartRapidRead(readerID, aReportConfig: report_cfg, aAccessConfig: access_cfg, aStatusMessage: &error_response)
        switch result {
        case SRFID_RESULT_SUCCESS:
            print("Request succeed")
            isScanning = true
        case SRFID_RESULT_RESPONSE_ERROR:
            print("Error response from RFID reader: \(error_response ?? "")")
            isScanning = false
        default:
            print("Request failed")
            isScanning = false
        }
    }
    func stopTriggerScanning() -> srfidStopTriggerConfig? {
        let stop_trigger_cfg: srfidStopTriggerConfig = srfidStopTriggerConfig()
        stop_trigger_cfg.setStopOnHandheldTrigger(true)
        stop_trigger_cfg.setTriggerType(SRFID_TRIGGERTYPE_RELEASE)
        stop_trigger_cfg.setStopOnTimeout(true)
        stop_trigger_cfg.setStopTimout(25*1000)
        stop_trigger_cfg.setStopOnTagCount(false)
        stop_trigger_cfg.setStopOnInventoryCount(false)
        stop_trigger_cfg.setStopOnAccessCount(false)
        return stop_trigger_cfg
    }
    func startTriggerScanning() -> srfidStartTriggerConfig {
        let start_trigger_cfg: srfidStartTriggerConfig = srfidStartTriggerConfig()
        start_trigger_cfg.setStartOnHandheldTrigger(true)
        start_trigger_cfg.setTriggerType(SRFID_TRIGGERTYPE_PRESS)
        start_trigger_cfg.setStartDelay(0)
        start_trigger_cfg.setRepeatMonitoring(true)
        return start_trigger_cfg
    }
    func reportConfigurationScanning() -> srfidReportConfig {
        let report_cfg: srfidReportConfig = srfidReportConfig()
        report_cfg.setIncPC(false)
        report_cfg.setIncPhase(false)
        report_cfg.setIncChannelIndex(true)
        report_cfg.setIncRSSI(true)
        report_cfg.setIncTagSeenCount(false)
        report_cfg.setIncFirstSeenTime(false)
        report_cfg.setIncLastSeenTime(false)
        return report_cfg
    }
    // MARK: Funciones para solicitar información del dispositivo
    /// Solicitar el estatus de la bateria.
    func requestBatteryStatus(readerID: Int32) {
        let result = apiInstance.srfidRequestBatteryStatus(readerID)
        if SRFID_RESULT_SUCCESS == result {
            bfprint("batteryStatus: Request succeed")
        } else {
            bfprint("batteryStatus: Request failed")
        }
    }
    func reportConfiguration(readerID: Int32) -> srfidTagReportConfig?  {
        var report_cfg: srfidTagReportConfig? = srfidTagReportConfig()
        var error_response: NSString?
        let result = apiInstance.srfidGetTagReportConfiguration(readerID, aTagReportConfig: &report_cfg, aStatusMessage: &error_response)
        switch result {
        case SRFID_RESULT_SUCCESS:
            guard let report_cfg = report_cfg else {
                return nil
            }
            let incPC: String = report_cfg.getIncPC() == false ? "off" : "on"
            print("PC field: \(incPC) ")
            let IncPhase: String = report_cfg.getIncPhase() == false ? "off" : "on"
            print("Phase field: \(IncPhase) ")
            let IncChannelIdx: String = report_cfg.getIncChannelIdx() == false ? "off" : "on"
            print("Channel index field: \(IncChannelIdx) ")
            let IncRSSI: String = report_cfg.getIncRSSI() == false ? "off" : "on"
            print("RSSI field: \(IncRSSI) ")
            let IncTagSeenCount: String = report_cfg.getIncTagSeenCount() == false ? "off" : "on"
            print("Tag seen count field: \(IncTagSeenCount) ")
            let IncFirstSeenTime: String = report_cfg.getIncFirstSeenTime() == false ? "off" : "on"
            print("Tag seen count field: \(IncFirstSeenTime) ")
            let IncLastSeenTime: String = report_cfg.getIncLastSeenTime() == false ? "off" : "on"
            print("Tag seen count field: \(IncLastSeenTime) ")
            return report_cfg
        default:
            print("Failed to receive tag report parameters")
            return nil
        }
    }
    func regulatoryConfiguration(readerID: Int32) {
        var regulatory_cfg: srfidRegulatoryConfig? = srfidRegulatoryConfig()
        var error_response: NSString?
        let result = apiInstance.srfidGetRegulatoryConfig(readerID, aRegulatoryConfig: &regulatory_cfg, aStatusMessage: &error_response)
        if result == SRFID_RESULT_SUCCESS {
            guard let regulatory_cfg = regulatory_cfg else {
                return
            }
            let regionCode = regulatory_cfg.getRegionCode()
            print("Código de region: \(regionCode ?? "")")
            let hopping_cfg = regulatory_cfg.getHoppingConfig()
            print("Hopping is: \(hopping_cfg == SRFID_HOPPINGCONFIG_DISABLED ? "off" : "on")")
            if let channels = regulatory_cfg.getEnabledChannelsList() {
                print("canales: \(channels)")
            }
        } else {
            print("Failed to receive regulatory parameters")
        }
    }
    // MARK: Funciones para obtener información del dispositivo
    func getPreFilters(readerID: Int32) -> [srfidPreFilter]? {
        var preFilters: NSMutableArray? = NSMutableArray()
        var error_response: NSString?
        let result = apiInstance.srfidGetPreFilters(readerID, aPreFilters: &preFilters, aStatusMessage: &error_response)
        if result == SRFID_RESULT_SUCCESS {
            guard let preFilters = preFilters as? [srfidPreFilter] else {
                return nil
            }
            return preFilters
        } else {
            return nil
        }
    }
    /// Obtener el Nivel de Poder de la Antena
    func getPowerLevel() -> Double {
        /// Validar si existe un dispositivo Zebra conectado
        let currentID = currentReaderID
        if  currentID != -1 {
            let antennaConfiguration = antennaConfiguration
            let currentPower = antennaConfiguration?.getPower()
            return Double(currentPower ?? 0)
        } else {
            return 30
        }
    }
    /// Obtener el Maximo nivel de Poder de la Antena
    func getMaxPower() -> Double {
        if currentReaderID != -1 {
            let capabilities = getCapabilities()
            return Double(capabilities.maxPower)
        } else {
            return 30
        }
    }
    /// Obtener las capacidades de la antena
    func getCapabilities() -> RFIDCapabilities {
        let capabilities = antennaCapabilities
        let minPower = capabilities?.getMinPower() ?? 0
        let maxPower = capabilities?.getMaxPower() ?? 0
        let step = capabilities?.getPowerStep() ?? 0
        let rfidCapabilities = RFIDCapabilities(maxPower: Int(maxPower), minPower: Int(minPower), steps: Int(step))
        return rfidCapabilities
    }
    /// Funcion para obtener los atributos de una Antena RFID
    func getCapabilities(readerID: Int32) -> srfidReaderCapabilitiesInfo? {
        var capabilities: srfidReaderCapabilitiesInfo? = srfidReaderCapabilitiesInfo()
        var error_response: NSString?
        let result: SRFID_RESULT = apiInstance.srfidGetReaderCapabilitiesInfo(readerID, aReaderCapabilitiesInfo: &capabilities, aStatusMessage: &error_response)
        if SRFID_RESULT_SUCCESS == result {
            guard let capabilities = capabilities else {
                return nil
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
            return capabilities
        } else if SRFID_RESULT_RESPONSE_ERROR == result {
            bfprint("getCapabilities: Error response from RFID reader: \(error_response ?? "")")
        } else if SRFID_RESULT_RESPONSE_TIMEOUT == result {
            bfprint("getCapabilities: Timeout occurs during communication with RFID reader")
        } else if SRFID_RESULT_READER_NOT_AVAILABLE == result {
            bfprint("getCapabilities: RFID reader with id = %d is not available \(readerID)")
        } else {
            bfprint("getCapabilities: Request failed")
        }
        return nil
    }
    /// Función para obtener el perfil RfMode, Min Tari, Max Tari, step Tari
    /// - Parameter readerID: id del Lector
    /// - Returns: retorna el perfil del RFID
    func getProfile(readerID: Int32) -> srfidLinkProfile? {
        var profiles: NSMutableArray? = NSMutableArray()
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
    func getBeepConfiguration(readerID: Int32) {
        var beeper_cfg: SRFID_BEEPERCONFIG = SRFID_BEEPERCONFIG(0)
        var error_response: NSString?
        let result = apiInstance.srfidGetBeeperConfig(readerID, aBeeperConfig: &beeper_cfg, aStatusMessage: &error_response)
        if result == SRFID_RESULT_SUCCESS {
            switch beeper_cfg {
            case SRFID_BEEPERCONFIG_HIGH:
                print("Beeper: high volume")
            case SRFID_BEEPERCONFIG_LOW:
                print("Beeper: low volume")
            case SRFID_BEEPERCONFIG_MEDIUM:
                print("Beeper: medium volume")
            case SRFID_BEEPERCONFIG_QUIET:
                print("Beeper: disabled")
            default:
                break
            }
        } else {
            print("Failed to receive beeper parameters")
        }
    }
    func updateBeepConfiguration(readerID: Int32, aBeeperConfig: SRFID_BEEPERCONFIG) {
        var error_response: NSString?
        let result = apiInstance.srfidSetBeeperConfig(readerID, aBeeperConfig: aBeeperConfig, aStatusMessage: &error_response)
        switch result {
        case SRFID_RESULT_SUCCESS:
            print("Beeper configuration has been set")
        case SRFID_RESULT_RESPONSE_ERROR:
            print("Error response from RFID reader \(error_response ?? "")")
        default:
            print("Failed to set beeper configuration")
        }
    }
    /// Función para obtener la configuración de la antena.
    /// - Parameter readerID: Id del lector.
    /// - Returns: Configuración del la antena.
    func antenaConfiguration(readerID: Int32) -> srfidAntennaConfiguration? {
        var antenna_cfg: srfidAntennaConfiguration? = srfidAntennaConfiguration()
        var error_response: NSString?
        let result = apiInstance.srfidGetAntennaConfiguration(readerID, aAntennaConfiguration: &antenna_cfg, aStatusMessage: &error_response)
        if SRFID_RESULT_SUCCESS == result {
            guard let antenna_cfg = antenna_cfg else {
                return nil
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
            return antenna_cfg
        } else if SRFID_RESULT_RESPONSE_ERROR == result {
            bfprint("antenaConfiguration: Error response from RFID reader: \(error_response ?? "")")
        } else if SRFID_RESULT_RESPONSE_TIMEOUT == result {
            bfprint("antenaConfiguration: Timeout occurs during communication with RFID reader")
        } else if SRFID_RESULT_READER_NOT_AVAILABLE == result {
            bfprint("antenaConfiguration: RFID reader with id = %d is not available \(readerID)")
        } else {
            bfprint("antenaConfiguration: Request failed")
        }
        return nil
    }
    // MARK: Funciones para modificar Antena
    func updateReportConfiguration(readerID: Int32, report_cfg: srfidTagReportConfig) {
        var error_response: NSString?
        let result = apiInstance.srfidSetTagReportConfiguration(readerID, aTagReportConfig: report_cfg, aStatusMessage: &error_response)
        if result == SRFID_RESULT_SUCCESS {
            print("Tag report configuration has been set")
        } else {
            print("Failed to set tag report parameters")
        }
    }
    func updateRegulatoryConfiguration(readerID: Int32, regulatory_cfg: srfidRegulatoryConfig) {
        var error_response: NSString?
        let result = apiInstance.srfidSetRegulatoryConfig(readerID, aRegulatoryConfig: regulatory_cfg, aStatusMessage: &error_response)
        if result == SRFID_RESULT_SUCCESS {
            print("Tag report configuration has been set")
        } else {
            print("Error response from RFID reader: \(error_response ?? "")")
        }
    }
    /// Función para actualizar la potencia de la antena
    /// - Parameter power: power de la antena en dBm
    func updateAntennaPower(power: Double) {
        let readerID = currentReaderID
        let antennaNewConfiguration = antennaConfiguration
        antennaNewConfiguration?.setPower(Int16(power))
        var error_response: NSString?
        let result = apiInstance.srfidSetAntennaConfiguration(readerID, aAntennaConfiguration: antennaNewConfiguration, aStatusMessage: &error_response)
        switch result {
        case SRFID_RESULT_SUCCESS:
            print("Update Success")
        case SRFID_RESULT_RESPONSE_ERROR:
            print("Error response from RFID reader: \(error_response ?? "")")
        default:
            break
        }
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
    /// Funcion que notifica el fin de la session.
    func srfidEventCommunicationSessionTerminated(_ readerID: Int32) {
        bfprint("RFID reader has disconnected: ID = \(readerID)")
        self.isDeviceConnectedZebra = false
        serialNumber = ""
        batteryLevel = ""
        currentReaderID = -1
    }
    /// Función para indicar lectura de un RFID
    func srfidEventReadNotify(_ readerID: Int32, aTagData tagData: srfidTagData!) {
        print("Tag data received from RFID reader with ID = \(readerID)")
        print("Tag id: \(tagData.getTagId() ?? "")")
        let tagId = tagData.getTagId() ?? ""
        let epc = EpcModel(epc: tagId, rssi: "", timestamp: Utils.getFullDate())
        onTagAdded(epc)
        /// Inventory
        ///let bank: SRFID_MEMORYBANK = tagData.getMemoryBank()
//        switch bank {
//        case SRFID_MEMORYBANK_NONE:
//
//        }
    }
    /// Función que indica que el RFID empezó a funcionar
    func srfidEventStatusNotify(_ readerID: Int32, aEvent event: SRFID_EVENT_STATUS, aNotification notificationData: Any!) {
        let status = event == SRFID_EVENT_STATUS_OPERATION_START ? "started" : "stopped"
        print("Radio operation has \(status)")
    }
    
    func srfidEventProximityNotify(_ readerID: Int32, aProximityPercent proximityPercent: Int32) {
    }
    
    func srfidEventMultiProximityNotify(_ readerID: Int32, aTagData tagData: srfidTagData!) {
    }
    
    func srfidEventTriggerNotify(_ readerID: Int32, aTriggerEvent triggerEvent: SRFID_TRIGGEREVENT) {
        switch triggerEvent {
        case SRFID_TRIGGEREVENT_PRESSED:
            print("Presionado")
            if !isScanning {
                startScanning(readerID: readerID)
            }
        case SRFID_TRIGGEREVENT_RELEASED:
            print("Liberado")
            self.apiInstance.srfidStopRapidRead(readerID, aStatusMessage: nil)
            isScanning = false
        case SRFID_TRIGGEREVENT_SCAN_PRESSED:
            print("Scan Presionado")
        case SRFID_TRIGGEREVENT_SCAN_RELEASED:
            print("Scan Liberado")
        default:
            print("Trigger Event: \(triggerEvent)")
        }
    }
    
    func srfidEventBatteryNotity(_ readerID: Int32, aBatteryEvent batteryEvent: srfidBatteryEvent!) {
        bfprint("Battery status event received from RFID reader with ID = \(readerID)")
        bfprint("Battery level: \(batteryEvent.getPowerLevel())")
        batteryLevel = "\(batteryEvent.getPowerLevel())"
        bfprint("Charging: \(batteryEvent.getIsCharging() == false ? "NO" : "SI")")
        bfprint("Event cause: \(batteryEvent.getCause() ?? "")")
    }
}
