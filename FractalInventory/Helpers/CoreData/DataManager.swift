//
//  DataManager.swift
//  FractalInventory
//
//  Created by Jonathan Saldivar on 06/04/22.
//

import Foundation
import CoreData
import SwiftUI

class DataManager: ObservableObject {
    private static var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Inventory")
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("********  Core data Error: \(error.localizedDescription)")
            }
        }
        return container
    }()
    
    var context: NSManagedObjectContext {
        return Self.persistentContainer.viewContext
    }
    
    //MARK: - CoreData
    func save(assets: [AssetRespondeModel], completion: @escaping(Result<[AssetRespondeModel],Error>) -> Void) {
        
            context.reset()
            context.retainsRegisteredObjects = true
            
            for item in assets {
                guard let epc = item.EPC, !epc.isEmpty else {
                    print("Error: EPC es nulo o vacío")
                    continue
                }
                
                let asset = Asset(context: context)
                print("Guardando EPC: \(epc)")
                asset.name = item.name
                asset.brand = item.brand
                asset.model = item.model
                asset.serial = item.serial
                asset.epc = epc
                asset.location = item.location
                asset.locationPath = item.locationPath
                asset.creator = item.creator
                asset.identifier = item._id
                asset.customFieldsTab = ""
                asset.referenceId = item.referenceId
                asset.tabs = [[:]]
                asset.customFields = [[:]]
                asset.customFieldsValues = []
                asset.assigned = item.assigned
                asset.assignedTo = item.assigned
                asset.status  = item.status
                asset.creationDate  = item.creation_date
                asset.updateDate  = item.updateDate
                asset.fileExt  = item.fileExt
                asset.parent  = item.parent
                asset.imageURL  = item.imageURL
                asset.quantity  = Int32(item.quantity ?? 0)
                asset.responsible  = item.responsible
                asset.purchaseDate  = item.purchase_date
                asset.purchasePrice  = item.purchase_price
                asset.totalPrice  = item.total_price
                asset.labelingUser  = item.labeling_user
                asset.notes  = item.notes
                asset.labelingDate  = item.labeling_date
                asset.price  = item.price
                asset.image = nil // TODO: Descargar imagen por imagen 2455
            }
            
            do {
                try context.save()
                print("Assets guardados exitosamente: \(assets.count)")
                completion(.success(assets))
            } catch {
                completion(.failure(error))
            }
        }
    
    func save(inventories: [InventoryDataModel] ,completion: @escaping(Result<[InventoryDataModel], Error>) -> Void)  {
        for (index, item) in inventories.enumerated() {
            let inventorySession = InventorySession(context: context)
            inventorySession.identifier = item._id
            inventorySession.sessionId = item.sessionId
            inventorySession.name = item.name
            inventorySession.locationId = item.locationId
            inventorySession.locationName = item.locationName
            inventorySession.status = item.status
            inventorySession.creation = item.creation
            print("Procesando \(index)/\(inventories.count)")
            if let assets = item.assets {
                for asset in assets {
                    let assetRequest = Asset.fetchRequest()
                    assetRequest.predicate = NSPredicate(format: "identifier == %@", asset._id)
                    do {
                        let assetResult = try context.fetch(assetRequest)
                        if let oneAsset = assetResult.first {
                            inventorySession.addToAssets(oneAsset)
                        }
                        try context.save()
                    } catch {
                        print("NO SE PUDO AGREGAR EL ASSET A LA SESSION: ", error.localizedDescription)
                    }
                }
            }
        }
        
        do {
            try context.save()
            completion(.success(inventories))
        } catch {
            completion(.failure(error))
        }
    }
    
    func save(locations: [LocationModel2], completion: @escaping(Result<[LocationModel2],Error>) -> Void) {
        for item in locations {
            let location = Location(context: context)
            location.id = item._id
            location.name = item.name
            location.profileName = item.profileName
            location.profileLevel = item.profileLevel
            location.parent = item.parent
            location.assetsCount = Int32(item.assetsCount) // TODO: Update Number whan create asset
            location.childrenCount = Int32(item.childrenCount)
        }
        
        do {
            try context.save()
            completion(.success(locations))
        } catch {
            completion(.failure(error))
        }
    }
    
    func save(employees: [EmployeeModel], completion: @escaping(Result<[EmployeeModel],Error>) -> Void) {
        context.reset()
        var test: [Employee] = []

        // Recopilar todos los asset IDs que se necesitarán en una sola consulta
        var assetIdsSet: Set<String> = []
        for employee in employees {
            if let assets = employee.assetsAssigned {
                for asset in assets {
                    if let assetId = asset.id {
                        assetIdsSet.insert(assetId)
                    }
                }
            }
        }

        // Obtener todos los assets de una sola vez
        let assetRequest = Asset.fetchRequest()
        assetRequest.predicate = NSPredicate(format: "identifier IN %@", Array(assetIdsSet))
        
        var allAssets: [Asset] = []
        do {
            allAssets = try context.fetch(assetRequest)
        } catch {
            print("Error al obtener los assets: ", error.localizedDescription)
            completion(.failure(error))
            return
        }

        // Crear empleados y asignar assets
        for item in employees {
            let employee = Employee(context: context)
            employee.identifier = item._id
            employee.name = item.name
            employee.lastName = item.lastName
            employee.email = item.email
            employee.profileId = item.profileId
            employee.employeeId = item.employee_id
            
            // Asignar assets al empleado desde la lista previamente obtenida
            if let assets = item.assetsAssigned {
                let assetsToAssign = allAssets.filter { asset in
                    assets.contains { $0.id == asset.identifier }
                }
                employee.addToAssets(NSSet(array: assetsToAssign))
                print("Se asignaron \(assetsToAssign.count) assets a empleado \(item._id)")
            }
            
            test.append(employee)
        }

        // Guardar todos los empleados y assets en una sola operación
        do {
            try context.save()
            completion(.success(employees))
        } catch {
            completion(.failure(error))
        }
    }
    
    func save(employee: EmployeeModel, profileId: String, profileName: String, completion: @escaping(Result<EmployeeModel,Error>) -> Void) {
        let item = Employee(context: context)
        item.identifier = employee._id
        item.name = employee.name
        item.lastName = employee.lastName
        item.email = employee.email
        item.employeeId = employee.employee_id
        item.profileId = profileId
        item.profileName = profileName
        item.beenCreated = true
        
        do {
            try context.save()
            completion(.success(employee))
        } catch {
            completion(.failure(error))
        }
    }
    
    func assign(assetId: String, to employeeId: String, replace oldEmployeeId: String?, completion: @escaping(Result<String, Error>) -> Void) {
        
        do {
            let assetRequest = Asset.fetchRequest()
            assetRequest.predicate = NSPredicate(format: "identifier == %@", assetId)
            assetRequest.returnsObjectsAsFaults = false
            let assetsResult = try context.fetch(assetRequest)
            guard let assetResult = assetsResult.first else {completion(.failure(WMError.failedFetchAssets)); return }
            
            let employeeRequest = Employee.fetchRequest()
            employeeRequest.returnsObjectsAsFaults = false
            employeeRequest.predicate = NSPredicate(format: "identifier == %@", employeeId)
            let employeesResult = try context.fetch(employeeRequest)
            guard let employeeResult = employeesResult.first else {completion(.failure(WMError.failedFetchEmployees)); return }
            
            if let oldEmployeeId = oldEmployeeId {
                let oldEmployeeRequest = Employee.fetchRequest()
                oldEmployeeRequest.returnsObjectsAsFaults = false
                oldEmployeeRequest.predicate = NSPredicate(format: "identifier == %@", oldEmployeeId)
                let oldEmployeesResult = try context.fetch(oldEmployeeRequest)
                if let oldEmployee = oldEmployeesResult.first {
                    oldEmployee.removeFromAssets(assetResult)
                    oldEmployee.beenUpdated = true
                    assetResult.originalAssigned = oldEmployeeId
                }
            }
            
            assetResult.assignedTo = "\(employeeResult.name ?? "") \(employeeResult.lastName ?? "") <\(employeeResult.email ?? "")>"
            assetResult.assigned = employeeId
            assetResult.beenUpdated = true
            employeeResult.addToAssets(assetResult)
            employeeResult.beenUpdated = true
            try context.save()
            completion(.success(employeeId))
        } catch {
            completion(.failure(error))
        }
    }
    
    func save(employeeProfiles: [EmployeeProfileModel], completion: @escaping(Result<[EmployeeProfileModel],Error>) -> Void) {
        for item in employeeProfiles {
            let employee = EmployeeProfile(context: context)
            employee.identifier = item._id
            employee.name = item.name
        }
        
        do {
            try context.save()
            completion(.success(employeeProfiles))
        } catch {
            completion(.failure(error))
        }
    }
    
    func save(references: [ReferenceModel], completion: @escaping(Result<[ReferenceModel],Error>) -> Void) {
        for item in references {
            let reference = Reference(context: context)
            reference.id = item._id
            reference.brand = item.brand
            reference.model = item.model
            reference.name = item.name
            reference.fileExt = item.fileExt
        }
        do {
            try context.save()
            completion(.success(references))
        } catch {
            completion(.failure(error))
        }
    }
    
    func getLocations(by id: String, and level: String, completion: @escaping(Result<[LocationModel2],Error>) -> Void) {
        let request = Location.fetchRequest()
        request.predicate = NSPredicate(format: "parent == %@ AND profileLevel == %@ ", id, level)
        request.returnsObjectsAsFaults = false
        do {
            let result = try context.fetch(request)
            var locations: [LocationModel2] = []
            for data in result {
                locations.append(LocationModel2(from: data))
            }
            completion(.success(locations))
        } catch {
            completion(.failure(error))
        }
    }
    
    func getReferences(completion:  @escaping(Result<[ReferenceModel], Error>) -> Void) {
        let request = Reference.fetchRequest()
        request.returnsObjectsAsFaults = false
        do {
            let result = try context.fetch(request)
            var references: [ReferenceModel] = []
            for data in result {
                references.append(ReferenceModel(from: data))
            }
            completion(.success(references))
        } catch {
            completion(.failure(error))
        }
    }
    
    func getEmployees(completion:  @escaping(Result<[EmployeeModel], Error>) -> Void) {
        let request = Employee.fetchRequest()
        request.relationshipKeyPathsForPrefetching = ["assets"]
        request.returnsObjectsAsFaults = true
        do {
            let result = try context.fetch(request)
            var employees: [EmployeeModel] = []
            for data in result {
                print("Empleado \(data.identifier ?? "N/A") assets: \(data.assets?.count ?? 0)")
                employees.append(EmployeeModel(from: data))
            }
            completion(.success(employees))
        } catch {
            completion(.failure(error))
        }
    }
    
    func getEmployeesToSync(completion:  @escaping(Result<[EmployeeModel], Error>) -> Void) {
        let request = Employee.fetchRequest()
        request.predicate = NSPredicate(format: "beenCreated == YES")
        request.relationshipKeyPathsForPrefetching = ["assets"]
        request.returnsObjectsAsFaults = false
        do {
            let result = try context.fetch(request)
            var employees: [EmployeeModel] = []
            for data in result {
                employees.append(EmployeeModel(from: data))
            }
            completion(.success(employees))
        } catch {
            completion(.failure(error))
        }
    }
    
    func getEmployeesToUpdate(completion:  @escaping(Result<[EmployeeModel], Error>) -> Void) {
        let request = Employee.fetchRequest()
        request.predicate = NSPredicate(format: "beenUpdated == YES AND beenCreated == NO")
        request.relationshipKeyPathsForPrefetching = ["assets"]
        request.returnsObjectsAsFaults = false
        do {
            let result = try context.fetch(request)
            var employees: [EmployeeModel] = []
            for data in result {
                employees.append(EmployeeModel(from: data))
            }
            completion(.success(employees))
        } catch {
            completion(.failure(error))
        }
    }
    
    func getEmployeeProfiles(completion:  @escaping(Result<[EmployeeProfileModel], Error>) -> Void) {
        let request = EmployeeProfile.fetchRequest()
        request.returnsObjectsAsFaults = false
        do {
            let result = try context.fetch(request)
            var profiles: [EmployeeProfileModel] = []
            for data in result {
                profiles.append(EmployeeProfileModel(profile: data))
            }
            completion(.success(profiles))
        } catch {
            completion(.failure(error))
        }
    }
    
    func tag(asset reference: ReferenceModel, location: LocationModel, locationPath: String, epc: String, userId: String, serialNumber: String, tabs: [[String: Any]], customFields: [[String: Any]], customFieldsValues: [String], employee: EmployeeModel, image: Data?, completion: @escaping(Result<Asset,Error>) -> Void) {
        print("Iniciando proceso para guardar el activo con EPC: \(epc)")

        // Verificar si el EPC tiene la longitud correcta de 24 caracteres
        guard epc.count == 24 else {
            print("EPC no tiene la longitud de 24 caracteres: \(epc)")
            completion(.failure(NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "EPC no tiene la longitud de 24 caracteres"])))
            return
        }
        
        // Verificar si el EPC ya existe
        let fetchRequest: NSFetchRequest<Asset> = Asset.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "epc == %@", epc)
        
        do {
            let fetchedAssets = try context.fetch(fetchRequest)
            if fetchedAssets.isEmpty {
                // Crear y guardar un nuevo Asset
                print("EPC no encontrado en la base de datos, creando nuevo activo.")
                let asset = Asset(context: context)
                asset.name = reference.name ?? ""
                asset.brand = reference.brand ?? ""
                asset.model = reference.model ?? ""
                asset.serial = serialNumber
                asset.epc = epc
                asset.location = location._id
                asset.locationPath = locationPath
                asset.creator = userId
                asset.identifier = userId
                asset.customFieldsTab = "pending"
                asset.referenceId = reference._id
                asset.tabs = tabs
                asset.customFields = customFields
                asset.customFieldsValues = customFieldsValues
                asset.assigned = employee._id
                asset.assignedTo = "\(employee.name) \(employee.lastName) <\(employee.email)>"
                asset.image = image
                asset.beenUpdated = true
                asset.beenCreated = true
                
                do {
                    try context.save()
                    print("Asset guardado con EPC completo: \(epc)")
                    completion(.success(asset))
                } catch {
                    print("Error al guardar el activo: \(error)")
                    completion(.failure(error))
                }
            } else {
                print("EPC ya existe: \(epc)")
                completion(.failure(NSError(domain: "", code: 409, userInfo: [NSLocalizedDescriptionKey: "ERROR: EPC Already Exists"])))
            }
        } catch {
            print("Error al verificar la existencia del EPC: \(error)")
            completion(.failure(error))
        }
    }
    
    func getAssets(completion:  @escaping(Result<[Asset],Error>) -> Void) {
        let request = Asset.fetchRequest()
        request.returnsObjectsAsFaults = false
        do {
            let result = try context.fetch(request)
            completion(.success(result))
        } catch {
            completion(.failure(error))
        }
    }
    
    func getAssetsToSync(completion:  @escaping(Result<[Asset],Error>) -> Void) {
        let request = Asset.fetchRequest()
        //        beenUpdated
        request.predicate = NSPredicate(format: "beenCreated == YES")
        request.returnsObjectsAsFaults = false
        do {
            let result = try context.fetch(request)
            completion(.success(result))
        } catch {
            completion(.failure(error))
        }
    }
    
    func getAssetsToUpdate(completion:  @escaping(Result<[Asset],Error>) -> Void) {
        let request = Asset.fetchRequest()
        request.predicate = NSPredicate(format: "beenCreated == NO") 
        request.predicate = NSPredicate(format: "beenUpdated == YES")
        request.returnsObjectsAsFaults = false
        do {
            let result = try context.fetch(request)
            completion(.success(result))
        } catch {
            completion(.failure(error))
        }
    }
    
    func resetAllData() {
        let entityNames = Self.persistentContainer.managedObjectModel.entities.map({ $0.name!})
        entityNames.forEach { [weak self] entityName in
            let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)
            
            do {
                try self?.context.execute(deleteRequest)
                try self?.context.save()
            } catch {
                print("Error: ", error.localizedDescription)
            }
        }
    }
    
    func delete(asset: Asset) {
        context.delete(asset)
        do {
            try context.save()
        } catch {
            print("Error: ", error.localizedDescription)
        }
    }
    
    //MARK: - UserDefaults
    func getWorkMode() -> WorkMode {
        let value = UserDefaults.standard.integer(forKey: WMConstants.keys.mode)
        return WorkMode(rawValue: value) ?? .online
    }
    
    func setWorkMode(_ workMode: WorkMode) {
        UserDefaults.standard.set(workMode.rawValue, forKey: WMConstants.keys.mode)
    }
    
    func getOfflineStartDate() -> Date? {
        return UserDefaults.standard.object(forKey: WMConstants.keys.startDate) as? Date
    }
    
    func setOfflineStartDate(_ date: Date?) {
        UserDefaults.standard.set(date, forKey: WMConstants.keys.startDate)
    }
    
    //MARK: Assets
    func getAssets(by locationID: String, completion:  @escaping(Result<[RealAssetModel], Error>) -> Void) {
        let request = Asset.fetchRequest()
        request.predicate = NSPredicate(format: "location == %@", locationID)
        request.returnsObjectsAsFaults = false
        do {
            let result = try context.fetch(request)
            let resultData = result.map({ RealAssetModel(asset: $0)})
            completion(.success(resultData))
        } catch {
            completion(.failure(error))
        }
    }
    
    func getAsset(by id: String, completion:  @escaping(Result<RealAssetModel?, Error>) -> Void) {
        let request = Asset.fetchRequest()
        request.predicate = NSPredicate(format: "identifier IN %@", id)
        request.returnsObjectsAsFaults = false
        do {
            let result = try context.fetch(request)
            let resultData = result.map({ RealAssetModel(asset: $0)})
            completion(.success(resultData.first))
        } catch {
            completion(.failure(error))
        }
    }
    
    func update(asset id: String, epc: String, serialNumber: String, image: Data?, completion:  @escaping(Result<Asset?, Error>) -> Void) {
        let request = Asset.fetchRequest()
        request.predicate = NSPredicate(format: "identifier == %@", id)
        request.returnsObjectsAsFaults = false
        do {
            let result = try context.fetch(request)
            if let asset = result.first {
                asset.beenUpdated = true
                asset.epc = epc
                asset.serial = serialNumber
                asset.image = image
            }
            try context.save()
            completion(.success(result.first))
        } catch {
            completion(.failure(error))
        }
    }
    
    func getAsset(EPC: String, completion:  @escaping(Result<RealAssetModel?, Error>) -> Void) {
        let request = Asset.fetchRequest()
        request.predicate = NSPredicate(format: "epc == %@", EPC)
        request.returnsObjectsAsFaults = false
        do {
            let result = try context.fetch(request)
            let resultData = result.map({ RealAssetModel(asset: $0)})
            completion(.success(resultData.first))
        } catch {
            completion(.failure(error))
        }
    }
    
    func getAssets(by assetIDs: [String], completion:  @escaping(Result<[RealAssetModel], Error>) -> Void) {
        let request = Asset.fetchRequest()
        request.predicate = NSPredicate(format: "identifier IN %@", assetIDs)
        request.returnsObjectsAsFaults = false
        do {
            let result = try context.fetch(request)
            let resultData = result.map({ RealAssetModel(asset: $0)})
            completion(.success(resultData))
        } catch {
            completion(.failure(error))
        }
    }
    
    func getAssets(searchText: String, completion:  @escaping(Result<[RealAssetModelWithLocation],Error>) -> Void) {
        let request = Asset.fetchRequest()
        let predicates =  [
            NSPredicate(format: "brand CONTAINS[c] %@ ", searchText),
            NSPredicate(format: "epc CONTAINS[c] %@ ", searchText),
            NSPredicate(format: "location CONTAINS[c] %@ ", searchText),
            NSPredicate(format: "name CONTAINS[c] %@ ", searchText),
            NSPredicate(format: "identifier CONTAINS[c] %@ ", searchText),
            NSPredicate(format: "creationDate CONTAINS[c] %@ ", searchText),
            NSPredicate(format: "responsible CONTAINS[c] %@ ", searchText),
            NSPredicate(format: "notes CONTAINS[c] %@ ", searchText),
            NSPredicate(format: "serial CONTAINS[c] %@ ", searchText),
            NSPredicate(format: "model CONTAINS[c] %@ ", searchText)
        ]
        request.predicate = NSCompoundPredicate(type: .or, subpredicates: predicates)
        request.returnsObjectsAsFaults = false
        do {
            let result = try context.fetch(request)
            let resultData = result.map({ RealAssetModelWithLocation(asset: $0)})
            completion(.success(resultData))
        } catch {
            completion(.failure(error))
        }
    }
    
    // Inventarios
    
    func getInventories(completion:  @escaping(Result<[InventoryDataModel], Error>) -> Void) {
        let request = InventorySession.fetchRequest()
        
        request.returnsObjectsAsFaults = false
        do {
            let result = try context.fetch(request)
            let resultData = result.map({ InventoryDataModel(inventorySession: $0)})
            completion(.success(resultData))
        } catch {
            completion(.failure(error))
        }
    }
    
    func getInventories(locationId: String, completion:  @escaping(Result<[InventoryDataModel], Error>) -> Void) {
        let request = InventorySession.fetchRequest()
        if !locationId.isEmpty {
            request.predicate = NSPredicate(format: "locationId == %@", locationId)
        }
        request.returnsObjectsAsFaults = false
        do {
            let result = try context.fetch(request)
            let resultData = result.map({ InventoryDataModel(inventorySession: $0)})
            completion(.success(resultData))
        } catch {
            completion(.failure(error))
        }
    }
    
    func updateInventory(by id: String, status: String, completion:  @escaping(Result<InventoryDataModel, Error>) -> Void) {
        let request = InventorySession.fetchRequest()
        request.predicate = NSPredicate(format: "identifier == %@", id)
        request.returnsObjectsAsFaults = false
        do {
            let result = try context.fetch(request)
            if let item = result.first {
                item.status = status
                item.beenUpdated = true
                try context.save()
                completion(.success(InventoryDataModel(inventorySession: item)))
            } else {
                completion(.failure(WMError.inventoryNotFound))
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    func getInventorySession(by id: String, completion:  @escaping(Result<InventoryDataModel, Error>) -> Void) {
        let request = InventorySession.fetchRequest()
        request.predicate = NSPredicate(format: "sessionId == %@", id)
        request.returnsObjectsAsFaults = false
        request.relationshipKeyPathsForPrefetching = ["assets"]
        do {
            let result = try context.fetch(request)
            if let item = result.first {
                completion(.success(InventoryDataModel(inventorySession: item)))
            } else {
                completion(.failure(WMError.inventoryNotFound))
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    func getInventorySessionToSync(completion:  @escaping(Result<[InventorySession], Error>) -> Void) {
        let request = InventorySession.fetchRequest()
        request.predicate = NSPredicate(format: "beenCreated == YES") 
        request.returnsObjectsAsFaults = false
        request.relationshipKeyPathsForPrefetching = ["assets"]
        do {
            let result = try context.fetch(request)
            completion(.success(result))
        } catch {
            completion(.failure(error))
        }
    }
    
    
    func getInventoryAssets(location: String, locationName: String, sessionId: String, inventoryName: String, type: InventoryType, completion: @escaping(Result<[AssetModel], Error>) -> Void) {
        /*
         // Quick Inventory - This level
         location: 61719f385c137b0aa434153c
         locationName: Home
         sessionId:
         inventoryName:
         type: root
         
         // Quick Inventory - This level and sublevels
         location: 61719f385c137b0aa434153c
         locationName: Home
         sessionId:
         inventoryName:
         type: subLevels
         
         // Create Inventory session - This level
         location: 61719f385c137b0aa434153c
         locationName: Home
         sessionId: session-id-20220802170016370
         inventoryName: Inventory in Home
         type: root
         
         // Create Inventory session - This level and sublevels
         location: 61719f385c137b0aa434153c
         locationName: Home
         sessionId: session-id-20220802170146696
         inventoryName: Inventory in Home
         type: subLevels
         */
        
        if sessionId.isEmpty {
            //Quick Inventory
            getQuickInventory(by: location, locationName: locationName, type: type, completion: completion)
        } else {
            // Create Inventory session
            createInventorySession(by: location, locationName: locationName, sessionId: sessionId, inventoryName: inventoryName, type: type, completion: completion)
        }
    }
    
    func getQuickInventory(by locationId: String, locationName: String, type: InventoryType, completion: @escaping(Result<[AssetModel], Error>) -> Void) {
        switch type {
        case .root:
            let request = Asset.fetchRequest()
            request.predicate = NSPredicate(format: "location == %@", locationId)
            request.returnsObjectsAsFaults = false
            do {
                let result = try context.fetch(request)
                let resultData = result.map({ AssetModel(asset: $0)})
                completion(.success(resultData))
            } catch {
                completion(.failure(error))
            }
        case .subLevels:
            let rootLocation = Location.fetchRequest()
            rootLocation.predicate = NSPredicate(format: "id == %@", locationId)
            rootLocation.returnsObjectsAsFaults = false
            
            let parentLocation = Location.fetchRequest()
            parentLocation.predicate = NSPredicate(format: "parent == %@", locationId)
            parentLocation.returnsObjectsAsFaults = false
            do {
                let rootResult = try context.fetch(rootLocation)
                let parentResult = try context.fetch(parentLocation)
                let resultLocation = rootResult + parentResult
                var arrayAssets: [Asset] = []
                for location in resultLocation {
                    let request = Asset.fetchRequest()
                    request.predicate = NSPredicate(format: "location == %@ and status == 'active'", location.id ?? "")
                    let result = try context.fetch(request)
                    arrayAssets.append(contentsOf: result)
                }
                let resultData = arrayAssets.map({ AssetModel(asset: $0)})
                completion(.success(resultData))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func createInventorySession(by locationId: String, locationName: String, sessionId: String, inventoryName: String, type: InventoryType, completion: @escaping(Result<[AssetModel], Error>) -> Void) {
        let inventorySession = InventorySession(context: context)
        inventorySession.identifier = sessionId
        inventorySession.sessionId = sessionId
        inventorySession.name = inventoryName
        inventorySession.locationId = locationId
        inventorySession.locationName = locationName
        inventorySession.status = "open"
        inventorySession.creation = getCreationDate()
        inventorySession.beenCreated = true
        inventorySession.type = type.rawValue
        
        switch type {
        case .root:
            let request = Asset.fetchRequest()
            request.predicate = NSPredicate(format: "location == %@", locationId)
            request.returnsObjectsAsFaults = false
            do {
                let result = try context.fetch(request)
                for assetResult in result {
                    print("Agregando asst \(assetResult.identifier ?? "") a session")
                    inventorySession.addToAssets(assetResult)
                    try context.save()
                }
                try context.save()
                let resultData = result.map({ AssetModel(asset: $0)})
                completion(.success(resultData))
            } catch {
                completion(.failure(error))
            }
        case .subLevels:
            let rootLocation = Location.fetchRequest()
            rootLocation.predicate = NSPredicate(format: "id == %@", locationId)
            rootLocation.returnsObjectsAsFaults = false
            
            let parentLocation = Location.fetchRequest()
            parentLocation.predicate = NSPredicate(format: "parent == %@", locationId)
            parentLocation.returnsObjectsAsFaults = false
            do {
                let rootResult = try context.fetch(rootLocation)
                let parentResult = try context.fetch(parentLocation)
                let resultLocation = rootResult + parentResult
                var arrayAssets: [Asset] = []
                for location in resultLocation {
                    let request = Asset.fetchRequest()
                    request.predicate = NSPredicate(format: "location == %@ and status == 'active'", location.id ?? "")
                    let result = try context.fetch(request)
                    for assetResult in result {
                        print("Agregando asst \(assetResult.identifier ?? "") a session")
                        inventorySession.addToAssets(assetResult)
                        try context.save()
                    }
                    arrayAssets.append(contentsOf: result)
                }
                try context.save()
                let resultData = arrayAssets.map({ AssetModel(asset: $0)})
                completion(.success(resultData))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func updateInventorySession(by sessionId: String, foundEPCS: [String], closeSession: Bool, completion: @escaping(Result<InventorySession, Error>) -> Void) {
        
        let request = InventorySession.fetchRequest()
        request.predicate = NSPredicate(format: "identifier == %@", sessionId)
        request.returnsObjectsAsFaults = false
        do {
            let result = try context.fetch(request)
            if let item = result.first {
                item.status = closeSession ? "close" : "open"
                item.beenUpdated = true
                try context.save()
                
                for epc in foundEPCS {
                    let request = Asset.fetchRequest()
                    request.predicate = NSPredicate(format: "epc == %@", epc)
                    request.returnsObjectsAsFaults = false
                    do {
                        let result = try context.fetch(request)
                        if let assetToChange = result.first {
                            assetToChange.status = "found"
                        }
                        try context.save()
                    } catch {
                        print("error: \(error.localizedDescription)")
                    }
                }
                
                completion(.success(item))
            } else {
                completion(.failure(WMError.inventoryNotFound))
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    private func getCreationDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MM yyyy HH:mm:ss"
        return dateFormatter.string(from: Date())
    }
    
    
    //    func createInventorySession(by id: String) {
    //        let inventorySession = InventorySession(context: context)
    //        inventorySession.identifier = item._id
    //        inventorySession.sessionId = item.sessionId
    //        inventorySession.name = item.name
    //        inventorySession.locationId = item.locationId
    //        inventorySession.locationName = item.locationName
    //        inventorySession.status = item.status
    //        inventorySession.creation = item.creation
    //
    //    }
    
    //    "status" : "open",
    //    "locationName" : "Home",
    //    "sessionId" : "session-id-20220801185925590",
    //    "creation" : "01\/08\/2022 18:59:41",
    //    "name" : "Inventory in Home this level",
    //    "locationId" : "61719f385c137b0aa434153c"
    
}
