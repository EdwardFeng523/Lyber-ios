//
//  ViewController.swift
//  Lyber
//
//  Created by Edward Feng on 6/11/18.
//  Copyright © 2018 Edward Feng. All rights reserved.
//

import UIKit
import GooglePlaces
import UberCore
import UberRides
import GoogleMaps



class ViewController: UIViewController
{
    // Booleans for autocomplete view controller to know which one is currently being edited.
    var fromPressed: Bool = false
    var toPressed: Bool = false
    
    // Coordinates
    var fromCoord: CLLocationCoordinate2D? = nil
    
    var toCoord: CLLocationCoordinate2D? = nil
    
    // List of items for display and comparison.
    var items: [LyberItem] = [] { didSet{
        print ("items were set")
        displayTable.reloadData()
        spinner.stopAnimating()
    } }
    
    // Storing current locations
    var currentLoc: CLLocation = CLLocation(latitude: 0, longitude: 0)
    {
        didSet{
            (self.view.subviews[0] as? GMSMapView)?.animate(toLocation: currentLoc.coordinate)
            
        }
    }
    
    
    let locationManager = CLLocationManager()
    
    
    
    
    
    @IBOutlet weak var displayTable: UITableView!
    
    // Spinner indicator
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        displayTable.delegate = self
        displayTable.dataSource = self
        
        // Ask for Authorisation from the User.
        self.locationManager.requestAlwaysAuthorization()
        
        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
        
