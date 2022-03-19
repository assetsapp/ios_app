//
//  CSLViewModel.swift
//  FractalInventory
//
//  Created by Miguel Cruz on 01/09/21.
//

import AudioToolbox

@objcMembers class CSLViewModel : UIViewController, CSLBleReaderDelegate, CSLBleInterfaceDelegate, MQTTSessionDelegate {

    var tagRangingStartTime: Date? = nil
    private var scrRefreshTimer: Timer?
    private var transport: MQTTCFSocketTransport?
    private var session: MQTTSession?
    private var isMQTTConnected = false

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("**************** Reaching this file!!!")
        print("**************** Delegates attached")

    }

    override func viewWillDisappear(_ animated: Bool) {
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func didInterfaceChangeConnectStatus(_ sender: CSLBleInterface?) {
        print("> > > > Original")
        print("didInterfaceChangeConnectStatus")
    }

    func didReceiveTagResponsePacket(_ sender: CSLBleReader?, tagReceived tag: CSLBleTag?) {

    }

    func didReceiveTagAccessData(_ sender: CSLBleReader?, tagReceived tag: CSLBleTag?) {

    }

    func didReceiveBatteryLevelIndicator(_ sender: CSLBleReader?, batteryPercentage battPct: Int32) {

    }

    func didTriggerKeyChangedState(_ sender: CSLBleReader?, keyState state: Bool) {

    }

    func didReceiveBarcodeData(_ sender: CSLBleReader?, scannedBarcode barcode: CSLReaderBarcode?) {

    }
    

    func bankEnum(toString bank: MEMORYBANK) -> String? {
        var result: String? = nil

        switch bank {
        case MEMORYBANK.RESERVED:
                result = "RESERVED"
        case MEMORYBANK.EPC:
                result = "EPC"
        case MEMORYBANK.TID:
                result = "TID"
        case MEMORYBANK.USER:
                result = "USER"
            default:
                result = ""
        }

        return result
    }
}

