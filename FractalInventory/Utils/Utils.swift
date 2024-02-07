//
//  Utils.swift
//  FractalInventory
//
//  Created by Miguel Mexicano Herrera on 07/02/24.
//
import Foundation
struct Utils {
    static func getFullDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/y H:m:ss.SSS"
        return dateFormatter.string(from: Date())
    }
}
