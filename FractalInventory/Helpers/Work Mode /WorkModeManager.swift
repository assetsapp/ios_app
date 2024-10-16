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
    func startOfflineMode(completion: @escaping(Result<WorkMode, WMError>) -> Void) {
        let dispatchGroup = DispatchGroup()
        var errors: [WMError] = []
        
        //var inventories: [InventoryDataModel]?
        var employees: [EmployeeModel]?
        
        dispatchGroup.enter()
        fetchAssets { result in
            switch result {
            case .success(let assets):
                print("Asset: ", assets.count)
            case .failure(_ ):
                errors.append(WMError.assetsCouldNotBeDownloaded)
            }
            dispatchGroup.leave()
        }
        /*
        dispatchGroup.enter()
        fetchInventories { result in
            switch result {
            case .success(let data):
                print("Inventories: ", data.count)
                inventories = data
            case .failure(_ ):
                errors.append(WMError.inventoriesCouldNotBeDownloaded)
            }
            dispatchGroup.leave()
        } */
        
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
            case .success(let data):
                employees = data
            case .failure(_ ):
                errors.append(WMError.employeesCouldNotBeDownloaded)
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        fetchEmployeProfiles { result in
            switch result {
            case .success(_ ):
                break
            case .failure(_ ):
                errors.append(WMError.employeeProfilesCouldNotBeDownloaded)
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
        
        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let self = self else {
                return
            }
            //if inventories != nil || employees != nil {
            if employees != nil {
                // En este punto ya tenemos los assets guardados
                // Y los Inventories aun no sean guardado
                //self.processSync(inventories: inventories, employees: employees, errors: errors, completion: completion)
                self.processSync(inventories: nil, employees: employees, errors: errors, completion: completion)
            } else {
                self.processOfflineWorkMode(errors: errors, completion: completion)
            }
        }
    }
    
    private func processSync(inventories: [InventoryDataModel]?, employees: [EmployeeModel]? ,errors: [WMError], completion: @escaping(Result<WorkMode, WMError>) -> Void) {
        var processSyncErrors = errors
        let dispatchGroup = DispatchGroup()
        
        if let inventories = inventories {
            print("-> Empezo A Guardar los inventarios en BD")
            dispatchGroup.enter()
            DataManager().save(inventories: inventories) { result in
                switch result {
                case .success(let inv):
                    print("<- Termino de Guardar los inventarios en BD:", inv.count)
                case .failure(let error):
                    print("<- Error de Guardar los inventarios en BD:", error.localizedDescription)
                    processSyncErrors.append(.inventoriesCouldNotBeDownloaded)
                }
                dispatchGroup.leave()
            }
        }
        
        if let employees = employees {
            dispatchGroup.enter()
            DataManager().save(employees: employees) { result in
                switch result {
                case .success(let emp):
                    print("<- Termino de Guardar los Empleados en BD:", emp.count)
                case .failure(let error):
                    print("<- Error de Guardar los Empleados en BD:", error.localizedDescription)
                    processSyncErrors.append(.employeesCouldNotBeDownloaded)
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            self.processOfflineWorkMode(errors: errors, completion: completion)
        }
    }
    
    private func processOfflineWorkMode(errors: [WMError], completion: @escaping(Result<WorkMode, WMError>) -> Void) {
        if errors.isEmpty {
            self.workMode = .offline
            print("\n\n ###### \n Termino la carga de modo offline\n######\n\n")
            completion(.success(self.workMode))
        } else {
            print("\n\n ###### \n Termino la carga de modo offline Con errores \n######\n\n")
            self.workMode = .online
            self.deleteAllData()
            let error = WMError.failedStartOfflineMode(errors: errors)
            completion(.failure(error))
        }
    }
    
    func startOnlineMode(completion: @escaping(Result<(workMode: WorkMode, savedAssets: [Asset]), WMError>) -> Void) {
        let dispatchGroup = DispatchGroup()
        var savedAssets: [Asset] = []
        var errors: [WMError] = []
        
        dispatchGroup.enter()
        DataManager().getAssetsToSync { [weak self] result in
            guard let self = self else {
                return
            }
            switch result {
            case .success(let assets):
                self.startSync(assets: assets) { [weak self] result in
                    guard let self = self else {
                        return
                    }
                    switch result {
                    case.success(let savedAssetsR):
                        print("Termino de sincronizar los Assets:", savedAssetsR.count)
                        savedAssets = savedAssetsR
                    case .failure(let error):
                        switch error {
                        case .failedToSyncAssets(_ ,let  savedAssets):
                            self.deleteAssets(savedAssets)
                        default:
                            break
                        }
                        errors.append(error)
                    }
                    dispatchGroup.leave()
                }
            case .failure(_ ):
                errors.append(WMError.failedFetchAssets)
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.enter()
        DataManager().getAssetsToUpdate { [weak self] result in
            guard let self = self else {
                return
            }
            switch result {
            case .success(let assets):
                print("Asses para actualizar \(assets.count)")
                self.startUpdate(assets: assets) { [weak self] result in
                    guard let self = self else {
                        return
                    }
                    switch result {
                    case.success(let updatedAssets):
                        print("Termino de actualizar los Assets:", updatedAssets.count)
                    case .failure(let error):
                        switch error {
                        case .failedToSyncAssets(_ ,let savedAssets):
                            self.deleteAssets(savedAssets)
                        default:
                            break
                        }
                        errors.append(error)
                    }
                    dispatchGroup.leave()
                }
            case .failure(_ ):
                errors.append(WMError.failedFetchAssets)
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) { [weak self] in
            self?.continueStartOnlineMode(savedAssets, and: errors, completion: completion)
        }
    }
    
    private func continueStartOnlineMode(_ savedAssets: [Asset], and lastErrors: [WMError] ,completion: @escaping(Result<(workMode: WorkMode, savedAssets: [Asset]), WMError>) -> Void) {
        let dispatchGroup = DispatchGroup()
        var errors: [WMError] = lastErrors
        //var savedEmployees: [EmployeeModel] = []
        // empleados
        dispatchGroup.enter()
        DataManager().getEmployeesToSync { [weak self] result in
            switch result {
            case .success(let employees):
                self?.startSync(employees: employees) { result in
                    switch result {
                    case .success(let _savedEmployees):
                        print("Termino de actualizar los Empleados:", _savedEmployees.count)
                        //savedEmployees = _savedEmployees
                    case .failure(let error):
                        switch error {
                        case .failedToSyncEmployees(_ , _):
                            break
                        default:
                            break
                        }
                        errors.append(error)
                    }
                    dispatchGroup.leave()
                }
            case .failure(_ ):
                errors.append(WMError.failedFetchEmployees)
                dispatchGroup.leave()
            }
        }
        
        // empleados
        dispatchGroup.enter()
        DataManager().getEmployeesToUpdate { [weak self] result in
            switch result {
            case .success(let employees):
                self?.startUpdateSync(employees: employees) { result in
                    switch result {
                    case .success(let savedEmployees):
                        print("Termino de actualizar los Empleados asignados:", savedEmployees.count)
                    case .failure(let error):
                        switch error {
                        case .failedToSyncEmployees(_ , _):
                            break
                        default:
                            break
                        }
                        errors.append(error)
                    }
                    dispatchGroup.leave()
                }
            case .failure(_ ):
                errors.append(WMError.failedFetchEmployees)
                dispatchGroup.leave()
            }
        }
        
        //inventarios
        dispatchGroup.enter()
        DataManager().getInventorySessionToSync { [weak self] result in
            switch result {
            case .success(let inventorySessions):
                self?.starSync(inventorySessions: inventorySessions) { result in
                    switch result {
                    case .success(let savedInventories):
                        print("Termino de actualizar los Inventarios:", savedInventories.count)
                    case .failure(let error):
                        switch error {
                        case .failedToSyncInventories(_ , _):
                            break
                        default:
                            break
                        }
                        errors.append(error)
                    }
                    dispatchGroup.leave()
                }
            case .failure(_ ):
                errors.append(WMError.failedFetchInventories)
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let self = self else {
                return
            }
            if errors.isEmpty {
                self.deleteAllData()
                self.workMode = .online
                completion(.success((workMode: self.workMode , savedAssets: savedAssets)))
            } else {
                self.workMode = .offline
                completion(.failure(WMError.synchronizationFailure(errors: errors)))
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
        DataManager().getAssetsToSync(completion: completion)
    }
    
    func tag(asset reference: ReferenceModel, location: LocationModel, locationPath: String, epc: [String], userId: String, serialNumber: String, tabs: [[String: Any]], customFields: [[String: Any]], customFieldsValues: [String], employee: EmployeeModel, image: Data?, completion: @escaping(Result<Asset, Error>) -> Void) {
        // Concatenar los elementos del array EPC en una sola cadena
        let epcString = epc.joined()
        print("tag EPC: \(epcString)") // Log
        // Llamar a la función tag de DataManager para guardar el activo
        DataManager().tag(asset: reference,
                          location: location,
                          locationPath: locationPath,
                          epc: epcString,
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
    private func fetchAssets(completion: @escaping(Result<[AssetRespondeModel],Error>) -> Void) {
        ApiAssets().getAllAssets { result in
            switch result {
            case .success(let assets):
                print("get assets succes \(assets.count)")
                DataManager().save(assets: assets, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func fetchInventories(completion: @escaping(Result<[InventoryDataModel],Error>) -> Void) {
        ApiInventorySessions().getInventorySessions { result in
            switch result {
            case .success(let sessions):
                completion(.success(sessions))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
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
    
    private func fetchEmployeProfiles(completion: @escaping(Result<[EmployeeProfileModel],Error>) -> Void) {
        ApiEmployees().getEmployeeProfiles { result in
            switch result {
            case.failure(let error):
                completion(.failure(error))
            case .success(let profiles):
                DataManager().save(employeeProfiles: profiles, completion: completion)
            }
        }
    }
    
    private func fetchEmployees(completion: @escaping(Result<[EmployeeModel],Error>) -> Void) {
        ApiEmployees().getEmployees { result in
            switch result {
            case .success(let employees):
               // DataManager().save(employees: employees, completion: completion)
                // Se traslada el guardado al momento en el que ya se tienen los assets
                completion(.success(employees))
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
    private func startSync(assets: [Asset], completion: @escaping(Result<[Asset], WMError>) -> Void) {
        let dispatchGroup = DispatchGroup()
        var savedAssets: [Asset] = []
        var errors:[WMError] = []
        
        for asset in assets {
            dispatchGroup.enter()
            print("Sincronizando asset con EPC: \(asset.epc ?? "nil")") // Agrega este log
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
    
    private func startUpdate(assets: [Asset], completion: @escaping(Result<[Asset], WMError>) -> Void) {
        let dispatchGroup = DispatchGroup()
        var savedAssets: [Asset] = []
        var errors:[WMError] = []
        
        for asset in assets {
            dispatchGroup.enter()
            if let imageData = asset.image {
                print("Actualizando asset con imagen nueva")
                let image = UIImage(data: imageData)!
                syncUpdate(image: image, asset: asset) { result in
                    switch result {
                    case .success(_ ):
                        savedAssets.append(asset)
                    case .failure(let error):
                        print(error.localizedDescription)
                        errors.append(WMError.failedToUpdate(asset: asset))
                    }
                    dispatchGroup.leave()
                }
            } else {
                print("Actualizando asset \(asset.id)")
                syncUpdate(asset: asset) { result in
                    switch result {
                    case .success(_ ):
                        savedAssets.append(asset)
                    case .failure(let error):
                        print(error.localizedDescription)
                        errors.append(WMError.failedToUpdate(asset: asset))
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
                    case .failedToUpdate(let asset):
                        assets.append(asset)
                    default:
                        break
                    }
                }
                completion(.failure(WMError.failedToSyncAssets(errorAssets: assets, savedAssets: savedAssets)))
            }
        }
    }
    
    private func startSync(employees: [EmployeeModel], completion: @escaping(Result<[EmployeeModel], WMError>) -> Void) {
        let dispatchGroup = DispatchGroup()
        var savedEmployees: [EmployeeModel] = []
        var errors:[WMError] = []
        
        for employee in employees {
            dispatchGroup.enter()
            sync(employee: employee) { result in
                switch result {
                case .success(_ ):
                    savedEmployees.append(employee)
                case .failure(let error):
                    print(error.localizedDescription)
                    errors.append(WMError.failedToSyncEmployee(employee: employee))
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            if errors.isEmpty {
                completion(.success(savedEmployees))
            } else {
                var errorEmployee: [EmployeeModel] = []
                for error in errors {
                    switch error {
                    case .failedToSyncEmployee(let employee):
                        errorEmployee.append(employee)
                    default:
                        break
                    }
                }
                completion(.failure(.failedToSyncEmployees(errorEmployee: errorEmployee, savedEmployee: savedEmployees)))
            }
        }
    }
    
    private func startUpdateSync(employees: [EmployeeModel], completion: @escaping(Result<[EmployeeModel], WMError>) -> Void) {
        let dispatchGroup = DispatchGroup()
        var savedEmployees: [EmployeeModel] = []
        var errors:[WMError] = []
        
        for employee in employees {
            dispatchGroup.enter()
            syncUpdate(employee: employee) { result in
                switch result {
                case .success(_ ):
                    savedEmployees.append(employee)
                case .failure(let error):
                    print(error.localizedDescription)
                    errors.append(WMError.failedToSyncEmployee(employee: employee))
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            if errors.isEmpty {
                completion(.success(savedEmployees))
            } else {
                var errorEmployee: [EmployeeModel] = []
                for error in errors {
                    switch error {
                    case .failedToSyncEmployee(let employee):
                        errorEmployee.append(employee)
                    default:
                        break
                    }
                }
                completion(.failure(.failedToSyncEmployees(errorEmployee: errorEmployee, savedEmployee: savedEmployees)))
            }
        }
    }
    
    private func starSync(inventorySessions: [InventorySession], completion: @escaping(Result<[InventorySession], WMError>) -> Void) {
        let dispatchGroup = DispatchGroup()
        var savedInventories: [InventorySession] = []
        var errors:[WMError] = []
        
        for session in inventorySessions {
            dispatchGroup.enter()
            print("starSync inventorySession: \(session.identifier ?? ""), count: \(session.assets?.count ?? -1)")
            let inventorySessionFiltered = InventoryDataModel(inventorySession: session)
            sync(inventorySession: session) { result in
                switch result {
                case .success(_ ):
                    self.syncInventoryAssets(inventorySession: inventorySessionFiltered) { result2 in
                        switch result2 {
                        case .success(_ ):
                            savedInventories.append(session)
                        case .failure(let error):
                            print(error.localizedDescription)
                            errors.append(WMError.failedToSyncInventory(inventory: session))
                        }
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                    errors.append(WMError.failedToSyncInventory(inventory: session))
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            if errors.isEmpty {
                completion(.success(savedInventories))
            } else {
                var errorInventory: [InventorySession] = []
                for error in errors {
                    switch error {
                    case .failedToSyncInventory(let inventory):
                        errorInventory.append(inventory)
                    default:
                        break
                    }
                }
                completion(.failure(.failedToSyncInventories(errorInventorie: errorInventory, savedInventories: savedInventories)))
            }
        }
    }
    
    private func syncInventoryAssets(inventorySession: InventoryDataModel, completion: @escaping(Result<String, Error>) -> Void) {
        let params: [String: Any] = [
            "foundEPCS": inventorySession.assets?
                .filter { $0.status == "found" }
                .compactMap { $0.EPC } ?? [],
            "sessionId": inventorySession.sessionId,
            "closeInventory": inventorySession.status
        ]
        
        ApiInventorySessions().updateAssetsInInventorySession(params: params) { result in
            switch result {
            case .success(_ ):
                completion(.success(""))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func sync(asset: Asset, completion: @escaping(Result<[SavedAsset], Error>) -> Void) {
        let params = convert(asset: asset)
        print("sync params: \(params)") // Log
        ApiReferences().postAssets(params: params) { result in
            switch result {
            case .success(let savedAssets):
                print("sync success: \(savedAssets)") // Log
                completion(.success(savedAssets))
            case .failure(let error):
                print("sync error: \(error)") // Log
                completion(.failure(error))
            }
        }
    }
    
    private func sync(employee: EmployeeModel, completion: @escaping(Result<EmployeeModel, Error>) -> Void) {
        ApiEmployees().postEmployee(params: convert(employee: employee)) { result in
            switch result {
            case .success(_ ):
                completion(.success(employee))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func syncUpdate(employee: EmployeeModel, completion: @escaping(Result<EmployeeModel, Error>) -> Void) {
        let asset = employee.assetsAssigned?.first
        let assetId = asset?.id ?? ""
        ApiAssets().assignEmployeeToAsset(assetId: assetId, employee: employee) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(_ ):
                let params: [String: Any] = [
                    "id": asset?.id ?? "",
                    "name": asset?.name ?? "",
                    "brand": asset?.brand ?? "",
                    "model": asset?.model ?? "",
                    "EPC": asset?.EPC ?? "",
                    "serial": asset?.serial ?? "",
                    "oldEmployeeId": asset?.originalAssigned ?? ""
                ]
                ApiEmployees().assignAssetToEmployee(params: params, employeeId: employee._id) { result in
                    switch result {
                    case .success(_ ):
                        completion(.success(employee))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
        }
    }
    
    private func sync(inventorySession: InventorySession, completion: @escaping(Result<InventorySession, Error>) -> Void) {
        let type = InventoryType(rawValue: inventorySession.type ?? "") ?? .root
        ApiAssets().getInventoryAssets(location: inventorySession.locationId ?? "", locationName: inventorySession.locationName ?? "", sessionId: inventorySession.sessionId ?? "", inventoryName: inventorySession.name ?? "", type: type) { result in
            switch result {
            case .success(_ ):
                completion(.success(inventorySession))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func sync(image: UIImage, asset: Asset, completion: @escaping(Result<[SavedAsset], Error>) -> Void) {
        let params = self.convert(asset: asset)
        ApiFile().postImage(image: image, _id: asset.identifier ?? "") { result in
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
    
    private func syncUpdate(asset: Asset, completion: @escaping(Result<[SavedAsset], Error>) -> Void) {
        ApiAssets().updateAsset(assetId: asset.identifier ?? "", params: convertUpdate(asset: asset)) { result in
            switch result {
            case .success(_ ):
                completion(.success([SavedAsset(_id: asset.identifier ?? "", EPC: asset.epc ?? "")]))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func syncUpdate(image: UIImage, asset: Asset, completion: @escaping(Result<[SavedAsset], Error>) -> Void) {
        let params = self.convertUpdate(asset: asset)
        let assetId = asset.identifier ?? ""
        ApiFile().postImage(image: image, _id: asset.identifier ?? "") { result in
            switch result {
            case .success(_ ):
                print("Actualizo imagen de asset")
                let fileparams: [String: Any] = [
                    "fileExt": "jpeg"
                ]
                let fileassetsparams = params.merging(fileparams) { (_, new) in new }
                ApiAssets().updateAsset(assetId: assetId, params: fileassetsparams) { result in
                    switch result {
                    case .success(_ ):
                        completion(.success([SavedAsset(_id: asset.identifier ?? "", EPC: asset.epc ?? "")]))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
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
                        "labeling_user": asset.identifier ?? "",
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
            "labeling_user": asset.labelingUser ?? "",
            "customFieldsTab": asset.customFieldsTab ?? "",
            "referenceId": asset.referenceId ?? "",
            "tabs": asset.tabs ?? "",
            "customFields": asset.customFields ?? "",
            "customFieldsValues": asset.customFieldsValues ?? "",
            "assigned": asset.assigned ?? "",
            "assignedTo": asset.assignedTo ?? ""
        ]
        print("convert params: \(params)") // Log
        return params
    }
    
    private func convert(asset: AssetsAssigned) -> [String: Any] {
        let params: [String: Any] = [
            "id": asset.id ?? "",
            "name": asset.name ?? "",
            "brand": asset.brand ?? "",
            "model": asset.model ?? "",
            "assigned": asset.assigned ?? true,
            "EPC": asset.EPC ?? "",
            "serial": asset.serial ?? "",
            "creationDate": asset.creationDate ?? ""
        ]
        return params
    }
    
    private func convertUpdate(asset: Asset) -> [String: Any] {
        let params: [String: Any] = [
            "serial": asset.serial ?? "",
            "EPC": asset.epc ?? ""
        ]
        return params
    }
    
    private func convert(employee: EmployeeModel) -> [String: Any] {
        var assetsAssigned: [[String: Any]] = []
        if let assets = employee.assetsAssigned {
            for asset in assets {
                assetsAssigned.append(convert(asset: asset))
            }
        }
        let selectedProfile: [String:String] = [
            "value": employee.profileId ?? "",
            "label": employee.profileName ?? ""
        ]
        let params: [String : Any] = [
            "name": employee.name,
            "lastName": employee.lastName,
            "employee_id": employee.employee_id ?? "",
            "email": employee.email,
            "employeeProfile": selectedProfile,
            "assetsAssigned": assetsAssigned
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
