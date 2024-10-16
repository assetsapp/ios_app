//
//  InventoryAssetsRequest.swift
//  FractalInventory
//
//  Created by Miguel Mexicano Herrera on 30/04/24.
//

import Foundation
struct InventoryAssetsRequest: Codable {
    let location: String
    let children: String
    let locationName: String
    let inventoryName: String
    let sessionId: String
}
