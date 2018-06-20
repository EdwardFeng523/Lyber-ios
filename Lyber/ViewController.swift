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



class ViewController: UIViewController
{
    var fromPressed: Bool = false
    var toPressed: Bool = false
    
    var fromCoord: CLLocationCoordinate2D? = nil
    
    var toCoord: CLLocationCoordinate2D? = nil
    
    var items: [LyberItem] = [] { didSet{
        print ("items were set")
        displayTable.reloadData()
        spinner.stopAnimating()
    } }
    
    @IBOutlet weak var displayTable: UITableView!
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        displayTable.delegate = self
        displayTable.dataSource = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        print ("This would rather never happen but you did receive a memory warning!")
    }
    
    
    @IBOutlet weak var from: UITextField!
    @IBAction func fromButton(_ sender: Any) {
        let autocompleteControllerFrom = GMSAutocompleteViewController()
        autocompleteControllerFrom.delegate = self
        
        fromPressed = true
        present(autocompleteControllerFrom, animated: true, completion: nil)
    }
    
    @IBOutlet weak var to: UITextField!
    @IBAction func toButton(_ sender: Any) {
        let autocompleteControllerTo = GMSAutocompleteViewController()
        autocompleteControllerTo.delegate = self
        
        // Set a filter to return only addresses.
        let addressFilter = GMSAutocompleteFilter()
        addressFilter.type = .address
        autocompleteControllerTo.autocompleteFilter = addressFilter
        
        toPressed = true
        present(autocompleteControllerTo, animated: true, completion: nil)
    }
    
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
    
    @IBAction func uberLogin(_ sender: Any) {
        let loginManager = LoginManager()
        loginManager.login(requestedScopes:[.request], presentingViewController: self, completion: { accessToken, error in
            // Completion block. If accessToken is non-nil, you’re good to go
            // Otherwise, error.code corresponds to the RidesAuthenticationErrorType that occured
            if (accessToken != nil) {
                print ("good")
            } 
        })
    }
    
    func sendRequest(depar_lat: String, depar_lng: String, dest_lat: String, dest_lng: String) {
        let jsonUrlStringUber = "https://lyber-server.herokuapp.com/api/uber?depar_lat=" + depar_lat + "&depar_lng=" + depar_lng + "&dest_lat=" + dest_lat + "&dest_lng=" + dest_lng
        let jsonUrlStringLyft = "https://lyber-server.herokuapp.com/api/lyft?depar_lat=" + depar_lat + "&depar_lng=" + depar_lng + "&dest_lat=" + dest_lat + "&dest_lng=" + dest_lng
        
        var uberFinished: Bool = false
        var lyftFinished: Bool = false
        
        guard let urlUber = URL(string: jsonUrlStringUber) else { return }
        guard let urlLyft = URL(string: jsonUrlStringLyft) else { return }
        var lst: [LyberItem] = []
        URLSession.shared.dataTask(with: urlUber) { (data, response, err) in
            guard let data = data else { return }
            do {
                let uberInfo = try JSONDecoder().decode(UberInfo.self, from: data)
                for elementUber in uberInfo.prices {
                    let new_item = LyberItem(type: lyberType(type: elementUber.display_name) , description: lyberDescription(type: elementUber.display_name), priceRange: elementUber.estimate, high: Double(elementUber.high_estimate), low: Double(elementUber.low_estimate), distance: elementUber.distance, duration: elementUber.duration, estimatedArrival: "unavailable")
                    lst.append(new_item)
                }
                print ("lst appended")
                print (uberInfo)
                uberFinished = true
            } catch let jsonErr {
                print("Error serializing json uber:", jsonErr)
            }
            }.resume()
        
        URLSession.shared.dataTask(with: urlLyft) { (data, response, err) in
            guard let lyftData = data else { return }
            do {
                let lyftInfo = try JSONDecoder().decode(LyftInfo.self, from: lyftData)
                for elementLyft in lyftInfo.cost_estimates {
                    let new_item1 = LyberItem(type: lyberType(type: elementLyft.ride_type), description: lyberDescription(type: elementLyft.ride_type), priceRange: lyftPriceRange(low: elementLyft.estimated_cost_cents_min, high: elementLyft.estimated_cost_cents_max), high: Double(elementLyft.estimated_cost_cents_max), low: Double(elementLyft.estimated_cost_cents_min), distance: elementLyft.estimated_distance_miles, duration: elementLyft.estimated_duration_seconds, estimatedArrival: "unavailable")
                    lst.append(new_item1)
                }
                print ("lst appended")
                print (lyftInfo)
                lyftFinished = true
            } catch let jsonErr {
                print("Error serializing json lyft:", jsonErr)
            }
            }.resume()
        
        spinner.startAnimating()
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            while (!uberFinished || !lyftFinished) {
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
                    self?.items = lst
                    self?.displayTable.separatorStyle = UITableViewCellSeparatorStyle.singleLine
                }
            }
            
        }
    }

    
}


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

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
//        cell.textLabel?.text = items[indexPath.row].type
//        cell.detailTextLabel?.text = items[indexPath.row].priceRange
        let cell = tableView.dequeueReusableCell(withIdentifier: "customCell") as! CustomTableViewCell
        cell.type.text = items[indexPath.row].type
        cell.arrivalTime.text = items[indexPath.row].description
        cell.distance.text = String(items[indexPath.row].distance) + "mi"
        cell.priceRange.text = items[indexPath.row].priceRange
        return cell
    }
    
    
}
