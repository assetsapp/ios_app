//
//  Reference+CoreDataProperties.swift
//  
//
//  Created by Jonathan Saldivar on 06/04/22.
//
//

import Foundation
import CoreData


extension Reference {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Reference> {
        return NSFetchRequest<Reference>(entityName: "Reference")
    }

    @NSManaged public var id: String?
    @NSManaged public var brand: String?
    @NSManaged public var model: String?
    @NSManaged public var name: String?
    @NSManaged public var fileExt: String?

}
