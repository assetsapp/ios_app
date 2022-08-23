//
//  Reference+CoreDataProperties.swift
//  FractalInventory
//
//  Created by Jonathan Saldivar on 18/08/22.
//
//

import Foundation
import CoreData


extension Reference {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Reference> {
        return NSFetchRequest<Reference>(entityName: "Reference")
    }

    @NSManaged public var brand: String?
    @NSManaged public var fileExt: String?
    @NSManaged public var id: String?
    @NSManaged public var model: String?
    @NSManaged public var name: String?

}

extension Reference : Identifiable {

}
