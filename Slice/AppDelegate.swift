//
//  AppDelegate.swift
//  Slice
//
//  Created by Oliver Hill on 6/9/16.
//  Copyright © 2016 Oliver Hill. All rights reserved.
//
import UIKit
import Stripe
import Alamofire
import SwiftyJSON


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var containerController: ContainerController?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        Stripe.setDefaultPublishableKey(Constants.stripePublishableKey)
        retrieveAndSetPrices()
        
        window = UIWindow(frame: UIScreen.main.bounds)
       
        if checkFirstLaunch(){ return true }
        
        guard let user = NSKeyedUnarchiver.unarchiveObject(withFile: Constants.userFilePath()) as? User else{
            window?.rootViewController = LoginController()
            window!.makeKeyAndVisible()
            return true
        }
        
        if user.isLoggedIn{
            setupWithUser(user)
        }
        else{
            window?.rootViewController = LoginController()
        }
        
        window!.makeKeyAndVisible()

        return true
    }
    
    
    func checkFirstLaunch()->Bool{
        let isNotFirstLaunch = UserDefaults.standard.bool(forKey: "isNotFirstLaunch")
        if !isNotFirstLaunch{
            UserDefaults.standard.set(true, forKey: "isNotFirstLaunch")
            window?.rootViewController = WelcomeController()
            window!.makeKeyAndVisible()
        }
        return !isNotFirstLaunch
    }
    
    func setupWithUser(_ user: User){
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
    
    func retrieveAndSetPrices(){
        Alamofire.request(Constants.getPricesURLString, method: .post, parameters: nil).responseJSON{ response in
            switch response.result{
            case .success:
                if let value = response.result.value{
                    let json = JSON(value)
                    let cheesePrice = Int(json["Cheese"].doubleValue * 100)
                    let pepperoniPrice = Int(json["Pepperoni"].doubleValue * 100)
                    Constants.setPrices(cheese: cheesePrice, pepperoni: pepperoniPrice)
                }
            case .failure:
                break
            }
        }
    }
    
    func application(_ application: UIApplication, willChangeStatusBarFrame newStatusBarFrame: CGRect) {
        let windows = UIApplication.shared.windows
        for window in windows {
            window.removeConstraints(window.constraints)
        }
    }
    

    func applicationDidBecomeActive(_ application: UIApplication) {
        if containerController != nil{
            containerController!.viewDidLoad()
            containerController!.promptUserFeedBack()
        }
    }
}



