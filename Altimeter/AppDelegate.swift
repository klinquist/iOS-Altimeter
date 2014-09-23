//
//  AppDelegate.swift
//  Altimeter
//
//  Created by Kristopher Linquist on 9/14/14.
//  Copyright (c) 2014 Kristopher Linquist. All rights reserved.
//

import UIKit
import CoreMotion

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    /* The altimeter instance that will deliver our altitude updates if they
    are available on the host device */
    lazy var altimeter = CMAltimeter()
    /* A private queue on which altitude updates will be delivered to us */
    lazy var queue = NSOperationQueue()
    
    var pressure:Float = 0.00

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        altimeter.stopRelativeAltitudeUpdates()
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        if CMAltimeter.isRelativeAltitudeAvailable(){
            altimeter.startRelativeAltitudeUpdatesToQueue(queue,
                withHandler: {(data: CMAltitudeData!, error: NSError!) in
                    self.pressure = data.pressure * 0.295299802
                    //println("Relative pressure is \(data.pressure) kpa")

                    
            })
        }
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

