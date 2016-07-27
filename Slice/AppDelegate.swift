//
//  AppDelegate.swift
//  Slice
//
//  Created by Oliver Hill on 6/9/16.
//  Copyright © 2016 Oliver Hill. All rights reserved.
//
import UIKit
import Stripe

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        Stripe.setDefaultPublishableKey("pk_test_Lp3E4ypwmrizs2jfEenXdwpr")
        noUserFound()
        guard let user = NSKeyedUnarchiver.unarchiveObjectWithFile(Constants.userFilePath()) as? User else{
            noUserFound()
            return true
        }
        
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        if user.isLoggedIn{
            let cc = ContainerController()
            cc.loggedInUser = user
            window?.rootViewController = cc
            
        }
        else{
            let lc = LoginController()
            lc.shouldShowBackButton = false
            window?.rootViewController = WelcomeController()
        }
        window!.makeKeyAndVisible()
        return true
    }
    
    
    func noUserFound(){
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        window?.rootViewController = WelcomeController()
        window!.makeKeyAndVisible()
    }
    
    
    func application(application: UIApplication, willChangeStatusBarFrame newStatusBarFrame: CGRect) {
        let windows = UIApplication.sharedApplication().windows
        for window in windows {
            window.removeConstraints(window.constraints)
        }
    }
    
  
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    
}



