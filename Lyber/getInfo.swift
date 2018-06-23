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

struct LyberItem {
    let type: String
    let description: String
    let priceRange: String
    let high: Double
    let low: Double
    let distance: Double
    let duration: Int
    let estimatedArrival: String
}

func lyftPriceRange(low: Int, high: Int) -> String {
    return "$" + String(low/100) + "-" + String(high/100)
}

func lyberDescription(type: String) -> String {
    switch type {
    case "lyft":
        return "4 seats"
    case "lyft_plus":
        return "6 seats"
    case "lyft_premier":
        return "4 seats, high-end"
    case "lyft_lux":
        return "4 seats, black car"
    case "lyft_luxsuv":
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
        return ""
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
        return ""
    }
}
