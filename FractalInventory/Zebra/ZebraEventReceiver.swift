//
//  ZebraEventReceiver.swift
//  FractalInventory
//
//  Created by Miguel Mexicano Herrera on 06/11/23.
//

import Foundation
class EventReceiver: NSObject, srfidISdkApiDelegate {
    var delegate: EventReceiverDelegate?
    func srfidEventReaderAppeared(_ availableReader: srfidReaderInfo!) {
        print("RFID reader has appeared: ID = \(availableReader.getReaderID()) name = \(availableReader.getReaderName() ?? "")")
    }
    
    func srfidEventReaderDisappeared(_ readerID: Int32) {
        print("RFID reader has disappeared: ID = \(readerID)")
    }
    
    func srfidEventCommunicationSessionEstablished(_ activeReader: srfidReaderInfo!) {
        let readerID = activeReader.getReaderID()
        print("RFID reader has connected: ID = \(readerID) name = \(activeReader.getReaderName() ?? "")")
        delegate?.establishConnection(readerID: readerID)
    }
    
    func srfidEventCommunicationSessionTerminated(_ readerID: Int32) {
        print("RFID reader has disconnected: ID = \(readerID)")
    }
    
    func srfidEventReadNotify(_ readerID: Int32, aTagData tagData: srfidTagData!) {
        
    }
    
    func srfidEventStatusNotify(_ readerID: Int32, aEvent event: SRFID_EVENT_STATUS, aNotification notificationData: Any!) {
        
    }
    
    func srfidEventProximityNotify(_ readerID: Int32, aProximityPercent proximityPercent: Int32) {
        
    }
    
    func srfidEventMultiProximityNotify(_ readerID: Int32, aTagData tagData: srfidTagData!) {
        
    }
    
    func srfidEventTriggerNotify(_ readerID: Int32, aTriggerEvent triggerEvent: SRFID_TRIGGEREVENT) {
        
    }
    
    func srfidEventBatteryNotity(_ readerID: Int32, aBatteryEvent batteryEvent: srfidBatteryEvent!) {
        print("Battery status event received from RFID reader with ID = \(readerID)")
        print("Battery level: \(batteryEvent.getPowerLevel())")
        print("Charging: \(batteryEvent.getIsCharging() == false ? "NO" : "SI")")
        print("Event cause: \(batteryEvent.getCause() ?? "")")
    }
}
