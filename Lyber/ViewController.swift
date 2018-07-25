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
import CoreLocation
import Alamofire
import SwiftyJSON

class ViewController: UIViewController, GMSAutocompleteViewControllerDelegate
{
    // Booleans for autocomplete view controller to know which one is currently being edited.
    var fromPressed: Bool = false
    var toPressed: Bool = false
    
    var fromMarker = GMSMarker(position: CLLocationCoordinate2D(latitude: 0, longitude: 0))
    var toMarker = GMSMarker(position: CLLocationCoordinate2D(latitude: 0, longitude: 0))
    
    var sortedByTime: Bool = false
    
    // Coordinates
    var fromCoord: CLLocationCoordinate2D? = nil
    {
        didSet{
            self.fromMarker.opacity = 1
            self.fromMarker.position = fromCoord!
            if (self.toCoord != nil) {
                let bounds = GMSCoordinateBounds(coordinate: fromCoord!, coordinate: toCoord!)
                (self.view.subviews[0] as? GMSMapView)?.animate(with: GMSCameraUpdate.fit(bounds, withPadding: 100))
                drawPath(startLocation: (fromCoord)!, endLocation: (toCoord)!)
            } else {
                (self.view.subviews[0] as? GMSMapView)?.animate(toLocation: fromCoord!)
            }
        }
    }
    
    var toCoord: CLLocationCoordinate2D? = nil
    {
        didSet{
            toMarker.position = toCoord!
            toMarker.opacity = 1
            if (fromCoord != nil) {
                let bounds = GMSCoordinateBounds(coordinate: (fromCoord)!, coordinate: (toCoord)!)
                print ("north east", bounds.northEast)
                (self.view.subviews[0] as? GMSMapView)?.animate(with: GMSCameraUpdate.fit(bounds, withPadding: 100))
                drawPath(startLocation: (fromCoord)!, endLocation: (toCoord)!)
            } else {
                (self.view.subviews[0] as? GMSMapView)?.animate(toLocation: toCoord!)
            }
        }
    }
    
    var mapView: GMSMapView!
    
    var polylines: [GMSPolyline] = []
    
    // List of items for display and comparison.
    var items: [LyberItem] = []
    {
        didSet{
            print ("items were set")
            displayTable.reloadData()
            spinner.stopAnimating()
            self.displayTable.alpha = 0.8
        }
    }
    
    // The custom google map marker representing the user's current location.
    var circle = GMSMarker(position: CLLocationCoordinate2D(latitude: 0, longitude: 0))
    
