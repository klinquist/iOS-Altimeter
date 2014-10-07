//
//  ViewController.swift
//  Altimeter
//
//  Created by Kristopher Linquist on 9/14/14.
//  Copyright (c) 2014 Kristopher Linquist. All rights reserved.
//


var wuapi = "343fae88a6936714"  //weather underground API key
import UIKit
let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate





class ViewController: UIViewController {
    
    func UpdateAltitude() {
       
            var airportBarometricPressurehPa:Float = (airportBarometricPressureTextBox.text as NSString).floatValue * 33.8638866667
            var yourBarometricPressurehPa:Float = (yourBarometricPressureTextBox.text as NSString).floatValue * 33.8638866667
            var yourCalculatedAlt = pow(10, log10(yourBarometricPressurehPa/airportBarometricPressurehPa)/5.2558797)-1
            yourCalculatedAlt = yourCalculatedAlt / (-6.8755856 * pow(10,-6)) + (airportAltitudeTextBox.text as NSString).floatValue
            var yourCalculatedAltString = NSString(format: "%.0f", yourCalculatedAlt)
            yourBarometricPressureTextBox.resignFirstResponder()
            yourAltitudeLabel.text = yourCalculatedAltString + " ft"
            if (yourCalculatedAltString != "-inf") {
                yourAltitudeCaptionLabel.hidden = false
                yourAltitudeLabel.hidden = false
            } else {
                yourAltitudeCaptionLabel.hidden = true
                yourAltitudeLabel.hidden = true
            }

    }

    @IBOutlet weak var airportBarometricPressureTextBox: UITextField!
    
    @IBOutlet weak var airportAltitudeTextBox: UITextField!
    
    @IBOutlet weak var yourBarometricPressureTextBox: UITextField!
    
    @IBOutlet weak var yourAltitudeLabel: UILabel!
    
    @IBOutlet weak var retrieveButton: UIButton!
    
    @IBOutlet weak var airportNameLabel: UILabel!
    
    @IBOutlet weak var yourAltitudeCaptionLabel: UILabel!
    
    @IBOutlet weak var airportNameValue: UITextField!
    
    @IBAction func calculateButton(sender: UIButton) {
        
         if (yourBarometricPressureTextBox.text != "" && airportBarometricPressureTextBox.text != ""){
            UpdateAltitude()
         } else {
            var alert = UIAlertController(title: "Error", message: "Manually enter airport pressure & altitude or enter ICAO airport code and click the 'Retrieve' button.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
        
    }
    
    @IBAction func retrieveButtonPressed(sender: UIButton) {
        airportBarometricPressureTextBox.text = "Waiting..."
        airportAltitudeTextBox.text = "Waiting..."
        airportNameValue.resignFirstResponder()
        yourAltitudeLabel.hidden = false
        var airport = airportNameValue.text.uppercaseString
        if (countElements(airport) == 4) {
                let url = NSURL(string: "http://api.wunderground.com/api/" + wuapi + "/forecast/geolookup/conditions/q/" +  airport + ".json")
                let request = NSURLRequest(URL: url)
                NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) {(response, data, error) in
                    var datastring = NSString(data: data, encoding: NSUTF8StringEncoding)
                    //println("datastring = " + datastring)
                    let value = datastring
                    let pattern = "\\\"pressure_in\\\":\\\"([-+]?[0-9]*\\.?[0-9]+.)\\\""
                    if (value =~ pattern) {
                        var m = value =~ pattern
                        self.airportBarometricPressureTextBox.text = m[0]
                        let elevationpattern = "\\\"elevation\\\":\\\"([-+]?[0-9]*\\.?[0-9]+.)\\\""
                        m = value =~ elevationpattern
                        var AltConversion:Int = 0
                        var AltFloat = (m[0] as NSString).floatValue * 3.28084  //convert meters to feet
                        self.airportAltitudeTextBox.text = NSString(format: "%.0f", AltFloat)
                        let citynamepattern = "\\\"city\\\":\\\"([a-zA-Z ]+.)\\\""
                        m = value =~ citynamepattern
                        self.airportNameLabel.hidden = false
                        self.airportNameLabel.text = m[0]
                    } else {
                        var alert = UIAlertController(title: "Error", message: "Invalid ICAO code.", preferredStyle: UIAlertControllerStyle.Alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
                        self.presentViewController(alert, animated: true, completion: nil)
                    }
                }
            } else {
                self.airportNameLabel.hidden = false
                self.airportNameLabel.text = "Error. Type a valid ICAO code."
                var alert = UIAlertController(title: "Error", message: "Enter a valid ICAO Airport Code", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
                yourAltitudeCaptionLabel.hidden = true
                yourAltitudeLabel.hidden = true
            }


        

    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        var updatePressureTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("updatePressure"), userInfo: nil, repeats: true)

        
   
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func updatePressure()
    {
        let pressure = appDelegate.pressure
        if (pressure > 1) {
            self.yourBarometricPressureTextBox.text = NSString(format: "%.4f", pressure)
            UpdateAltitude()
        }

    }
}

