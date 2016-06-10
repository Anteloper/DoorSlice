//
//  ContainerController.swift
//  Slice
//
//  Created by Oliver Hill on 6/9/16.
//  Copyright © 2016 Oliver Hill. All rights reserved.
//


import UIKit

class ContainerController: UIViewController, Slideable {
    var sliceController: SliceController!
    var navController: UINavigationController!
    var menuController: MenuController?
    
    var menuIsVisible = false{
        didSet{
            showShadow(menuIsVisible)
        }
    }
    
    let amountVisibleOfSliceController: CGFloat = 110
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sliceController = SliceController()
        sliceController.delegate = self
        
        navController = UINavigationController(rootViewController: sliceController)
        view.addSubview(navController.view)
        addChildViewController(navController)
        navController.didMoveToParentViewController(self)
        
    }
    
    
    func toggleMenu() {
        
        if !menuIsVisible{
            if menuController == nil{
                menuController = MenuController()
                menuController?.delegate = self
                view.insertSubview(menuController!.view, atIndex: 0)
                addChildViewController(menuController!)
                menuController!.didMoveToParentViewController(self)
            }
        }
        
        if !menuIsVisible{
            menuIsVisible = true
            animateCenterPanelXPosition(navController.view.frame.width - amountVisibleOfSliceController)
        }
            
            
        else{
            animateCenterPanelXPosition(0) { finished in
                self.menuIsVisible = false
                self.menuController?.view.removeFromSuperview()
                self.menuController = nil
            }
        }
    }
    
    func animateCenterPanelXPosition(targetPosition: CGFloat, completion: ((Bool) ->Void)! = nil){
        
        UIView.animateWithDuration(0.3,
                                   delay: 0,
                                   usingSpringWithDamping: 0.8,
                                   initialSpringVelocity: 0,
                                   options: .CurveEaseInOut,
                                   animations: {
                                    self.navController.view.frame.origin.x = targetPosition},
                                   completion:completion
        )
    }
    
    func showShadow(shouldShowShadow: Bool){
        if shouldShowShadow{
            navController.view.layer.shadowOpacity = 0.8
        }
        else{
            navController.view.layer.shadowOpacity = 0.0
        }
    }
    
    
    func userSwipe(recognizer: UIPanGestureRecognizer) {
        if recognizer.state == .Ended{
            let point = recognizer.translationInView(sliceController.view)
            //Horizontal Swipe
            if(abs(point.x) >= abs(point.y)){
                //Right Swipe, Menu not already showing
                if point.x >= 0 && !menuIsVisible{
                    toggleMenu()
                }
                    //Left Swipe, Menu already showing
                else if point.x <= 0 && menuIsVisible{
                    toggleMenu()
                }
            }
        }
    }
    func userTap(){
        if menuIsVisible{
            toggleMenu()
        }
    }
    func menuCurrentlyShowing()->Bool{
        return menuIsVisible
    }
    
    func bringMenuToFullscreen(completion: ((Bool) ->Void)) {
        animateCenterPanelXPosition(view.frame.width, completion: completion)
    }
    func returnFromFullscreen() {
        animateCenterPanelXPosition(navController.view.frame.width - amountVisibleOfSliceController)
    }
}

internal struct Properties{
    
    //The amount of the main view that is still showing when the side menu slides out. Should match amountVisibleOfSliceController
    static let sliceControllerShowing: CGFloat = 110
    static let tiltColor = UIColor(red: 19/255.0,green: 157/255.0, blue: 234/255.0, alpha: 1.0)
    static let eucalyptus = UIColor(red: 38/255.0, green: 166/255.0, blue: 91/255.0, alpha: 1.0)
    
}