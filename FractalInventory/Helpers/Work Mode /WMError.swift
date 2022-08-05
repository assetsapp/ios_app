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
    case employeeProfilesCouldNotBeDownloaded
    case referencesCouldNotBeDownloaded
    case assetsCouldNotBeDownloaded
    case inventoriesCouldNotBeDownloaded
    case failedStartOfflineMode(errors: [WMError]? = nil)
    case failedFetchAssets
    case failedFetchEmployees
    case failedFetchInventories
    case failedToSyncAssets(errorAssets: [Asset], savedAssets: [Asset])
    case failedToSync(asset: Asset)
    case failedToUpdate(asset: Asset)
    case failedToSyncEmployee(employee: EmployeeModel)
    case failedToSyncInventory(inventory: InventorySession)
    case failedToSyncEmployees(errorEmployee: [EmployeeModel], savedEmployee: [EmployeeModel])
    case failedToSyncInventories(errorInventorie: [InventorySession], savedInventories: [InventorySession])
    case failedToSyncImage
    case inventoryNotFound
    case synchronizationFailure(errors: [WMError])
}

extension WMError: Hashable, Identifiable {
    var id: Self { self }
}

extension WMError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .synchronizationFailure(let errors):
            var message = ""
            for error in errors {
                message += error.localizedDescription + "\n"
            }
            return message
        case .locationsCouldNotBeDownloaded:
            return "Catalog locations could not be downloaded."
        case .employeesCouldNotBeDownloaded:
            return "Catalog employees could not be downloaded."
        case .employeeProfilesCouldNotBeDownloaded:
            return "Catalog employee profiles could not be downloaded."
        case .referencesCouldNotBeDownloaded:
            return "Catalog references could not be downloaded."
        case .assetsCouldNotBeDownloaded:
            return "Assets could not be downloaded."
        case .inventoriesCouldNotBeDownloaded:
            return "inventories could not be downloaded."
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
        case .failedToUpdate(_ ):
            return "Synchronization of updtate asset failed."
        case .failedToSyncAssets(let errorAssets, let savedAssets):
            return "Synchronization assets failed.\n Failing items: \(errorAssets.count).\nSuccess items: \(savedAssets.count)"
        case .failedToSyncEmployees(let errorEmployees, let savedEmployees):
            return "Synchronization employees failed.\n Failing items: \(errorEmployees.count).\nSuccess items: \(savedEmployees.count)"
        case .failedToSyncInventories(let errorInventorie, let savedInventories ):
            return "Synchronization inventories failed.\n Failing items: \(errorInventorie.count).\nSuccess items: \(savedInventories.count)"
        case .failedToSyncImage:
            return "Failed To Sync image"
        case .inventoryNotFound:
            return "inventory not found"
        case .failedFetchEmployees:
            return "Failed to Fetch Employees"
        case .failedToSyncEmployee(_ ):
            return "Failed To Sync Employee"
        case .failedFetchInventories:
            return "Failed to Fetch Inventories"
        case .failedToSyncInventory(_ ):
            return "Failed to sync inventory"
        }
    }
    
    public var title: String {
        return "Work Mode Error"
    }
}
