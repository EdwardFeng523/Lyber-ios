//
//  getInfo.swift
//  Lyber
//
//  Created by Edward Feng on 6/13/18.
//  Copyright © 2018 Edward Feng. All rights reserved.
//

import Foundation

/**
 Contains all of the code used for parsing json http response
 **/

struct LogItem: Decodable {
    let id: String
    let deparLat: Double
    let deparLng: Double
    let destLat: Double
    let destLng: Double
    let company: String
    let productName: String
    let priceMin: Double
    let priceMax: Double
    let eta: Int
    let priority: String
}

struct ServerEstimate: Decodable {
    let prices: [EstimateItem]
    let id: String
}

struct EstimateItem: Decodable {
    let company: String
    let display_name: String
    let product_id: String
    let max_estimate: Int
    let min_estimate: Int
    let distance: Double
    let duration: Int
    let currency_code: String
    let eta: Int?
}




struct AddressComponent: Decodable {
    let long_name: String
    let short_name: String
    let types: [String]
}

struct Location: Decodable {
    let lat: Double
    let lng: Double
}

struct Viewport: Decodable {
    let northeast: Location
    let southwest: Location
}

struct Geometry: Decodable {
    let location: Location
    let location_type: String
    let viewport: Viewport
}

struct Result: Decodable {
    let address_components: [AddressComponent]
    let formatted_address: String
    let geometry: Geometry
    let place_id: String
    let types: [String]
}

struct LocationInfo: Decodable {
    let results: [Result]
    let status: String
}

struct LyberItem {
    let company: String
    let type: String
    let description: String
    let priceRange: String
    let high: Double
    let low: Double
    let distance: Double
    let duration: Int
    let estimatedArrival: Int
    let product_id: String
    let display_name: String
    let id: String
}

struct History {
    let dep: String
    let dest: String
    let time: NSDate
    let high: Double
    let low: Double
    let display_name: String
}

func lyftPriceRange(low: Int, high: Int) -> String {
    return "$" + String(low) + "-" + String(high)
}

func lyberDescription(type: String) -> String {
    switch type {
    case "Lyft":
        return "4 seats"
    case "Lyft Plus":
        return "6 seats"
    case "Lyft Premier":
        return "4 seats, high-end"
    case "Lyft Lux":
        return "4 seats, black car"
    case "Lyft Lux SUV":
        return "6 seats, black car"
    case "UberX":
        return "4 seats"
    case "UberXL":
        return "6 seats"
    case "Black":
        return "4 seats, luxury black"
    case "Select":
        return "4 seats, high-end"
    case "Black SUV":
        return "6 seats, luxury black"
    default:
        return type
    }
}

func lyberType(type: String) -> String {
    switch type {
    case "lyft":
        return "Lyft"
    case "lyft_plus":
        return "Lyft Plus"
    case "lyft_premier":
        return "Lyft Premier"
    case "lyft_lux":
        return "Lyft Lux"
    case "lyft_luxsuv":
        return "Lyft Lux SUV"
    case "UberX":
        return "UberX"
    case "UberXL":
        return "UberXL"
    case "Black":
        return "Uber Black"
    case "Select":
        return "Uber Select"
    case "Black SUV":
        return "Uber Black SUV"
    default:
        return type
    }
}




// Below are deprecated structs for parsing json from the old api
struct UberInfo: Decodable {
    let prices: [UberItem]
}

struct UberItem: Decodable {
    let localized_display_name: String
    let distance: Double
    let display_name: String
    let product_id: String
    let high_estimate: Int
    let low_estimate: Int
    let duration: Int
    let estimate: String
    let currency_code: String
}

struct LyftInfo: Decodable {
    let cost_estimates: [LyftItem]
}

struct LyftItem: Decodable {
    let ride_type: String
    let estimated_duration_seconds: Int
    let estimated_distance_miles: Double
    let price_quote_id: String
    let estimated_cost_cents_max: Int
    let primetime_percentage: String
    let is_valid_estimate: Bool
    let currency: String
    let cost_token: String?
    let estimated_cost_cents_min: Int
}