    // Storing current locations
    var currentLoc: CLLocation = CLLocation(latitude: 0, longitude: 0)
    {
        didSet{
            circle.position = currentLoc.coordinate
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
        self.mapView = GMSMapView.map(withFrame: CGRect(origin: CGPoint(x: 0,y: 0), size: CGSize(width: self.view.bounds.width, height: self.view.bounds.height)), camera: camera)
        self.view.insertSubview(self.mapView, at: 0)
        
        circle.icon = UIImage(named: "currentLoc")
        circle.map = mapView
        
        fromMarker.title = "From"
        fromMarker.icon = UIImage(named: "dep_marker")
        fromMarker.map = mapView
        fromMarker.opacity = 0
        fromMarker.isDraggable = true
        
        toMarker.title = "To"
        toMarker.icon = UIImage(named: "marker")
        toMarker.map = mapView
        toMarker.opacity = 1
        self.displayTable.alpha = 0
        mapView.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if (fromCoord != nil) {
            fromMarker.position = fromCoord!
        }
        if (toCoord != nil) {
            toMarker.position = toCoord!
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        print ("This would rather never happen but you did receive a memory warning!")
    }
    
    // Get saved locations
    
    @IBAction func fromBlue(_ sender: Any) {
        let result = RecordViewController.fetchPlace(tag: "blue")
        if result.count == 0 {
            
        } else {
            from.text = result[0].name
            fromCoord = CLLocationCoordinate2D(latitude: result[0].lat, longitude: result[0].lng)
        }
    }
    
    @IBAction func fromRed(_ sender: Any) {
        let result = RecordViewController.fetchPlace(tag: "red")
        if result.count == 0 {
            
        } else {
            from.text = result[0].name
            fromCoord = CLLocationCoordinate2D(latitude: result[0].lat, longitude: result[0].lng)
        }
    }
    
    @IBAction func toBlue(_ sender: Any) {
        let result = RecordViewController.fetchPlace(tag: "blue")
        if result.count == 0 {
            
        } else {
            to.text = result[0].name
            toCoord = CLLocationCoordinate2D(latitude: result[0].lat, longitude: result[0].lng)
        }
    }
    
    @IBAction func toRed(_ sender: Any) {
        let result = RecordViewController.fetchPlace(tag: "red")
        if result.count == 0 {
            
        } else {
            to.text = result[0].name
            toCoord = CLLocationCoordinate2D(latitude: result[0].lat, longitude: result[0].lng)
        }
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
    
    @IBAction func hideTable(_ sender: UIButton) {
        displayTable.alpha = 0
    }
    
    @IBAction func toTouched(_ sender: Any) {
        let autocompleteControllerTo = GMSAutocompleteViewController()
        autocompleteControllerTo.delegate = self
        let filter = GMSAutocompleteFilter()
        filter.country = "US"
        autocompleteControllerTo.autocompleteFilter = filter
        
        toPressed = true
        present(autocompleteControllerTo, animated: true, completion: nil)
    }
    
    @IBAction func fromTouched(_ sender: Any) {
        let autocompleteControllerFrom = GMSAutocompleteViewController()
        autocompleteControllerFrom.delegate = self
        let filter = GMSAutocompleteFilter()
        filter.country = "US"
        
        autocompleteControllerFrom.autocompleteFilter = filter

        fromPressed = true
        present(autocompleteControllerFrom, animated: true, completion: nil)
    }
    
    @IBAction func sortByPrice(_ sender: Any) {
        items.sort { (itemA, itemB) -> Bool in
            if (itemA.low != itemB.low) {
                return itemA.low < itemB.low
            } else {
                return itemA.high < itemB.high
            }
        }
        displayTable.reloadData()
        sortedByTime = false
    }
    
    @IBAction func sortByTime(_ sender: Any) {
        items.sort { (itemA, itemB) -> Bool in
            return itemA.estimatedArrival < itemB.estimatedArrival
        }
        displayTable.reloadData()
        sortedByTime = true
    }
    
    @IBOutlet weak var to: UITextField!
    
    func drawPath(startLocation: CLLocationCoordinate2D, endLocation: CLLocationCoordinate2D)
    {
        let origin = "\(startLocation.latitude),\(startLocation.longitude)"
        let destination = "\(endLocation.latitude),\(endLocation.longitude)"
        
        
        let url = "https://maps.googleapis.com/maps/api/directions/json?origin=\(origin)&destination=\(destination)&mode=driving"
        
        Alamofire.request(url).responseJSON { response in
            
            print(response.request as Any)  // original URL request
            print(response.response as Any) // HTTP URL response
            print(response.data as Any)     // server data
            print(response.result as Any)   // result of response serialization
            
            print("[line 282]: " + origin)
            
            do {
                let json = try JSON(data: response.data!)
                let routes = json["routes"].arrayValue
                
                for line in (self.polylines) {
                    line.map = nil
                }
                
                // print route using Polyline
                for route in routes
                {
                    DispatchQueue.main.async {
                        let routeOverviewPolyline = route["overview_polyline"].dictionary
                        let points = routeOverviewPolyline?["points"]?.stringValue
                        let path = GMSPath.init(fromEncodedPath: points!)
                        let polyline = GMSPolyline.init(path: path)
                        polyline.strokeWidth = 4
                        polyline.strokeColor = UIColor.black
                        polyline.map = self.mapView
                        self.polylines.append(polyline)
                        print ("set one line")
                    }
                }
            } catch {
                print ("error drawing route")
                return
            }
            
        }
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
        let jsonUrlStringEstimate = "https://lyber.co/api/estimate?depar_lat=" + depar_lat + "&depar_lng=" + depar_lng + "&dest_lat=" + dest_lat + "&dest_lng=" + dest_lng
        
        
        // The code using alamofire
        var lst: [LyberItem] = []
        
        spinner.startAnimating()
        Alamofire.request(jsonUrlStringEstimate).responseJSON { response in
            do {
                let json = try JSON(data: response.data!)
                let priceItems = json["prices"].arrayValue
                for item in priceItems {
                    let new_estimate = LyberItem(company: item["company"].stringValue, type: item["display_name"].stringValue, description: lyberDescription(type: item["display_name"].stringValue), priceRange: lyftPriceRange(low: item["min_estimate"].int != nil ? item["min_estimate"].int! : 999, high: item["max_estimate"].int != nil ? item["max_estimate"].int! : 999), high: item["max_estimate"].double != nil ? item["max_estimate"].double! : 999, low: item["min_estimate"].double != nil ? item["min_estimate"].double! : 999, distance: item["distance"].doubleValue, duration: item["duration"].intValue, estimatedArrival: item["eta"].intValue / 60, product_id: item["product_id"].stringValue, display_name: item["display_name"].stringValue, id: json["id"].stringValue)
                    lst.append(new_estimate)
                }
                let from_lat = self.fromCoord!.latitude
                let from_lng = self.fromCoord!.longitude
                let to_lat = self.toCoord!.latitude
                let to_lng = self.toCoord!.longitude
                if (String(from_lat) == depar_lat
                    && String(to_lat) == dest_lat
                    && String(from_lng) == depar_lng
                    && String(to_lng) == dest_lng)
                {
                    DispatchQueue.main.async {
                        // Go back to the main queue to update the gui.
                        self.items = lst
                        self.sortByPrice(lst)
                        self.sortedByTime = false
                    }
                }
            } catch {
                
            }
        }
        
    }
    
    // GMSAutocomplet code
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        if (fromPressed == true) {
            DispatchQueue.main.async { [weak self] in
                self?.from.text = place.name
                self?.fromCoord = place.coordinate
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.to.text = place.name
                self?.toCoord = place.coordinate
            }
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
        cell.estimateTime.text = String(items[indexPath.row].estimatedArrival) + " min away"
        
        cell.iconDisplay.image = items[indexPath.row].company == "uber" ? UIImage(named: "uberIcon") : UIImage(named: "lyftIcon")
        
        cell.priceRange.text = items[indexPath.row].priceRange
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // Happens when user clicks on the table cell, call the deep link to direct to your uber/lyft app.
        let target = items[indexPath.row]
        
        if (items[indexPath.row].company == "uber") {
            let builder = RideParametersBuilder()
            let pickupLocation = CLLocation(latitude: fromCoord!.latitude, longitude: fromCoord!.longitude)
            let dropoffLocation = CLLocation(latitude: toCoord!.latitude, longitude: toCoord!.longitude)
            builder.pickupLocation = pickupLocation
            builder.dropoffLocation = dropoffLocation
            builder.dropoffNickname = "Destination"
            builder.dropoffAddress = to.text!
            builder.productID = items[indexPath.row].product_id
            let rideParameters = builder.build()
            
            let deeplink = RequestDeeplink(rideParameters: rideParameters, fallbackType: .mobileWeb)
            deeplink.execute()
        } else {
            let lyftDeepLinkStr = "lyft://ridetype?id=" + items[indexPath.row].product_id + "&pickup[latitude]=" + String(fromCoord!.latitude) + "&pickup[longitude]=" + String(fromCoord!.longitude) + "&destination[latitude]=" + String(toCoord!.latitude) + "&destination[longitude]=" + String(toCoord!.longitude)
            guard let lyftDeepLink = URL(string: lyftDeepLinkStr) else { return }
            UIApplication.shared.open(lyftDeepLink, options: [:], completionHandler: nil)
        }
        
        let recordToSave = Record(context: PersistenceService.context)
        recordToSave.company = target.company
        recordToSave.price_max = target.high
        recordToSave.price_min = target.low
        recordToSave.priority = sortedByTime ? "time" : "price"
        recordToSave.dep_lat = (fromCoord?.latitude)!
        recordToSave.dep_lng = (fromCoord?.longitude)!
        recordToSave.dest_lat = (toCoord?.latitude)!
        recordToSave.dest_lng = (toCoord?.longitude)!
        recordToSave.dep_name = from.text!
        recordToSave.dest_name = to.text!
        recordToSave.uuid = target.id
        recordToSave.user_lat = currentLoc.coordinate.latitude
        recordToSave.user_lng = currentLoc.coordinate.longitude
        recordToSave.eta = Int32(target.estimatedArrival)
        recordToSave.real_price = 0.0
        recordToSave.product = target.display_name
        let now = NSDate()
        recordToSave.time_stamp = now
        PersistenceService.saveContext()
        
        let parameters = ["id": recordToSave.uuid ?? "", "deparLat": recordToSave.dep_lat, "deparLng": recordToSave.dep_lng, "destLat": recordToSave.dest_lat, "destLng": recordToSave.dest_lng, "company": recordToSave.company ?? " ", "productName": recordToSave.product ?? " ", "priceMin": recordToSave.price_min, "priceMax": recordToSave.price_max, "eta": recordToSave.eta * 60, "priority": recordToSave.priority ?? ""] as [String : Any]
        
        postLog(log: parameters)
        
    }
    
    func postLog(log: Any) {
        guard let url = URL(string: "https://lyber-server.herokuapp.com/log/request") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        guard let httpBody = try? JSONSerialization.data(withJSONObject: log, options: []) else { return }
        request.httpBody = httpBody
        
        let session = URLSession.shared
        session.dataTask(with: request) { (data, response, error) in
            if let response = response {
                print("-=-=-=-=")
                print(response)
            }
            
            if let data = data {
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: [])
                    print(json)
                } catch {
                    print(error)
                }
            }
            
        }.resume()
    }
}

// As an extension for CLLocationManagerDelegate
extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if currentLoc.coordinate.latitude == 0 && currentLoc.coordinate.longitude == 0 {
            (self.view.subviews[0] as? GMSMapView)?.animate(toLocation: locations[0].coordinate)
        }
        currentLoc = locations[0]
    }
}

