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
        
        Stripe.setDefaultPublishableKey(Constants.stripePublishableKey)
        _ = CurrentPrices()
        
        guard let user = NSKeyedUnarchiver.unarchiveObjectWithFile(Constants.userFilePath()) as? User else{
            noUserFound()
            return true
        }
        
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        if user.isLoggedIn{
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
        else{
            let lc = LoginController()
            lc.shouldShowBackButton = false
            window?.rootViewController = WelcomeController()
        }
        window!.makeKeyAndVisible()
        if UIScreen.mainScreen().bounds.height <= 480.0{
            Alerts.iPhone4()
        }
        
        return true
    }
    
    
    func noUserFound(){
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        window?.rootViewController = LoginController()
        window!.makeKeyAndVisible()
    }
    
    
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



