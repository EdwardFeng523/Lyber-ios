//
//  getInfo.swift
//  Lyber
//
//  Created by Edward Feng on 6/13/18.
//  Copyright © 2018 Edward Feng. All rights reserved.
//

import Foundation
import UIKit

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

func sendRequest(depar_lat: String, depar_lng: String, dest_lat: String, dest_lng: String) {
    let jsonUrlStringUber = "https://lyber-server.herokuapp.com/api/uber?depar_lat=" + depar_lat + "&depar_lng=" + depar_lng + "&dest_lat=" + dest_lat + "&dest_lng=" + dest_lng
    let jsonUrlStringLyft = "https://lyber-server.herokuapp.com/api/lyft?depar_lat=" + depar_lat + "&depar_lng=" + depar_lng + "&dest_lat=" + dest_lat + "&dest_lng=" + dest_lng
    
    guard let urlUber = URL(string: jsonUrlStringUber) else { return }
    guard let urlLyft = URL(string: jsonUrlStringLyft) else { return }
    URLSession.shared.dataTask(with: urlUber) { (data, response, err) in
        guard let data = data else { return }
        do {
            let uberInfo = try JSONDecoder().decode(UberInfo.self, from: data)
            print (uberInfo)
        } catch let jsonErr {
            print("Error serializing json uber:", jsonErr)
        }
    }.resume()
    
    URLSession.shared.dataTask(with: urlLyft) { (data, response, err) in
        guard let lyftData = data else { return }
        do {
            let lyftInfo = try JSONDecoder().decode(LyftInfo.self, from: lyftData)
            print (lyftInfo)
        } catch let jsonErr {
            print("Error serializing json lyft:", jsonErr)
        }
    }.resume()
    
}
