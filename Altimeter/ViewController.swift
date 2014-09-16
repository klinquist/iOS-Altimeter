//
//  ViewController.swift
//  Altimeter
//
//  Created by Kristopher Linquist on 9/14/14.
//  Copyright (c) 2014 Kristopher Linquist. All rights reserved.
//


var wuapi = "YOUR_API_KEY"  //weather underground API key

import UIKit
import CoreMotion

class ViewController: UIViewController {
    
    func UpdateAltitude() {
        yourAltitudeCaptionLabel.hidden = false
        yourAltitudeLabel.hidden = false
        var airportBarometricPressurehPa:Float = (airportBarometricPressureTextBox.text as NSString).floatValue * 33.8638866667
        var yourBarometricPressurehPa:Float = (yourBarometricPressureTextBox.text as NSString).floatValue * 33.8638866667
        var yourCalculatedAlt = pow(10, log10(yourBarometricPressurehPa/airportBarometricPressurehPa)/5.2558797)-1
        yourCalculatedAlt = yourCalculatedAlt / (-6.8755856 * pow(10,-6))
        var yourCalculatedAltString = NSString(format: "%.0f", yourCalculatedAlt)
        yourBarometricPressureTextBox.resignFirstResponder()
        yourAltitudeLabel.text = yourCalculatedAltString + " ft"
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
        UpdateAltitude()
    }
    
    @IBAction func retrieveButtonPressed(sender: UIButton) {
        airportBarometricPressureTextBox.text = "Waiting..."
        airportAltitudeTextBox.text = "Waiting..."
        airportNameValue.resignFirstResponder()
        yourAltitudeLabel.hidden = false
        let url = NSURL(string: "http://api.wunderground.com/api/" + wuapi + "/forecast/geolookup/conditions/q/" +  airportNameValue.text + ".json")
        let request = NSURLRequest(URL: url)
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) {(response, data, error) in

            var datastring = NSString(data: data, encoding: NSUTF8StringEncoding)
            //println(datastring)
            let value = datastring
            let pattern = "\\\"pressure_in\\\":\\\"([-+]?[0-9]*\\.?[0-9]+.)\\\""
            var m = value =~ pattern
            self.airportBarometricPressureTextBox.text = m[0]
            let elevationpattern = "\\\"elevation\\\":\\\"([-+]?[0-9]*\\.?[0-9]+.)\\\""
            m = value =~ elevationpattern
            var AltConversion:Int = 0
            var AltFloat = (m[0] as NSString).floatValue * 3.28084
            self.airportAltitudeTextBox.text = NSString(format: "%.0f", AltFloat)
            let citynamepattern = "\\\"city\\\":\\\"([a-zA-Z ]+.)\\\""
            m = value =~ citynamepattern
            self.airportNameLabel.hidden = false
            self.airportNameLabel.text = m[0]
            
        }

    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
       var altimeter = CMAltimeter()
       var pressure:Float = 0
       if CMAltimeter.isRelativeAltitudeAvailable() {
            altimeter.startRelativeAltitudeUpdatesToQueue(NSOperationQueue.mainQueue(), withHandler: { data, error in
                if !(error != nil) {
                    pressure = data.pressure * 0.2953
                    self.yourBarometricPressureTextBox.text = NSString(format:"%.2f", pressure)
                    if (self.airportNameValue != ""){
                        self.UpdateAltitude()
                    }
                 
                }
            })
       } else {
          self.yourBarometricPressureTextBox.placeholder = "unsupported"
       }
        

   
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

