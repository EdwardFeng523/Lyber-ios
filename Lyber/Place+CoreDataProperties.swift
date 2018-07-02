//
//  Place+CoreDataProperties.swift
//  
//
//  Created by Edward Feng on 7/1/18.
//
//

import Foundation
import CoreData


extension Place {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Place> {
        return NSFetchRequest<Place>(entityName: "Place")
    }

    @NSManaged public var tag: String?
    @NSManaged public var name: String?
    @NSManaged public var lat: Double
    @NSManaged public var lng: Double

}