extension ViewController: GMSMapViewDelegate {
    func mapView(_ mapView: GMSMapView, didBeginDragging marker: GMSMarker) {
        print ("beginned dragging")
    }
    
    func mapView(_ mapView: GMSMapView, didDrag marker: GMSMarker) {
        print ("is being dragged")
    }
    
    func mapView(_ mapView: GMSMapView, didEndDragging marker: GMSMarker) {
        print ("is done dragging")
        let jsonUrlStringLoc = "https://maps.googleapis.com/maps/api/geocode/json?latlng=" + String(marker.position.latitude) + "," + String(marker.position.longitude) + "&key=AIzaSyAg-s2u1gxtock_vf16pzHu-eh04je99qQ"
        guard let urlLoc = URL(string: jsonUrlStringLoc) else { return }
        
        URLSession.shared.dataTask(with: urlLoc) { [weak self] (data, response, err) in
            guard let data = data else { return }
            do {
                let locationInfo = try JSONDecoder().decode(LocationInfo.self, from: data)
                print("results:" , locationInfo)
                print(locationInfo.results[0].formatted_address)
                DispatchQueue.main.async {
                    self?.from.text = locationInfo.results[0].formatted_address
                    self?.fromCoord = marker.position
                }
            } catch let jsonErr {
                print("Error serializing json uber:", jsonErr)
            }
            }.resume()
    }
}