        let camera = GMSCameraPosition.camera(withLatitude: 29.76328, longitude: -95.36327, zoom: 12.0)
        let mapView = GMSMapView.map(withFrame: CGRect(origin: CGPoint(x: 0,y: 0), size: CGSize(width: self.view.bounds.width, height: self.view.bounds.height)), camera: camera)
        self.view.insertSubview(mapView, at: 0)
        self.displayTable.alpha = 0.5
    }
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        print ("This would rather never happen but you did receive a memory warning!")
    }
    
    
    @IBOutlet weak var from: UITextField!
    
    
    // Action listener for locating the current location.
    @IBAction func locate(_ sender: Any) {
        let jsonUrlStringLoc = "https://maps.googleapis.com/maps/api/geocode/json?latlng=" + String(currentLoc.coordinate.latitude) + "," + String(currentLoc.coordinate.longitude) + "&key=AIzaSyAg-s2u1gxtock_vf16pzHu-eh04je99qQ"
        guard let urlLoc = URL(string: jsonUrlStringLoc) else { return }
        
        URLSession.shared.dataTask(with: urlLoc) { [weak self] (data, response, err) in
            guard let data = data else { return }
            do {
                let locationInfo = try JSONDecoder().decode(LocationInfo.self, from: data)
                print("results:" , locationInfo)
                print(locationInfo.results[0].formatted_address)
                DispatchQueue.main.async {
                    self?.from.text = locationInfo.results[0].formatted_address
                    self?.fromCoord = self?.currentLoc.coordinate
                }
            } catch let jsonErr {
                print("Error serializing json uber:", jsonErr)
            }
        }.resume()
    }
    
    
    // From button triggers the autocomplete view controller.
    @IBAction func fromButton(_ sender: Any) {
        let autocompleteControllerFrom = GMSAutocompleteViewController()
        autocompleteControllerFrom.delegate = self
        
        fromPressed = true
        present(autocompleteControllerFrom, animated: true, completion: nil)
    }
    
    @IBOutlet weak var to: UITextField!
    
    // To button triggers the autocomplete view controller.
    @IBAction func toButton(_ sender: Any) {
        let autocompleteControllerTo = GMSAutocompleteViewController()
        autocompleteControllerTo.delegate = self
        
        toPressed = true
        present(autocompleteControllerTo, animated: true, completion: nil)
    }
    
    // Do the actual lyber call, make two http requests.
    @IBAction func lyber(_ sender: Any) {
        if (fromCoord == nil || toCoord == nil) {
            let alert = UIAlertController(title: "Error", message: "You must provide a source and a destination to use Lyber", preferredStyle: UIAlertControllerStyle.alert)
            let action = UIAlertAction(title: "Got it", style: UIAlertActionStyle.default)
            alert.addAction(action)
            present(alert, animated: true, completion: nil)
        } else {
            sendRequest(depar_lat: String(fromCoord!.latitude), depar_lng: String(fromCoord!.longitude), dest_lat: String(toCoord!.latitude), dest_lng: String(toCoord!.longitude))
        }
    }
    
    // Do the two http requests.
    func sendRequest(depar_lat: String, depar_lng: String, dest_lat: String, dest_lng: String) {
        let jsonUrlStringUber = "https://lyber-server.herokuapp.com/api/uber?depar_lat=" + depar_lat + "&depar_lng=" + depar_lng + "&dest_lat=" + dest_lat + "&dest_lng=" + dest_lng
        let jsonUrlStringLyft = "https://lyber-server.herokuapp.com/api/lyft?depar_lat=" + depar_lat + "&depar_lng=" + depar_lng + "&dest_lat=" + dest_lat + "&dest_lng=" + dest_lng
        
        let jsonUrlStringEstimate = "https://lyber-server.herokuapp.com/api/estimate?depar_lat=" + depar_lat + "&depar_lng=" + depar_lng + "&dest_lat=" + dest_lat + "&dest_lng=" + dest_lng
        
        var uberFinished: Bool = false
        var lyftFinished: Bool = false
        
        print ("url I sent", jsonUrlStringUber)
        
        guard let urlUber = URL(string: jsonUrlStringUber) else { return }
        guard let urlLyft = URL(string: jsonUrlStringLyft) else { return }
        guard let urlEstimate = URL(string: jsonUrlStringEstimate) else { return }
        
        var lst: [LyberItem] = []
        
//        // The first request.
//        URLSession.shared.dataTask(with: urlUber) { (data, response, err) in
//            guard let data = data else { return }
//            do {
//                let uberInfo = try JSONDecoder().decode(UberInfo.self, from: data)
//                print (uberInfo)
//                for elementUber in uberInfo.prices {
//                    let new_item = LyberItem(type: lyberType(type: elementUber.display_name) , description: lyberDescription(type: elementUber.display_name), priceRange: elementUber.estimate, high: Double(elementUber.high_estimate), low: Double(elementUber.low_estimate), distance: elementUber.distance, duration: elementUber.duration, estimatedArrival: "unavailable")
//                    lst.append(new_item)
//                }
//                print ("uber lst appended")
//                uberFinished = true
//            } catch let jsonErr {
//                print("Error serializing json uber:", jsonErr)
//            }
//        }.resume()
//
//        // The second request.
//        URLSession.shared.dataTask(with: urlLyft) { (data, response, err) in
//            guard let lyftData = data else { return }
//            do {
//                let lyftInfo = try JSONDecoder().decode(LyftInfo.self, from: lyftData)
//                for elementLyft in lyftInfo.cost_estimates {
//                    let new_item1 = LyberItem(type: lyberType(type: elementLyft.ride_type), description: lyberDescription(type: elementLyft.ride_type), priceRange: lyftPriceRange(low: elementLyft.estimated_cost_cents_min, high: elementLyft.estimated_cost_cents_max), high: Double(elementLyft.estimated_cost_cents_max), low: Double(elementLyft.estimated_cost_cents_min), distance: elementLyft.estimated_distance_miles, duration: elementLyft.estimated_duration_seconds, estimatedArrival: "unavailable")
//                    lst.append(new_item1)
//                }
//                print ("lyft slst appended")
//                print (lyftInfo)
//                lyftFinished = true
//            } catch let jsonErr {
//                print("Error serializing json lyft:", jsonErr)
//            }
//        }.resume()
        
        spinner.startAnimating()
        URLSession.shared.dataTask(with: urlEstimate) { [weak self] (data, response, err) in
            guard let estimateData = data else { return }
            do {
                let estimateInfo = try JSONDecoder().decode(ServerEstimate.self, from: estimateData)
                for elementInfo in estimateInfo.prices {
                    let new_item_estimate = LyberItem(type: lyberType(type: elementInfo.display_name), description: lyberDescription(type: elementInfo.display_name), priceRange: lyftPriceRange(low: elementInfo.min_estimate, high: elementInfo.max_estimate), high: Double(elementInfo.max_estimate), low: Double(elementInfo.min_estimate), distance: elementInfo.distance, duration: elementInfo.duration, estimatedArrival: "unavailable", product_id: elementInfo.product_id)
                    lst.append(new_item_estimate)
                }
                guard let from_lat = self?.fromCoord!.latitude else {return }
                guard let from_lng = self?.fromCoord!.longitude else {return }
                guard let to_lat = self?.toCoord!.latitude else {return }
                guard let to_lng = self?.toCoord!.longitude else {return }
                if (String(from_lat) == depar_lat
                    && String(to_lat) == dest_lat
                    && String(from_lng) == depar_lng
                    && String(to_lng) == dest_lng) {
                    DispatchQueue.main.async {
                        // Go back to the main queue to update the gui.
                        self?.items = lst
                        self?.displayTable.separatorStyle = UITableViewCellSeparatorStyle.singleLine
                    }
                }
            } catch let jsonErr {
                print ("Error serializing json Estimate:", jsonErr)
            }
        }.resume()
        
        
//        // Do animation and started waiting for the response.
//        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
//            while (!uberFinished || !lyftFinished) {
//            }
//            guard let from_lat = self?.fromCoord!.latitude else {return }
//            guard let from_lng = self?.fromCoord!.longitude else {return }
//            guard let to_lat = self?.toCoord!.latitude else {return }
//            guard let to_lng = self?.toCoord!.longitude else {return }
//            if (String(from_lat) == depar_lat
//                && String(to_lat) == dest_lat
//                && String(from_lng) == depar_lng
//                && String(to_lng) == dest_lng) {
//                DispatchQueue.main.async {
//                    // Go back to the main queue to update the gui.
//                    self?.items = lst
//                    self?.displayTable.separatorStyle = UITableViewCellSeparatorStyle.singleLine
//                }
//            }
//
//        }
    }

    
}

// As an extension for autocomplete view controller.
extension ViewController: GMSAutocompleteViewControllerDelegate {
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        if (fromPressed == true) {
            from.text = place.name
            fromCoord = place.coordinate
        } else {
            to.text = place.name
            toCoord = place.coordinate
        }
        fromPressed = false
        toPressed = false
        self.dismiss(animated: true, completion: nil)
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        fromPressed = false
        toPressed = false
        self.dismiss(animated: true, completion: nil)
    }

}

// As an extension for UITableView
extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "customCell") as! CustomTableViewCell
        cell.type.text = items[indexPath.row].type
        cell.arrivalTime.text = items[indexPath.row].description
        cell.distance.text = String(items[indexPath.row].distance) + "mi"
        cell.priceRange.text = items[indexPath.row].priceRange
        return cell
    }

}

// As an extension for CLLocationManagerDelegate
extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLoc = locations[0]
    }
}

