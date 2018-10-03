//
//  AppDelegate.swift
//  Altimeter
//
//  Created by Kristopher Linquist on 9/14/14.
//  Copyright (c) 2014 Kristopher Linquist. All rights reserved.
//



import UIKit
var vc = ViewController()

func delayWithSeconds(_ seconds: Double, completion: @escaping () -> ()) {
    DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
        completion()
    }
}

var started:Bool = false;

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func applicationDidFinishLaunching(_ application: UIApplication) {
         print("starting altimeter didfinishlaunching")
         //vc.startAltimeter()
         //started = true;
    }
    
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        //altimeter.stopRelativeAltitudeUpdates()
        print("app going inactive")
        started = false;
        //vc.stopAltimeter()
        UIApplication.shared.isIdleTimerDisabled = false
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        print("app entered background")
        //started = false;
        //vc.stopAltimeter()
        UIApplication.shared.isIdleTimerDisabled = false
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        print("app entered foreground")
        //vc.startAltimeter()
//        NotificationCenter.defaultCenter().postNotificationName(UIApplicationWillEnterForegroundNotification, object:nil)
//        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
//        UIApplication.shared.isIdleTimerDisabled = true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        print("app became active")
//        UIApplication.shared.isIdleTimerDisabled = true
//        NotificationCenter.defaultCenter().postNotificationName(UIApplicationDidBecomeActiveNotification, object:nil)
//        if (!started){
//            vc = ViewController()
//            print("starting altimeter in 2sec")
//            delayWithSeconds(2) {
//                print("starting altimeter now")
//                vc.startAltimeter()
//            }
//        } else {
//            print("no need to start altimeter")
//        }
    }
    
    
//    @objc private func applicationDidBecomeActive(_ notification: NSNotification) {
//        print("app became active")
//        UIApplication.shared.isIdleTimerDisabled = true
//        if (!started){
//            vc = ViewController()
//            print("starting altimeter in 2sec")
//            delayWithSeconds(2) {
//                print("starting altimeter now")
//                vc.startAltimeter()
//            }
//        } else {
//            print("no need to start altimeter")
//        }
//    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        print("app will terminate")
        vc.stopAltimeter()
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
}

