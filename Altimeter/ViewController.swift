//
//  ViewController.swift
//  Altimeter
//
//  Created by Kristopher Linquist
//  Copyright (c) 2018 Kristopher Linquist. All rights reserved.
//

import UIKit
let appDelegate = UIApplication.shared.delegate as! AppDelegate

import CoreMotion

var altimeter = CMAltimeter() // Lazily load CMAltimeter
var queue = OperationQueue()
import CoreLocation
import AVFoundation


var pressure:Float = 0.00
var pressureInHg:Float = 0.00
var gotPressure:Bool = false;
var gotAirport:Bool = false;
var airportPress:Float = 0.00;
var airportAlt:Float = 0.00;
var prevAlt:String = "";
var prevAltFull:String = "";
var currentAltFull:String = "";
var currentAlt:String = "";
var initialSpeech:Bool = false;

class ViewController: UIViewController, CLLocationManagerDelegate {
    var locationManager:CLLocationManager!
    
    let synthesizer = AVSpeechSynthesizer()
    let audioSession = AVAudioSession.sharedInstance()
    var myUtterance = AVSpeechUtterance(string: "")
    var lastPlayingUtterance: AVSpeechUtterance?
    
    @IBOutlet weak var airportBarometricPressureTextBox: UITextField!
    
    @IBOutlet weak var airportAltitudeTextBox: UITextField!
    
    @IBOutlet weak var yourBarometricPressureTextBox: UITextField!
    
    @IBOutlet weak var yourAltitudeLabel: UILabel!
    
    @IBOutlet weak var retrieveButton: UIButton!
    
    @IBOutlet weak var airportNameLabel: UILabel!
    
    @IBOutlet weak var yourAltitudeCaptionLabel: UILabel!
    
    @IBOutlet weak var airportNameValue: UITextField!
    
//    @IBAction func calculateButton(_ sender: UIButton) {
//
//        if (yourBarometricPressureTextBox.text != "" && airportBarometricPressureTextBox.text != ""){
//            //UpdateAltitude()
//        } else {
//            let alert = UIAlertController(title: "Error", message: "Manually enter airport pressure & altitude or enter ICAO airport code and click the 'Retrieve' button.", preferredStyle: UIAlertControllerStyle.alert)
//            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
//            self.present(alert, animated: true, completion: nil)
//        }
//
//    }
    
    
    @IBAction func retrieveButtonPressed(_ sender: UIButton) {
        determineMyCurrentLocation()
//        airportBarometricPressureTextBox.text = "Waiting..."
//        airportAltitudeTextBox.text = "Waiting..."
//        airportNameValue.resignFirstResponder()
//        yourAltitudeLabel.isHidden = false
//        var airport = airportNameValue.text!.uppercased()
//        if (airport.characters.count == 4) {
//            populateFromAirport(airport: airport);
//        } else {
//            updateLabel(progressText: "Type a valid ICAO code")
//            let alert = UIAlertController(title: "Error", message: "Enter a valid ICAO Airport Code", preferredStyle: UIAlertControllerStyle.alert)
//            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
//            self.present(alert, animated: true, completion: nil)
//            self.yourAltitudeCaptionLabel.isHidden = true
//            self.yourAltitudeLabel.isHidden = true
//        }
    }
    
    
    func populateFromAirport(airport: String) {
        let url = URL(string: "https://api.baroaltimeter.com/getairportdata/" +  airport)
        let request = URLRequest(url: url!)
        let session = URLSession.shared
        session.dataTask(with: request) {data, response, error in
            guard let data = data, error == nil else { return }
            do {
                let json = try JSON(data: data)
                let city = json["data"]["city"].stringValue
                let elevation = json["data"]["alt"].stringValue
                if (elevation == ""){
                    self.errorMsg(error: "Airport not found")
                } else {
                //
                    let AltFloat = Float(elevation)! * 3.28084  //convert meters to feet
                    let baroPressure = json["data"]["pressure"].stringValue
                    DispatchQueue.main.sync() {
                        self.updateLabel(progressText: city)
                        self.airportAltitudeTextBox.text = String(format: "%.0f", AltFloat)
                        self.airportBarometricPressureTextBox.text = baroPressure
                        gotAirport = true;
                        airportPress = (baroPressure as NSString).floatValue
                        airportAlt = AltFloat;
                    }
                }
            } catch let error as NSError {
                print(error)
                self.errorMsg(error: "Could not get nearest barometer reading")
            }
            }.resume()
    }
    
    
    func populateFromLocation(lat: Double,long: Double){
        let url = URL(string: "https://api.baroaltimeter.com/findairport/" +  String(lat) + "/" + String(long))
        let request = URLRequest(url: url!)
        let session = URLSession.shared
        session.dataTask(with: request) {data, response, error in
            guard let data = data, error == nil else { return }
            do {
                let json = try JSON(data: data)
                let icao = json["icao"].stringValue
                DispatchQueue.main.sync() {
                    self.airportNameValue.text = icao
                }
                self.updateLabel(progressText: "Finding nearest airport...")
                self.populateFromAirport(airport: icao)
            } catch let error as NSError {
                print(error)
                self.errorMsg(error: "Could not find nearest airport")
            }
            }.resume()
    }
    
