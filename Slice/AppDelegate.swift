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
    var containerController: ContainerController?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        //Initialize Singleton Classes
        Stripe.setDefaultPublishableKey(Constants.stripePublishableKey)
        _ = CurrentPrices()
        
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
       
        if checkFirstLaunch(){ return true }
        
        guard let user = NSKeyedUnarchiver.unarchiveObjectWithFile(Constants.userFilePath()) as? User else{
            window?.rootViewController = LoginController()
            window!.makeKeyAndVisible()
            checkiPhone4()
            return true
        }
        
        if user.isLoggedIn{
            setupWithUser(user)
        }
        
        else{
            window?.rootViewController = LoginController()
        }
        
        window!.makeKeyAndVisible()
        checkiPhone4()
        return true
    }
    
    
    func checkFirstLaunch()->Bool{
        let isNotFirstLaunch = NSUserDefaults.standardUserDefaults().boolForKey("isNotFirstLaunch")
        if !isNotFirstLaunch{
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "isNotFirstLaunch")
            window?.rootViewController = WelcomeController()
            window!.makeKeyAndVisible()
            checkiPhone4()
        }
        return !isNotFirstLaunch
    }
    
    func setupWithUser(user: User){
        if user.hasSeenTutorial{
            containerController = ContainerController()
            containerController!.loggedInUser = user
            window?.rootViewController = containerController!
        }
        else{
            let tc = TutorialController()
            tc.user = user
            window?.rootViewController = tc
        }
    }
    
    func checkiPhone4(){ if UIScreen.mainScreen().bounds.height <= 480.0{ Alerts.iPhone4() } }
    
    func application(application: UIApplication, willChangeStatusBarFrame newStatusBarFrame: CGRect) {
        let windows = UIApplication.sharedApplication().windows
        for window in windows {
            window.removeConstraints(window.constraints)
        }
    }
    

    func applicationDidBecomeActive(application: UIApplication) {
        if containerController != nil{
            containerController!.promptUserFeedBack()
        }
    }
}



