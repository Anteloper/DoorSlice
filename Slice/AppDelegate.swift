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
        
        if UIScreen.mainScreen().bounds.height <= 480.0{
            //TODO: iPhone 4 not supported error message
        }
        /*Stripe.setDefaultPublishableKey("pk_test_Lp3E4ypwmrizs2jfEenXdwpr")
         
        
        guard let user = NSKeyedUnarchiver.unarchiveObjectWithFile(Constants.userFilePath()) as? User else{
            noUserFound()
            return true
        }
        
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        if user.isLoggedIn{
            /*containerController = ContainerController()
            containerController!.loggedInUser = user*/
            //window?.rootViewController = containerController!
         
                //UINavigationController(rootViewController: tc)
            
            
            
        }
        else{
            let lc = LoginController()
            lc.shouldShowBackButton = false
            window?.rootViewController = WelcomeController()
        }
        window!.makeKeyAndVisible()
        return true*/
        noUserFound()
        return true
    }
    
    
    func noUserFound(){
        
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        let tc = TutorialController()
        let addresses = [Address(school: "GEORGETOWN UNIVERSITY", dorm: "NEW SOUTH", room: "405")]
        tc.user = User(userID: "", addresses: addresses, jwt: "")
        window?.rootViewController = tc
       // window?.rootViewController = WelcomeController()
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
            containerController?.promptUserFeedBack()
        }
    }
    
    
}



