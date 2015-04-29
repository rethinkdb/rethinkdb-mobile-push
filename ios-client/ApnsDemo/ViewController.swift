//
//  ViewController.swift
//  ApnsDemo
//
//  Created by Ryan Paul on 4/15/15.
//  Copyright (c) 2015 Ryan Paul. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController, UINavigationBarDelegate, CLLocationManagerDelegate {
    
    var locationManager: CLLocationManager!
    var checkedForPoints: Bool!

    @IBOutlet weak var navBar: UINavigationBar!
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navBar.delegate = self
        checkedForPoints = false
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        mapView.showsUserLocation = true;
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
        return UIBarPosition.TopAttached
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        if (checkedForPoints == true) { return }
        checkedForPoints = true
        
        var position = locationManager.location.coordinate
        var url = "http://youraddress.ngrok.com/api/pins?place=\(position.latitude),\(position.longitude)"
        var req = NSURLRequest(URL: NSURL(string: url)!)
        
        NSURLConnection.sendAsynchronousRequest(req, queue: NSOperationQueue.mainQueue()) {(resp, data, err) in
            if let places = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: nil) as? NSArray {
                for place in places as! [NSDictionary] {
                    if let coords = place["coordinates"] as? NSArray, lon = coords[0] as? Double, lat = coords[1] as? Double {
                        self.addMapAnnotation(lon, lat: lat)
                    }
                }
            }
        }
    }
    
    func addMapAnnotation(lon: Double, lat: Double) {
        var newPin = MKPointAnnotation()
        newPin.coordinate = CLLocationCoordinate2DMake(lat, lon)
        mapView.addAnnotation(newPin)
    }
    
    @IBAction func sendMessage(sender: AnyObject) {
        var position = locationManager.location.coordinate
        var appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        var params = Dictionary<String, AnyObject>()
        params["place"] = [position.latitude, position.longitude]
        params["token"] = appDelegate.deviceToken
        
        var req = NSMutableURLRequest(URL: NSURL(string: "http://youraddress.ngrok.com/api/checkin")!)
        req.HTTPBody = NSJSONSerialization.dataWithJSONObject(params, options: nil, error: nil)
        req.HTTPMethod = "POST"
        
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue("application/json", forHTTPHeaderField: "Accept")
        
        NSURLConnection.sendAsynchronousRequest(req, queue: NSOperationQueue.mainQueue()) {(resp, data, err) in
            if let output = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: nil) as? NSDictionary {
                println(output["success"] as? Bool)
            }
        }
    }
}

