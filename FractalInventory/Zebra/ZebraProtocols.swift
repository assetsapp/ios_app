//
//  ZebraProtocols.swift
//  FractalInventory
//
//  Created by Miguel Mexicano Herrera on 06/11/23.
//

import Foundation
protocol EventReceiverDelegate: AnyObject {
    func establishConnection(readerID: Int32)
}
