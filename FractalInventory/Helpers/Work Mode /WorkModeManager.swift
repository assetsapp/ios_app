//
//  WorkModeManager.swift
//  FractalInventory
//
//  Created by Jonathan Saldivar on 30/03/22.
//

import Foundation
import CloudKit
import WebKit

class WorkModeManager {
    
    init() { }
    
    func startOfflineMode(completion: @escaping(Result<WorkMode, WMError>) -> Void) {
        let dispatchGroup = DispatchGroup()
        var errors: [WMError] = []
        
        dispatchGroup.enter()
        fetchLocations { result in
            switch result {
            case .success(_ ):
                break
            case .failure(_ ):
                errors.append(WMError.locationsCouldNotBeDownloaded)
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        fetchEmployees { result in
            switch result {
            case .success(_ ):
                break
            case .failure(_ ):
                errors.append(WMError.employeesCouldNotBeDownloaded)
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        fetchReferences { result in
            switch result {
            case .success(_ ):
                break
            case .failure(_ ):
                errors.append(WMError.referencesCouldNotBeDownloaded)
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
            if errors.isEmpty {
                self.workMode = .offline
                completion(.success(self.workMode))
            } else {
                self.workMode = .online
                self.deleteAllData()
                let error = WMError.failedStartOfflineMode(errors: errors)
                completion(.failure(error))
            }
        }
    }
    
    func startOnlineMode(completion: @escaping(Result<(workMode: WorkMode, savedAssets: [Asset]), WMError>) -> Void) {
        DataManager().getAssets { result in
            switch result {
            case .success(let assets):
                self.starSync(assets: assets) { result in
                    switch result {
                    case.success(let savedAssets):
                        self.workMode = .online
                        self.deleteAllData()
                        completion(.success((workMode: self.workMode, savedAssets: savedAssets)))
                    case .failure(let error):
                        self.workMode = .offline
                        switch error {
                        case .failedToSyncAssets(_ ,let  savedAssets):
                            self.deleteAssets(savedAssets)
                        default:
                            break
                        }
                        completion(.failure(error))
                    }
                }
            case .failure(_ ):
                self.workMode = .offline
                completion(.failure(WMError.failedFetchAssets))
            }
        }
    }
    
    func getLocations(by id: String, and level: String, completion: @escaping(Result<[LocationModel2],Error>) -> Void) {
        DataManager().getLocations(by: id, and: level, completion: completion)
    }
    
    func getReferences(completion:  @escaping(Result<[ReferenceModel], Error>) -> Void) {
        DataManager().getReferences(completion: completion)
    }
    
    func getEmployees(completion:  @escaping(Result<[EmployeeModel], Error>) -> Void) {
        DataManager().getEmployees(completion: completion)
    }
    
    func getAssets(completion:  @escaping(Result<[Asset], Error>) -> Void) {
        DataManager().getAssets(completion: completion)
    }
    
    func tag(asset reference: ReferenceModel, location: LocationModel, locationPath: String, epc: [String], userId: String, serialNumber: String, tabs: [[String: Any]], customFields: [[String: Any]], customFieldsValues: [String], employee: EmployeeModel, image: Data?, completion: @escaping(Result<Asset, Error>) -> Void) {
        DataManager().tag(asset: reference,
                          location: location,
                          locationPath: locationPath,
                          epc: epc,
                          userId: userId,
                          serialNumber: serialNumber,
                          tabs: tabs,
                          customFields: customFields,
                          customFieldsValues: customFieldsValues,
                          employee: employee,
                          image: image,
                          completion: completion)
        
    }
}

extension WorkModeManager {
    private func fetchLocations(completion: @escaping(Result<[LocationModel2],Error>) -> Void) {
        ApiLocations().getLocations { result in
            switch result {
            case .success(let locations):
                DataManager().save(locations: locations, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func fetchEmployees(completion: @escaping(Result<[EmployeeModel],Error>) -> Void) {
        ApiEmployees().getEmployees { result in
            switch result {
            case .success(let employees):
                DataManager().save(employees: employees, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func fetchReferences(completion: @escaping(Result<[ReferenceModel], Error>) -> Void) {
        ApiReferences().getReferences { result in
            switch result {
            case .success(let references):
                DataManager().save(references: references, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
            
        }
    }
    
    private func deleteAllData() {
        DataManager().resetAllData()
    }
    
    private func deleteAssets(_ assets: [Asset]) {
        for asset in assets {
            DataManager().delete(asset: asset)
        }
    }
}

extension WorkModeManager {
    private func starSync(assets: [Asset], completion: @escaping(Result<[Asset], WMError>) -> Void) {
        let dispatchGroup = DispatchGroup()
        var savedAssets: [Asset] = []
        var errors:[WMError] = []
        
        for asset in assets {
            dispatchGroup.enter()
            if let imageData = asset.image {
                let image = UIImage(data: imageData)!
                sync(image: image, asset: asset) { result in
                    switch result {
                    case .success(_ ):
                        savedAssets.append(asset)
                    case .failure(let error):
                        print(error.localizedDescription)
                        errors.append(WMError.failedToSync(asset: asset))
                    }
                    dispatchGroup.leave()
                }
            } else {
                sync(asset: asset) { result in
                    switch result {
                    case .success(_ ):
                        savedAssets.append(asset)
                    case .failure(let error):
                        print(error.localizedDescription)
                        errors.append(WMError.failedToSync(asset: asset))
                    }
                    dispatchGroup.leave()
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            if errors.isEmpty {
                completion(.success(savedAssets))
            } else {
                var assets: [Asset] = []
                for error in errors {
                    switch error{
                    case .failedToSync(let asset):
                        assets.append(asset)
                    default:
                        break
                    }
                }
                completion(.failure(WMError.failedToSyncAssets(errorAssets: assets, savedAssets: savedAssets)))
            }
        }
    }
    
    private func sync(asset: Asset, completion: @escaping(Result<[SavedAsset], Error>) -> Void) {
        ApiReferences().postAssets(params: convert(asset: asset), completion: completion)
    }
    
    private func sync(image: UIImage, asset: Asset, completion: @escaping(Result<[SavedAsset], Error>) -> Void) {
        let params = self.convert(asset: asset)
        ApiFile().postImage(image: image) { result in
            switch result {
            case .success(let uploadFile):
                let fileparams: [String: Any] = [
                    "filename": uploadFile.filename,
                    "path": uploadFile.path
                ]
                let fileassetsparams = params.merging(fileparams) { (_, new) in new }
                ApiReferences().postAssets(params: fileassetsparams, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func convert(assets: [Asset]) -> [[String: Any]] {
        var assetsParams: [[String: Any]] = []
        for asset in assets {
                    let params: [String: Any] = [
                        "name": asset.name ?? "",
                        "brand": asset.brand ?? "",
                        "model": asset.model ?? "",
                        "serial": asset.serial ?? "",
                        "EPC": asset.epc ?? "",
                        "location": asset.location ?? "",
                        "locationPath": asset.locationPath ?? "",
                        "creator": asset.creator ?? "",
                        "labeling_user": asset.userId ?? "",
                        "customFieldsTab": asset.customFieldsTab ?? "",
                        "referenceId": asset.referenceId ?? "",
                        "tabs": asset.tabs ?? "",
                        "customFields": asset.customFields ?? "",
                        "customFieldsValues": asset.customFieldsValues ?? "",
                        "assigned": asset.assigned ?? "",
                        "assignedTo": asset.assignedTo ?? ""
                    ]
            assetsParams.append(params)
        }
        return assetsParams
    }
    
    private func convert(asset: Asset) -> [String: Any] {
        let params: [String: Any] = [
            "name": asset.name ?? "",
            "brand": asset.brand ?? "",
            "model": asset.model ?? "",
            "serial": asset.serial ?? "",
            "EPC": asset.epc ?? "",
            "location": asset.location ?? "",
            "locationPath": asset.locationPath ?? "",
            "creator": asset.creator ?? "",
            "labeling_user": asset.userId ?? "",
            "customFieldsTab": asset.customFieldsTab ?? "",
            "referenceId": asset.referenceId ?? "",
            "tabs": asset.tabs ?? "",
            "customFields": asset.customFields ?? "",
            "customFieldsValues": asset.customFieldsValues ?? "",
            "assigned": asset.assigned ?? "",
            "assignedTo": asset.assignedTo ?? ""
        ]
        return params
    }
}

extension WorkModeManager {
    var workMode: WorkMode {
        get {
            DataManager().getWorkMode()
        } set {
            if newValue == .online {
                offlineStartDate = Date()
            }
            DataManager().setWorkMode(newValue)
        }
    }
    
    var offlineStartDate: Date? {
        get {
            DataManager().getOfflineStartDate()
        } set {
            DataManager().setOfflineStartDate(newValue)
        }
    }
    
    var offlineStartDateFormatted: String {
        guard let offlineStartDate = offlineStartDate else { return "" }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy HH:mm"
        return dateFormatter.string(from: offlineStartDate)
    }
}
