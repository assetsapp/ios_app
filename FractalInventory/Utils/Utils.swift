//
//  Utils.swift
//  FractalInventory
//
//  Created by Miguel Mexicano Herrera on 07/02/24.
//
import Foundation
struct Utils {
    static let zebraSingleton = ZebraSingleton.shared
    static func getFullDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/y H:m:ss.SSS"
        return dateFormatter.string(from: Date())
    }
    static func updateAntennaPower(power: Double) {
        if zebraSingleton.isAvailable() {
            zebraSingleton.updateAntennaPower(power: power)
        } else {
            CSLRfidAppEngine.shared().reader.selectAntennaPort(0)
            CSLRfidAppEngine.shared().reader.setPower(power)
        }
    }
}
