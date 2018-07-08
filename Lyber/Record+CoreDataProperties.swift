//
//  Record+CoreDataProperties.swift
//  
//
//  Created by Edward Feng on 7/7/18.
//
//

import Foundation
import CoreData


extension Record {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Record> {
        return NSFetchRequest<Record>(entityName: "Record")
    }

    @NSManaged public var dep_lat: Double
    @NSManaged public var dep_lng: Double
    @NSManaged public var dest_lat: Double
    @NSManaged public var dest_lng: Double
    @NSManaged public var user_lat: Double
    @NSManaged public var user_lng: Double
    @NSManaged public var time_stamp: NSDate?
    @NSManaged public var company: String?
    @NSManaged public var priority: String?
    @NSManaged public var product: String?
    @NSManaged public var price_max: Double
    @NSManaged public var price_min: Double
    @NSManaged public var dep_name: String?
    @NSManaged public var dest_name: String?
    @NSManaged public var eta: Int32
    @NSManaged public var uuid: String?
    @NSManaged public var real_price: Double

}
