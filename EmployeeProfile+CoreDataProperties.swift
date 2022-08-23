//
//  EmployeeProfile+CoreDataProperties.swift
//  FractalInventory
//
//  Created by Jonathan Saldivar on 18/08/22.
//
//

import Foundation
import CoreData


extension EmployeeProfile {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<EmployeeProfile> {
        return NSFetchRequest<EmployeeProfile>(entityName: "EmployeeProfile")
    }

    @NSManaged public var identifier: String?
    @NSManaged public var name: String?

}

extension EmployeeProfile : Identifiable {

}
