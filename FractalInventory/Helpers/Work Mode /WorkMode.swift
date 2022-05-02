//
//  WorkMode.swift
//  FractalInventory
//
//  Created by Jonathan Saldivar on 30/03/22.
//

import Foundation

enum WorkMode: Int {
    case online = 0
    case offline = 1
}

extension WorkMode {
    var isOnline: Bool {
        return self == .online
    }
    var isOffline: Bool {
        return self == .offline
    }
}
