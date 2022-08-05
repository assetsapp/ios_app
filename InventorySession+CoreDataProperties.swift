//
//  InventorySession+CoreDataProperties.swift
//  FractalInventory
//
//  Created by Jonathan Saldivar on 01/08/22.
//
//

import Foundation
import CoreData


extension InventorySession {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<InventorySession> {
        return NSFetchRequest<InventorySession>(entityName: "InventorySession")
    }

    @NSManaged public var creation: String?
    @NSManaged public var identifier: String?
    @NSManaged public var locationId: String?
    @NSManaged public var locationName: String?
    @NSManaged public var name: String?
    @NSManaged public var sessionId: String?
    @NSManaged public var status: String?
    @NSManaged public var assets: NSSet?
    @NSManaged public var beenCreated: Bool
    @NSManaged public var beenUpdated: Bool
    @NSManaged public var type: String?
}

// MARK: Generated accessors for assets
extension InventorySession {

    @objc(addAssetsObject:)
    @NSManaged public func addToAssets(_ value: Asset)

    @objc(removeAssetsObject:)
    @NSManaged public func removeFromAssets(_ value: Asset)

    @objc(addAssets:)
    @NSManaged public func addToAssets(_ values: NSSet)

    @objc(removeAssets:)
    @NSManaged public func removeFromAssets(_ values: NSSet)

}

extension InventorySession : Identifiable {

}
