//
//  AppDelegate.swift
//  LocationsAppTwo
//
//  Created by Akshay Kumar Both on 12/1/17.
//  Copyright © 2017 dummy. All rights reserved.
//

import UIKit
import CoreLocation
import Alamofire

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {

    var window: UIWindow?
    var backgroundTimer = Timer()
    var backgroundTaskIdentifier: UIBackgroundTaskIdentifier!
    var backgroundTaskIdentifier2: UIBackgroundTaskIdentifier!
    var locationManager = CLLocationManager()
    
    var startLocation: CLLocation!
    var lastLocation: CLLocation!
    var startDate: Date!
    //var traveledDistance: Double = 0
    var latitude: Double = 0.0
    var longitude: Double = 0.0
    

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        print("Entering background")
        if isAllowedTracking {
            if CLLocationManager.locationServicesEnabled() {
                locationManager.delegate = self
                //locationManager.allowsBackgroundLocationUpdates = true
                locationManager.desiredAccuracy = kCLLocationAccuracyBest //kCLLocationAccuracyNearestTenMeters
                //locationManager.startUpdatingLocation()
                /*
                if #available(iOS 9.0, *) {
                    locationManager.allowsBackgroundLocationUpdates = true
                } else {
                    // Fallback on earlier versions
                }*/
                locationManager.startMonitoringSignificantLocationChanges()
                locationManager.distanceFilter = 10
            }
            
            backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(expirationHandler: { () -> Void in
                if  ("\(Reach().connectionStatus())" == "Online (WiFi)" || "\(Reach().connectionStatus())" == "Online (WWAN)"){
                    
                    self.backgroundTimer.invalidate()
                    self.backgroundTimer = Timer.scheduledTimer( timeInterval: 1.0, target: self, selector: #selector(self.updateLocation), userInfo: nil, repeats: true)
                }
                
            })
        }
        
    }
    
    @objc func updateLocation() {
        //txtlocationLabel.text = String(n)
        //self.n = self.n+1
        
        
        let locValue:CLLocationCoordinate2D = locationManager.location!.coordinate
        
        self.latitude = locValue.latitude
        self.longitude = locValue.longitude
        print("\(latitude) \(longitude)")
        
        sendDataToServer()
        var timeRemaining = UIApplication.shared.backgroundTimeRemaining
        print(timeRemaining)
        
        if timeRemaining > 60.0 {
            
        } else {
            if timeRemaining == 0 {
                UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
            }
            
            backgroundTaskIdentifier2 = UIApplication.shared.beginBackgroundTask(expirationHandler: { () -> Void in
                if  ("\(Reach().connectionStatus())" == "Online (WiFi)" || "\(Reach().connectionStatus())" == "Online (WWAN)"){
                    
                    self.backgroundTimer.invalidate()
                    self.backgroundTimer = Timer.scheduledTimer( timeInterval: 1.0, target: self, selector: #selector(self.updateLocation), userInfo: nil, repeats: true)
                }
                
            })
        }
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
            //traveledDistance += lastLocation.distance(from: location)
            //print("Traveled Distance:",  traveledDistance)
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
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if (error as? CLError)?.code == .denied {
            manager.stopUpdatingLocation()
            manager.stopMonitoringSignificantLocationChanges()
            backgroundTimer.invalidate()
        }
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

