//
//  EpcModel.swift
//  FractalInventory
//
//  Created by Miguel Cruz on 29/08/21.
//

import Foundation
import SwiftUI

struct EpcModel: Identifiable, Hashable {
  
    var id = UUID()
    var epc: String
    var rssi: String
    var timestamp: String

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
  
}
