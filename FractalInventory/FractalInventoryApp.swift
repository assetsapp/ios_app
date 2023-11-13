//
//  FractalInventoryApp.swift
//  FractalInventory
//
//  Created by Miguel Cruz on 15/08/21.
//

import SwiftUI
import BugfenderSDK

@main
struct FractalInventoryApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @StateObject private var dataManager = DataManager()
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(\.managedObjectContext, dataManager.container.viewContext)
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        Bugfender.activateLogger("oTcsTQdZMtsU7VXEd7pdQYdRMP1VOeyf")
        Bugfender.enableCrashReporting()
        Bugfender.enableUIEventLogging()
        return true
    }
}
