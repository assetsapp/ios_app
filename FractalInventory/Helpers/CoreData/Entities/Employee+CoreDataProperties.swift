//
//  Employee+CoreDataProperties.swift
//  
//
//  Created by Jonathan Saldivar on 06/04/22.
//
//

import Foundation
import CoreData


extension Employee {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Employee> {
        return NSFetchRequest<Employee>(entityName: "Employee")
    }

    @NSManaged public var identifier: String?
    @NSManaged public var name: String?
    @NSManaged public var lastName: String?
    @NSManaged public var email: String?
    @NSManaged public var profileName: String?
    @NSManaged public var profileId: String?
    @NSManaged public var beenCreated: Bool
}
