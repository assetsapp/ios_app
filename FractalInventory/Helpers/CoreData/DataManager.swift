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
    let container = NSPersistentContainer(name: "Inventory")
    
    init() {
        container.loadPersistentStores { descrip, error in
            if let error = error {
                print("Core data Error: \(error.localizedDescription)")
            }
        }
    }
    
    //MARK: - CoreData
    
    func save(locations: [LocationModel2], completion: @escaping(Result<[LocationModel2],Error>) -> Void) {
        for item in locations {
            let location = Location(context: container.viewContext)
            location.id = item._id
            location.name = item.name
            location.profileName = item.profileName
            location.profileLevel = item.profileLevel
            location.parent = item.parent
            location.assetsCount = 0 //Int32(item.assetsCount)
            location.childrenCount = Int32(item.childrenCount)
        }
        
        do {
            try container.viewContext.save()
            completion(.success(locations))
        } catch {
            completion(.failure(error))
        }
    }
    
    func save(employees: [EmployeeModel], completion: @escaping(Result<[EmployeeModel],Error>) -> Void) {
        for item in employees {
            let employee = Employee(context: container.viewContext)
            employee.id = item._id
            employee.name = item.name
            employee.lastName = item.lastName
            employee.email = item.email
        }
        
        do {
            try container.viewContext.save()
            completion(.success(employees))
        } catch {
            completion(.failure(error))
        }
    }
    
    func save(references: [ReferenceModel], completion: @escaping(Result<[ReferenceModel],Error>) -> Void) {
        for item in references {
            let reference = Reference(context: container.viewContext)
            reference.id = item._id
            reference.brand = item.brand
            reference.model = item.model
            reference.name = item.name
            reference.fileExt = item.fileExt
        }
        do {
            try container.viewContext.save()
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
            let result = try container.viewContext.fetch(request)
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
            let result = try container.viewContext.fetch(request)
            var references: [ReferenceModel] = []
            for data in result {
                references.append(ReferenceModel(from: data))
            }
            completion(.success(references))
        } catch {
            completion(.failure(error))
        }
    }
    
    func getEmployees(completion:  @escaping(Result<[EmployeeModel],Error>) -> Void) {
        let request = Employee.fetchRequest()
        request.returnsObjectsAsFaults = false
        do {
            let result = try container.viewContext.fetch(request)
            var employees: [EmployeeModel] = []
            for data in result {
                employees.append(EmployeeModel(from: data))
            }
            completion(.success(employees))
        } catch {
            completion(.failure(error))
        }
    }
    
    func tag(asset reference: ReferenceModel, location: LocationModel, locationPath: String, epc: [String], userId: String, serialNumber: String, tabs: [[String: Any]], customFields: [[String: Any]], customFieldsValues: [String], employee: EmployeeModel, image: Data?, completion: @escaping(Result<Asset,Error>) -> Void) {
        
        let asset = Asset(context: container.viewContext)

        asset.name = reference.name ?? ""
        asset.brand = reference.brand ?? ""
        asset.model = reference.model ?? ""
        asset.serial = serialNumber
        asset.epc = epc
        asset.location = location._id
        asset.locationPath = locationPath
        asset.creator = userId
        asset.userId = userId
        asset.customFieldsTab = "pending"
        asset.referenceId = reference._id
        asset.tabs = tabs
        asset.customFields = customFields
        asset.customFieldsValues = customFieldsValues
        asset.assigned = employee._id
        asset.assignedTo = "\(employee.name) \(employee.lastName) <\(employee.email)>"
        asset.image = image
        
        do {
            try container.viewContext.save()
            completion(.success(asset))
        } catch {
            completion(.failure(error))
        }
    }
    
    func getAssets(completion:  @escaping(Result<[Asset],Error>) -> Void) {
        let request = Asset.fetchRequest()
        request.returnsObjectsAsFaults = false
        do {
            let result = try container.viewContext.fetch(request)
            completion(.success(result))
        } catch {
            completion(.failure(error))
        }
    }
    
    func resetAllData() {
        let entityNames = container.managedObjectModel.entities.map({ $0.name!})
        entityNames.forEach { [weak self] entityName in
            let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)
            
            do {
                try self?.container.viewContext.execute(deleteRequest)
                try self?.container.viewContext.save()
            } catch {
                print("Error: ", error.localizedDescription)
            }
        }
    }
    
    func delete(asset: Asset) {
        container.viewContext.delete(asset)
        do {
            try container.viewContext.save()
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
}
