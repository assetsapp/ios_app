//
//  Asset+CoreDataProperties.swift
//  
//
//  Created by Jonathan Saldivar on 23/04/22.
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
    @NSManaged public var creator: String?
    @NSManaged public var customFields: [[String : Any]]?
    @NSManaged public var customFieldsTab: String?
    @NSManaged public var customFieldsValues: [String]?
    @NSManaged public var epc: [String]?
    @NSManaged public var location: String?
    @NSManaged public var locationPath: String?
    @NSManaged public var model: String?
    @NSManaged public var name: String?
    @NSManaged public var referenceId: String?
    @NSManaged public var serial: String?
    @NSManaged public var tabs: [[String: Any]]?
    @NSManaged public var userId: String?
    @NSManaged public var image: Data?

}