    @objc func textFieldDidChange(textField : UITextField){
        if (airportNameValue.text!.count == 4){
            populateFromAirport(airport: airportNameValue.text!)
            self.view.endEditing(true)
        }
    }
    
    let userDefaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //startAltimeter();
        //
        //NSNotificationCenter.defaultCenter().addObserver(self, selector: "startAltimeter", name: UIApplicationDidBecomeActiveNotification, object: nil)
        if (CMAltimeter.isRelativeAltitudeAvailable()) {
            NotificationCenter.default.addObserver(self, selector: #selector(startAltimeter), name: UIApplication.didBecomeActiveNotification, object: nil)
            airportNameValue.addTarget(self, action: #selector(textFieldDidChange), for: UIControl.Event.editingChanged)
            UserDefaults.standard.register(defaults: [String: Any]())
        } else {
            errorMsg(error: "This device does not have a barometer and is incompatible with BaroAltimeter. Please contact kris@baroaltimeter.com for a refund.")
        }
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
        //print("UpdateAltitude Func")
        if (gotAirport == true && gotPressure == true){
            let airportPresshPa = airportPress * 3.38638866667
            var yourCalculatedAlt = pow(10, log10(pressure/airportPresshPa)/5.2558797)-1
            yourCalculatedAlt = yourCalculatedAlt / (-6.8755856 * pow(10,-6))
            let yourCalculatedAltString = NSString(format: "%.0f", yourCalculatedAlt)
            yourBarometricPressureTextBox.resignFirstResponder()
            yourAltitudeLabel.text = (yourCalculatedAltString as String) + " ft"
            
            if (!initialSpeech){
                if (userDefaults.bool(forKey: "announceonlaunch")){
                    //purposeful misspelling
                    say (text: "Your altatude is " + (yourCalculatedAltString as String) + " feet")
                }
                initialSpeech = true;
            }
            
            //print ((yourCalculatedAltString as String).characters.count)
            currentAlt = firstChar(text:yourCalculatedAltString as String)
            currentAltFull = (yourCalculatedAltString as String)
            
            if (Int(currentAltFull)! > 999){
                if (userDefaults.string(forKey: "voiceannouncements") == "descentonly"){
                    if (prevAlt != "" && Int(prevAlt)! > Int(currentAlt)! && Int(prevAltFull)! > Int(currentAltFull)!){
                        print("Descending, =prevAltFirstChar = " + prevAlt + " and currentAltFirstChar = " + currentAlt + " prevAltFull = " + prevAltFull + " currentAltFull = " + currentAltFull)
                        say(text: "descending through " + currentAlt + " thousand")
                    }
                } else if (userDefaults.string(forKey: "voiceannouncements") == "on") {
                    if (prevAlt != "" && Int(prevAlt)! > Int(currentAlt)! && Int(prevAltFull)! > Int(currentAltFull)!){
                        print("Descending, =prevAltFirstChar = " + prevAlt + " and currentAltFirstChar = " + currentAlt + " prevAltFull = " + prevAltFull + " currentAltFull = " + currentAltFull)
                        say(text: "descending through " + currentAlt + " thousand")
                    }
                    if (prevAlt != "" && (Int(prevAlt)! < Int(currentAlt)! || Int(prevAltFull)! < 1000 && Int(currentAltFull)! > 999)){
                        print("Ascending, prevAltFirstChar = " + prevAlt + " and currentAltFirstChar = " + currentAlt + " prevAltFull = " + prevAltFull + " currentAltFull = " + currentAltFull)
                        say(text: "ascending through " + currentAlt + " thousand")
                    }
                } else {
                    
                }
            } else {
                if (prevAltFull != "" && currentAltFull != "" && (userDefaults.string(forKey: "voiceannouncements") == "descentonly") || userDefaults.string(forKey: "voiceannouncements") == "on") {
                    if (prevAltFull != "" && currentAltFull != "" && Int(prevAltFull)! > 999 && Int(currentAltFull)! <= 999 ){
                        print("Descending through 1000, prevAltFirstChar = " + prevAlt + " and currentAltFirstChar = " + currentAlt + " prevAltFull = " + prevAltFull + " currentAltFull = " + currentAltFull)
                        say(text: "descending through one thousand")
                    }
                }
            }
            
            
            if (Int(currentAltFull)! > 99 && Int(currentAltFull)! < 1000){
                if (userDefaults.string(forKey: "voiceannouncements") == "descentonly"){
                    if (prevAlt != "" && Int(prevAltFull)! >= 500 && Int(currentAltFull)! < 500){
                        say(text: "five hundred")
                    }
                }
            }
            
            prevAlt = firstChar(text: yourCalculatedAltString as String)
            prevAltFull = (yourCalculatedAltString as String)
            
//            if (prevAltFull.count == 3) {
//                prevAlt = "0"
//            }
            
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
        //print("UpdatePressure Func")
        if (pressure > 1) {
            //print("Pressure is " + String(format: "%.4f", pressureInHg))
            yourBarometricPressureTextBox!.text = String(format: "%.4f", pressureInHg)
            gotPressure = true;
        } else {
            print("yourBarometricPressureTextBox is nil")
        }
    }
    
    func firstChar(text: String) -> String{
        return String(text[text.startIndex])
//        let firstChar = String(Array((text as String))[0])
//        print ("Firstchar is " + firstChar)
//        return firstChar
    }
    
    
    @objc func startAltimeter() {

        print("startAltimeter Func")
        // Check if altimeter feature is available
        if (CMAltimeter.isRelativeAltitudeAvailable()) {
            
            determineMyCurrentLocation()
            //self.activityIndicator.startAnimating()
            // Start altimeter updates, add it to the main queue
            altimeter.startRelativeAltitudeUpdates(to: OperationQueue.main, withHandler: { (altitudeData:CMAltitudeData?, error:Error?) in
                if (error != nil) {
                    // If there's an error, stop updating and alert the user
                    self.stopAltimeter()
                    self.errorMsg(error: "Error getting current barometer reading from phone")
                    
                } else {
                    pressure = altitudeData!.pressure.floatValue
                    pressureInHg = pressure * 0.2953;
                    self.updatePressure();
                    self.UpdateAltitude()
                    // delayed code, by default run in main thread
                }
            })
        } else {
            print("No altimeter on this device")
            errorMsg(error: "This device does not have a barometer and is incompatible with BaroAltimeter. Please contact kris@baroaltimeter.com for a refund.")
        }
    
    }
    
    
    
    func stopAltimeter() {
        print("stopAltimeter Func")
        if (CMAltimeter.isRelativeAltitudeAvailable()) {
            initialSpeech = false;
            altimeter.stopRelativeAltitudeUpdates() // Stop updates
            print("Stopped relative altitude updates.")
        }
    }
    
    
    
    func errorMsg(error: String){
        print ("Showing error " + error)
        let alertWindow = UIWindow(frame: UIScreen.main.bounds)
        alertWindow.rootViewController = UIViewController()
        alertWindow.windowLevel = UIWindow.Level.alert + 1;
        alertWindow.makeKeyAndVisible()
        let showErrorAlert = UIAlertController(title: "Error", message: error, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        showErrorAlert.addAction(cancelAction)
        present(showErrorAlert, animated: true, completion: nil)
        alertWindow.rootViewController?.present(showErrorAlert, animated: true, completion: nil)
    }
    
    
    
    func say(text: String) {
        print("Say Func")
        if (text.isEmpty) { return }
        let audioSession = AVAudioSession.sharedInstance()
        do {
            //try audioSession.setCategory(convertFromAVAudioSessionCategory(AVAudioSession.Category.playback), with: [.duckOthers])
            //audioSession.setCategory(category: "playback", mode: "default", options: ["duckOthers"])
            try audioSession.setCategory(AVAudioSession.Category.playback, mode: AVAudioSession.Mode.default, options: [AVAudioSession.CategoryOptions.duckOthers])
            try audioSession.setActive(true)
        } catch {
            return
        }
        
        let utterance = AVSpeechUtterance(string:text)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.volume = 1.0
        self.synthesizer.speak(utterance)
        self.perform(#selector(resumeAudio), with: nil, afterDelay: 3.0)
    }
    
    @objc func resumeAudio() {
        do {
            try self.audioSession.setActive(false);
        } catch {
            
        }
    }
    
}


// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromAVAudioSessionCategory(_ input: AVAudioSession.Category) -> String {
	return input.rawValue
}
