//
//  ViewController.swift
//  LocationsAppTwo
//
//  Created by Akshay Kumar Both on 12/1/17.
//  Copyright © 2017 dummy. All rights reserved.
//

import UIKit
import CoreLocation
import Alamofire

var isAllowedTracking: Bool = false

class ViewController: UIViewController , CLLocationManagerDelegate{
    
    var locationManager = CLLocationManager()
    var latitude: Double = 0.0
    var longitude: Double = 0.0
    var timeInMinutes: Int = 0
    var backgroundTimer = Timer()
    
    var startLocation: CLLocation!
    var lastLocation: CLLocation!
    var startDate: Date!
    var traveledDistance: Double = 0
    
    @IBAction func startTrackingPressed(_ sender: Any) {
        isAllowedTracking = true
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest //kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
            /*
            if #available(iOS 9.0, *) {
                locationManager.allowsBackgroundLocationUpdates = true
            } else {
                // Fallback on earlier versions
            }*/
            locationManager.startMonitoringSignificantLocationChanges()
            locationManager.distanceFilter = 10
        }
        
        if  ("\(Reach().connectionStatus())" == "Online (WiFi)" || "\(Reach().connectionStatus())" == "Online (WWAN)"){
            backgroundTimer = Timer.scheduledTimer( timeInterval: TimeInterval(timeInMinutes), target: self, selector: #selector(updateLocation), userInfo: nil, repeats: true)
        } else {
            let alert = UIAlertController(title: "Alert", message: "No internet connection", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "ok", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        
    }
    
    @IBAction func stopTrackingPressed(_ sender: Any) {
        isAllowedTracking = false
        
        locationManager.stopUpdatingLocation()
        locationManager.stopMonitoringSignificantLocationChanges()
        backgroundTimer.invalidate()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    
        timeInMinutes = 1
        
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.requestWhenInUseAuthorization()
    }

    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]){
        let locValue:CLLocationCoordinate2D = manager.location!.coordinate
        
        self.latitude = locValue.latitude
        self.longitude = locValue.longitude
        
        if startDate == nil {
            startDate = Date()
        } else {
            print("elapsedTime:", String(format: "%.0fs", Date().timeIntervalSince(startDate)))
        }
        if startLocation == nil {
            startLocation = locations.first
        } else if let location = locations.last {
            traveledDistance += lastLocation.distance(from: location)
            print("Traveled Distance:",  traveledDistance)
            print("Straight Distance:", startLocation.distance(from: locations.last!))
        }
        lastLocation = locations.last
        
        if startLocation.distance(from: lastLocation) > 100.0 {
            print("distance is more than 100 metre do api call")
            sendDataToServer() //do api call
        }
        
    }
    

    func sendDataToServer() {
        
        print(Reach().connectionStatus())
        
        let username = ""
        let password = ""
        let loginString = String(format: "%@:%@", username, password)
        let loginData = loginString.data(using: String.Encoding.utf8)!
        let base64LoginString = loginData.base64EncodedString()
        let headers = ["Authorization": "Basic \(base64LoginString)",
                        "Content-Type": "application/json"
                        ]
        let customerURL = URL(string: "https://api.locus.sh/v1//client/test/user/candidate/location")!
        
        let someDate = Date()
        let timeInterval = someDate.timeIntervalSince1970  // convert Date to TimeInterval (typealias for Double)
        let time = Int(timeInterval)  // convert to Integer

        let location1: [String: Any]  = [
            "lat": latitude,
            "lng": longitude,
            "timestamp": time
            ]
        
        let parameters: [String: Any]  = [
            "location": location1,
        ]
        
        Alamofire.request("https://api.locus.sh/v1//client/test/user/candidate/location", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .responseJSON { response in
                //print(response)
                var statusCode = response.response?.statusCode
                print(statusCode)
        }
 }
    
    @objc func updateLocation() {
        let locValue:CLLocationCoordinate2D = locationManager.location!.coordinate
        
        self.latitude = locValue.latitude
        self.longitude = locValue.longitude
        print("\(latitude) \(longitude)")
        
        //do apis callls after every 2 minute
        sendDataToServer()
        
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if (error as? CLError)?.code == .denied {
            manager.stopUpdatingLocation()
            manager.stopMonitoringSignificantLocationChanges()
        }
    }
    


}

