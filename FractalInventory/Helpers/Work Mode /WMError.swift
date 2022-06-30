//
//  WMError.swift
//  FractalInventory
//
//  Created by Jonathan Saldivar on 25/04/22.
//

import Foundation

enum WMError: Error {
    case locationsCouldNotBeDownloaded
    case employeesCouldNotBeDownloaded
    case referencesCouldNotBeDownloaded
    case failedStartOfflineMode(errors: [WMError]? = nil)
    case failedFetchAssets
    case failedToSyncAssets(errorAssets: [Asset], savedAssets: [Asset])
    case failedToSync(asset: Asset)
    case failedToSyncImage
}

extension WMError: Hashable, Identifiable {
    var id: Self { self }
}

extension WMError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .locationsCouldNotBeDownloaded:
            return "Catalog locations could not be downloaded."
        case .employeesCouldNotBeDownloaded:
            return "Catalog employees could not be downloaded."
        case .referencesCouldNotBeDownloaded:
            return "Catalog references could not be downloaded."
        case .failedStartOfflineMode(let errors):
            var reason = "unknown"
            if let errors = errors {
                reason = ""
                for error in errors {
                    reason += "\(error.description)\n"
                }
            }
            return "Failed to start offline mode\nReason: \(reason)"
        case .failedFetchAssets:
            return "Assets could not be recovered"
        case .failedToSync(_ ):
            return "Synchronization of asset failed."
        case .failedToSyncAssets(let errorAssets, let savedAssets):
            return "Synchronization assets failed.\n Failing items: \(errorAssets.count).\nSuccess items: \(savedAssets.count)"
        case .failedToSyncImage:
            return "Failed To Sync image"
        }
    }
    
    public var title: String {
        return "Work Mode Error"
    }
}
