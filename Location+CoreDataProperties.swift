//
//  Location+CoreDataProperties.swift
//  FractalInventory
//
//  Created by Jonathan Saldivar on 18/08/22.
//
//

import Foundation
import CoreData


extension Location {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Location> {
        return NSFetchRequest<Location>(entityName: "Location")
    }

    @NSManaged public var assetsCount: Int32
    @NSManaged public var childrenCount: Int32
    @NSManaged public var id: String?
    @NSManaged public var name: String?
    @NSManaged public var parent: String?
    @NSManaged public var profileLevel: String?
    @NSManaged public var profileName: String?

}

extension Location : Identifiable {

}
