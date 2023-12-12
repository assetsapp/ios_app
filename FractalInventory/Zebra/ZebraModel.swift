//
//  ZebraModel.swift
//  FractalInventory
//
//  Created by Miguel Mexicano Herrera on 12/12/23.
//

import Foundation
struct RFIDDevice: Identifiable {
    let id: Int32
    let name: String
    let type: RFIDDeviceType
    
    enum RFIDDeviceType {
        case active
        case available
        
        var toString: String {
            switch self {
            case .active:
                return "Conectado"
            case .available:
                return "Disponible"
            }
        }
    }
}
extension RFIDDevice {
    static var empty: Self {
        RFIDDevice(id: 0, name: "", type: .active)
    }
}
