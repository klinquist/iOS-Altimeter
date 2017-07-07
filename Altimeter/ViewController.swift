//
//  ViewController.swift
//  Altimeter
//
//  Created by Kristopher Linquist
//  Copyright (c) 2014 Kristopher Linquist. All rights reserved.
//


var wuapi = "343fae88a6936714"  //weather underground API key
import UIKit
let appDelegate = UIApplication.shared.delegate as! AppDelegate

import CoreMotion

var altimeter = CMAltimeter() // Lazily load CMAltimeter
var queue = OperationQueue()
import CoreLocation



var pressure:Float = 0.00
var pressureInHg:Float = 0.00
var gotPressure:Bool = false;
var gotAirport:Bool = false;
var airportPress:Float = 0.00;
var airportAlt:Float = 0.00;

class ViewController: UIViewController, CLLocationManagerDelegate {
    var locationManager:CLLocationManager!
    
    
    @IBOutlet weak var airportBarometricPressureTextBox: UITextField!
    
    @IBOutlet weak var airportAltitudeTextBox: UITextField!
    
    @IBOutlet weak var yourBarometricPressureTextBox: UITextField!
    
    @IBOutlet weak var yourAltitudeLabel: UILabel!
    
    @IBOutlet weak var retrieveButton: UIButton!
    
    @IBOutlet weak var airportNameLabel: UILabel!
    
    @IBOutlet weak var yourAltitudeCaptionLabel: UILabel!
    
    @IBOutlet weak var airportNameValue: UITextField!
    
