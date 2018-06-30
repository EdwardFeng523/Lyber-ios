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



class ViewController: UIViewController
{
    // Booleans for autocomplete view controller to know which one is currently being edited.
    var fromPressed: Bool = false
    var toPressed: Bool = false
    
    var fromMarker = GMSMarker(position: CLLocationCoordinate2D(latitude: 0, longitude: 0))
    var toMarker = GMSMarker(position: CLLocationCoordinate2D(latitude: 0, longitude: 0))
    
    // Coordinates
    var fromCoord: CLLocationCoordinate2D? = nil
    {
        didSet {
            if (fromCoord != nil) {
                fromMarker.position = fromCoord!
                (view.subviews[0] as? GMSMapView)?.animate(toLocation: fromCoord!)
                print("from Marker:", fromMarker.position)
            }
        }
    }
    
    var toCoord: CLLocationCoordinate2D? = nil
    {
        didSet {
            if (toCoord != nil) {
                toMarker.position = toCoord!
                (view.subviews[0] as? GMSMapView)?.animate(toLocation: toCoord!)
            }
        }
    }
    
    // List of items for display and comparison.
    var items: [LyberItem] = [] { didSet{
        print ("items were set")
        displayTable.reloadData()
        spinner.stopAnimating()
        self.displayTable.alpha = 0.8
    } }
    
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
        let mapView = GMSMapView.map(withFrame: CGRect(origin: CGPoint(x: 0,y: 0), size: CGSize(width: self.view.bounds.width, height: self.view.bounds.height)), camera: camera)
        self.view.insertSubview(mapView, at: 0)
        
        circle.icon = UIImage(named: "currentLoc")
        circle.map = mapView
        
        fromMarker.title = "From"
        fromMarker.tracksViewChanges = true
        fromMarker.map = mapView
        
        toMarker.title = "To"
        toMarker.tracksViewChanges = true
        toMarker.map = mapView
        self.displayTable.alpha = 0
        print ("View Did Load is called-=-=-=-=-=-=-=-=-=-=-=")
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
                    (self?.view.subviews[0] as? GMSMapView)?.animate(toLocation: (self?.currentLoc.coordinate)!)
                }
            } catch let jsonErr {
                print("Error serializing json uber:", jsonErr)
            }
        }.resume()
    }
    
    @IBAction func hideTable(_ sender: UIButton) {
        displayTable.alpha = 0
    }
    
    @IBAction func sortByPrice(_ sender: Any) {
        items.sort { (itemA, itemB) -> Bool in
            return itemA.low < itemB.low
        }
        displayTable.reloadData()
    }
    
    @IBAction func sortByTime(_ sender: Any) {
        items.sort { (itemA, itemB) -> Bool in
            return itemA.estimatedArrival < itemB.estimatedArrival
        }
        displayTable.reloadData()
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
        let jsonUrlStringEstimate = "https://lyber-server.herokuapp.com/api/estimate?depar_lat=" + depar_lat + "&depar_lng=" + depar_lng + "&dest_lat=" + dest_lat + "&dest_lng=" + dest_lng

        guard let urlEstimate = URL(string: jsonUrlStringEstimate) else { return }
        
        var lst: [LyberItem] = []
        
        spinner.startAnimating()
        URLSession.shared.dataTask(with: urlEstimate) { [weak self] (data, response, err) in
            guard let estimateData = data else { return }
            do {
                let estimateInfo = try JSONDecoder().decode(ServerEstimate.self, from: estimateData)
                for elementInfo in estimateInfo.prices {
                    let new_item_estimate = LyberItem(company: elementInfo.company, type: lyberType(type: elementInfo.display_name), description: lyberDescription(type: elementInfo.display_name), priceRange: lyftPriceRange(low: elementInfo.min_estimate, high: elementInfo.max_estimate), high: Double(elementInfo.max_estimate), low: Double(elementInfo.min_estimate), distance: elementInfo.distance, duration: elementInfo.duration, estimatedArrival: elementInfo.eta / 60, product_id: elementInfo.product_id)
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

    }
}

// As an extension for autocomplete view controller.
extension ViewController: GMSAutocompleteViewControllerDelegate {
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        if (fromPressed == true) {
            from.text = place.name
            self.fromCoord = place.coordinate
        } else {
            to.text = place.name
            self.toCoord = place.coordinate
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
        
        if (items[indexPath.row].company == "uber") {
            print ("got it!")
            
        } else {
            lyft://partner=YOUR_CLIENT_ID
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

}

// As an extension for CLLocationManagerDelegate
extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLoc = locations[0]
    }
}

