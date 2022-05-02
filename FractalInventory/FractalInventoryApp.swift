//
//  FractalInventoryApp.swift
//  FractalInventory
//
//  Created by Miguel Cruz on 15/08/21.
//

import SwiftUI

  @main
struct FractalInventoryApp: App {
    @StateObject private var dataManager = DataManager()
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(\.managedObjectContext, dataManager.container.viewContext)
        }
    }
}
