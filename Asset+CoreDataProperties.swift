//
//  Asset+CoreDataProperties.swift
//  FractalInventory
//
//  Created by Jonathan Saldivar on 29/07/22.
//
//

import Foundation
import CoreData


extension Asset {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Asset> {
        return NSFetchRequest<Asset>(entityName: "Asset")
    }

    @NSManaged public var assigned: String?
    @NSManaged public var assignedTo: String?
    @NSManaged public var brand: String?
    @NSManaged public var creationDate: String?
    @NSManaged public var creator: String?
    @NSManaged public var customFields: [[String : Any]]?
    @NSManaged public var customFieldsTab: String?
    @NSManaged public var customFieldsValues: [String]?
    @NSManaged public var epc: String?
    @NSManaged public var fileExt: String?
    @NSManaged public var identifier: String?
    @NSManaged public var image: Data?
    @NSManaged public var imageURL: String?
    @NSManaged public var labelingDate: String?
    @NSManaged public var labelingUser: String?
    @NSManaged public var location: String?
    @NSManaged public var locationPath: String?
    @NSManaged public var model: String?
    @NSManaged public var name: String?
    @NSManaged public var notes: String?
    @NSManaged public var parent: String?
    @NSManaged public var price: String?
    @NSManaged public var purchaseDate: String?
    @NSManaged public var purchasePrice: String?
    @NSManaged public var quantity: Int32
    @NSManaged public var referenceId: String?
    @NSManaged public var responsible: String?
    @NSManaged public var serial: String?
    @NSManaged public var status: String?
    @NSManaged public var tabs: [[String: Any]]?
    @NSManaged public var totalPrice: String?
    @NSManaged public var updateDate: String?
    @NSManaged public var beenCreated: Bool
    @NSManaged public var beenUpdated: Bool

}

extension Asset : Identifiable {

}
