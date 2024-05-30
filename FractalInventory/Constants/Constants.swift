//
//  Constants.swift
//  FractalInventory
//
//  Created by Miguel Mexicano Herrera on 01/11/23.
//
import Foundation
struct Constants {
//    static let apiHost = "https://apidemo.tagventory.com"
//    static let apiDB = "assets-app-backup"
//    static let apiHost = "https://apitasa.tagventory.com"
//    static let apiDB = "assets-app-tasa"
    static let apiHost = "https://apigrupomexico.tagventory.com"
    static let apiDB = "assets-app-grupomexico"
}
struct EndPoints {
    static let inventoryAssets = "/api/v1/app/{apiDB}/assets/inventory/"
    static let allAssets = "/api/v1/{apiDB}/assets/"
    static let inventorySession = "/api/v1/{apiDB}/inventorySessions/"
}
