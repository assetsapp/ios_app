//
//  Employee+CoreDataProperties.swift
//  FractalInventory
//
//  Created by Jonathan Saldivar on 18/08/22.
//
//

import Foundation
import CoreData


extension Employee {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Employee> {
        return NSFetchRequest<Employee>(entityName: "Employee")
    }

    @NSManaged public var beenUpdated: Bool
    @NSManaged public var beenCreated: Bool
    @NSManaged public var email: String?
    @NSManaged public var identifier: String?
    @NSManaged public var lastName: String?
    @NSManaged public var name: String?
    @NSManaged public var profileId: String?
    @NSManaged public var profileName: String?
    @NSManaged public var assets: NSSet?

}

// MARK: Generated accessors for assets
extension Employee {

    @objc(addAssetsObject:)
    @NSManaged public func addToAssets(_ value: Asset)

    @objc(removeAssetsObject:)
    @NSManaged public func removeFromAssets(_ value: Asset)

    @objc(addAssets:)
    @NSManaged public func addToAssets(_ values: NSSet)

    @objc(removeAssets:)
    @NSManaged public func removeFromAssets(_ values: NSSet)

}

extension Employee : Identifiable {

}
