//
//  ParentControllers.swift
//  Slice
//
//  Created by Oliver Hill on 8/26/16.
//  Copyright © 2016 Oliver Hill. All rights reserved.
//

import UIKit

//A Base Class for a View Controller that has a back button and can swipe to access that back button but does not have navigation bar
//To use: 1. make sure to call super.viewDidLoad()
//        2. call actionForBackButton(:_)
//The addition of the back button and the handling of its control events will be taken care of

class NavBarless: UIViewController, UIGestureRecognizerDelegate {
    var backButton: UIButton?
    var backAction: (()->Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Constants.darkBlue
        addTop()
        let swipe = UIPanGestureRecognizer(target: self, action: #selector(self.didSwipe(_:)))
        swipe.delegate = self
        view.addGestureRecognizer(swipe)
    }
    
    //To be overridden by navBarred
    func addTop(){
        backButton = UIButton(frame: CGRect(x: 9, y: 20, width: 20, height: 20))
        backButton!.setImage(UIImage(imageLiteral: "back"), forState: .Normal)
        view.addSubview(backButton!)
    }
    
    func backPressed(){
        if backAction != nil{
            backAction!()
        }
    }
    
    func actionForBackButton(action: ()->Void){
        backAction = action
        backButton!.addTarget(self, action: #selector(backPressed), forControlEvents: .TouchUpInside)
    }
    
   
    func didSwipe(recognizer: UIPanGestureRecognizer){
        if recognizer.state == .Ended{
            let point = recognizer.translationInView(view)
            if(abs(point.x) >= abs(point.y)) && point.x > 40{
                backPressed()
            }
        }
    }
    
}

class NavBarred: NavBarless{
    
    //Adds the full navigation bar rather than just the back button
    override func addTop() {
        navigationController?.navigationBar.barTintColor = Constants.darkBlue
        let titleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 44))
        titleLabel.attributedText = Constants.getTitleAttributedString("DOORSLICE", size: 16, kern: 6.0)
        titleLabel.textAlignment = .Center
        navigationItem.titleView = titleLabel
        
        backButton = UIButton(type: .Custom)
        backButton!.setImage(UIImage(imageLiteral: "back"), forState: .Normal)
        backButton!.frame = CGRect(x: -40, y: -4, width: 20, height: 20)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton!)
    }
}