    @IBAction func calculateButton(_ sender: UIButton) {
        
        if (yourBarometricPressureTextBox.text != "" && airportBarometricPressureTextBox.text != ""){
            //UpdateAltitude()
        } else {
            let alert = UIAlertController(title: "Error", message: "Manually enter airport pressure & altitude or enter ICAO airport code and click the 'Retrieve' button.", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        
    }
    
    @IBAction func retrieveButtonPressed(_ sender: UIButton) {
        airportBarometricPressureTextBox.text = "Waiting..."
        airportAltitudeTextBox.text = "Waiting..."
        airportNameValue.resignFirstResponder()
        yourAltitudeLabel.isHidden = false
        var airport = airportNameValue.text!.uppercased()
        if (airport.characters.count == 4) {
            populateFromAirport(airport: airport);
        } else {
            updateLabel(progressText: "Type a valid ICAO code")
            let alert = UIAlertController(title: "Error", message: "Enter a valid ICAO Airport Code", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            self.yourAltitudeCaptionLabel.isHidden = true
            self.yourAltitudeLabel.isHidden = true
        }
    }
    
    
    func populateFromAirport(airport: String) {
        self.updateLabel(progressText: "Finding nearest airport...")
        let url = URL(string: "https://api.wunderground.com/api/" + wuapi + "/forecast/geolookup/conditions/q/" +  airport + ".json")
        let request = URLRequest(url: url!)
        let session = URLSession.shared
        session.dataTask(with: request) {data, response, error in
            guard let data = data, error == nil else { return }
            do {
                let json = try JSON(data: data)
                let city = json["location"]["city"].stringValue
                let elevation = json["current_observation"]["display_location"]["elevation"].stringValue
                let AltFloat = Float(elevation)! * 3.28084  //convert meters to feet
                let baroPressure = json["current_observation"]["pressure_in"].stringValue
                DispatchQueue.main.sync() {
                    self.updateLabel(progressText: city)
                    self.airportAltitudeTextBox.text = String(format: "%.0f", AltFloat)
                    self.airportBarometricPressureTextBox.text = baroPressure
                    gotAirport = true;
                    airportPress = (baroPressure as NSString).floatValue
                    airportAlt = AltFloat;
                    
                }
            } catch let error as NSError {
                print(error)
            }
            }.resume()
    }
    
    
    func populateFromLocation(lat: Double,long: Double){
        let url = URL(string: "https://api.wunderground.com/api/" + wuapi + "/forecast/geolookup/conditions/q/" +  String(lat) + "," + String(long) + ".json")
        let request = URLRequest(url: url!)
        let session = URLSession.shared
        session.dataTask(with: request) {data, response, error in
            guard let data = data, error == nil else { return }
            do {
                let json = try JSON(data: data)
                let icao = json["location"]["nearby_weather_stations"]["airport"]["station"][0]["icao"].stringValue
                DispatchQueue.main.sync() {
                    self.airportNameValue.text = icao
                }
                self.populateFromAirport(airport: icao)
            } catch let error as NSError {
                print(error)
            }
            }.resume()
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startAltimeter();
        determineMyCurrentLocation()
    }
    
    
    func updateLabel(progressText: String) {
        if (Thread.isMainThread == true){
            airportNameLabel.isHidden = false
            airportNameLabel.text = progressText
            print("Setting label to " + progressText)
        } else {
            DispatchQueue.main.sync() {
                self.airportNameLabel.isHidden = false
                self.airportNameLabel.text = progressText
                print("Setting label to " + progressText)
            }
        }
    }
    
    
    func determineMyCurrentLocation() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
            //locationManager.startUpdatingHeading()
        } else {
            self.updateLabel(progressText: "Location services disabled, type in airport ICAO")
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation:CLLocation = locations[0] as CLLocation
        
        // Call stopUpdatingLocation() to stop listening for location updates,
        // other wise this function will be called every time when user location changes.
        
        manager.stopUpdatingLocation()
        populateFromLocation(lat: userLocation.coordinate.latitude, long: userLocation.coordinate.longitude)
        
        print("user latitude = \(userLocation.coordinate.latitude)")
        print("user longitude = \(userLocation.coordinate.longitude)")
    }
    
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
        print("Error \(error)")
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func UpdateAltitude() {
        if (gotAirport == true && gotPressure == true){
            let airportPresshPa = airportPress * 3.38638866667
            var yourCalculatedAlt = pow(10, log10(pressure/airportPresshPa)/5.2558797)-1
            yourCalculatedAlt = yourCalculatedAlt / (-6.8755856 * pow(10,-6))
            let yourCalculatedAltString = NSString(format: "%.0f", yourCalculatedAlt)
            yourBarometricPressureTextBox.resignFirstResponder()
            yourAltitudeLabel.text = (yourCalculatedAltString as String) + " ft"
            if (yourCalculatedAltString != "-inf") {
                yourAltitudeCaptionLabel.isHidden = false
                yourAltitudeLabel.isHidden = false
            } else {
                yourAltitudeCaptionLabel.isHidden = true
                yourAltitudeLabel.isHidden = true
            }
            
            
        } else{
            print("BaroAltimeter: not ready")
        }
    }
    
    
    
    @objc func updatePressure()
    {
        if (pressure > 1) {
            yourBarometricPressureTextBox!.text = String(format: "%.4f", pressureInHg)
            gotPressure = true;
        }
    }
    
    
    
    func startAltimeter() {

        
        // Check if altimeter feature is available
        if (CMAltimeter.isRelativeAltitudeAvailable()) {
            
            //self.activityIndicator.startAnimating()
            
            // Start altimeter updates, add it to the main queue
            altimeter.startRelativeAltitudeUpdates(to: OperationQueue.main, withHandler: { (altitudeData:CMAltitudeData?, error:Error?) in
                
                if (error != nil) {
                    
                    // If there's an error, stop updating and alert the user
                    
                    self.stopAltimeter()
                    print ("error")
                    //let alertView = UIAlertView(title: "Error", message: error!.localizedDescription, delegate: nil, cancelButtonTitle: "OK")
                    //alertView.show()
                } else {
                    pressure = altitudeData!.pressure.floatValue
                    pressureInHg = pressure * 0.2953;
                    self.updatePressure();
                    self.UpdateAltitude()
                }
            })
        } else {
            print("No altimeter on this device")
            //let alertView = UIAlertView(title: "Error", message: "Barometer not available on this device.", delegate: nil, cancelButtonTitle: "OK")
            //alertView.show()
            
        }
        
    }
    func stopAltimeter() {
        altimeter.stopRelativeAltitudeUpdates() // Stop updates
        print("Stopped relative altitude updates.")
    }
}

