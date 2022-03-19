//
//  CSLGlobalVariables.swift
//  FractalInventory
//
//  Created by Miguel Cruz on 01/09/21.
//

import Foundation
import SwiftUI

struct CSLGlobalVariables {
    static var batteryLevel: Int32 = -1
    static var isKeyPressed: Bool = false
    static var epcsarr: [EpcModel] = []
    static var _cslvalues: CSLValues = CSLValues()
    static func addEpc(epc: String, rssi: UInt8) {
        if !epcsarr.contains(where: { $0.epc == epc }) {
            epcsarr.append(EpcModel(epc: epc, rssi: String(rssi), timestamp: ""))
        }
    }
}

