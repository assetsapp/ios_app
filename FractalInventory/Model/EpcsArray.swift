//
//  EpcsArray.swift
//  FractalInventory
//
//  Created by Miguel Cruz on 29/08/21.
//

import Foundation

class EpcsArray: ObservableObject {
    
    @Published var epcs = [EpcModel]()
    
    init() {
        
        print("Fetch from Backend")
        
        let epc00 = EpcModel(epc: "ABCDEF012345678901234501", rssi: "84.13", timestamp: "08/29/2021 15:07:33")
        let epc01 = EpcModel(epc: "ABCDEF012345678901234502", rssi: "44.13", timestamp: "08/29/2021 15:07:34")
        let epc02 = EpcModel(epc: "ABCDEF012345678901234503", rssi: "83.13", timestamp: "08/29/2021 15:07:35")
        let epc03 = EpcModel(epc: "ABCDEF012345678901234504", rssi: "12.23", timestamp: "08/29/2021 15:07:36")
        let epc04 = EpcModel(epc: "ABCDEF012345678901234505", rssi: "94.33", timestamp: "08/29/2021 15:07:37")
        let epc05 = EpcModel(epc: "ABCDEF012345678901234506", rssi: "73.23", timestamp: "08/29/2021 15:07:38")
        let epc06 = EpcModel(epc: "ABCDEF012345678901234507", rssi: "51.23", timestamp: "08/29/2021 15:07:39")
        let epc07 = EpcModel(epc: "ABCDEF012345678901234508", rssi: "71.34", timestamp: "08/29/2021 15:07:40")
        let epc08 = EpcModel(epc: "ABCDEF01234567890123450A", rssi: "99.98", timestamp: "08/29/2021 15:07:41")
        let epc09 = EpcModel(epc: "ABCDEF01234567890123450B", rssi: "51.31", timestamp: "08/29/2021 15:07:42")
        
        self.epcs.append(epc00)
        self.epcs.append(epc01)
        self.epcs.append(epc02)
        self.epcs.append(epc03)
        self.epcs.append(epc04)
        self.epcs.append(epc05)
        self.epcs.append(epc06)
        self.epcs.append(epc07)
        self.epcs.append(epc08)
        self.epcs.append(epc09)

    }
    
    init(epc: EpcModel) {
        self.epcs.append(epc)
    }
    
}
