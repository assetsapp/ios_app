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
    static func decode<T: Codable>(_ type: T.Type, from data: Data, serviceName: String) -> T? {
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch let DecodingError.dataCorrupted(context) {
            print("DecodingError in \(serviceName) - Context:", context.codingPath)
        } catch let DecodingError.keyNotFound(key, context) {
            print("DecodingError in \(serviceName) - Key '\(key)' not found:", context.debugDescription)
            print("DecodingError in \(serviceName) - CodingPath:", context.codingPath)
        } catch let DecodingError.valueNotFound(value, context) {
            print("DecodingError in \(serviceName) - Value '\(value)' not found:", context.debugDescription)
            print("DecodingError in \(serviceName) - CodingPath:", context.codingPath)
        } catch let DecodingError.typeMismatch(type, context) {
            print("DecodingError in \(serviceName) - Type '\(type)' mismatch:", context.debugDescription)
            print("DecodingError in \(serviceName) - CodingPath:", context.codingPath)
        } catch {
            print("DecodingError in \(serviceName) - Error: ", error)
        }
        return nil
    }
}
