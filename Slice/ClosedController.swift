//
//  ClosedController.swift
//  Slice
//
//  Created by Oliver Hill on 8/10/16.
//  Copyright © 2016 Oliver Hill. All rights reserved.
//

import UIKit

//Displayed if pizza serving is not in operation when the user is on the app
class ClosedController: UIViewController, UIGestureRecognizerDelegate{
    
    var delegate: Slideable!
    var userID: String!
    
    override func viewDidLoad() {
        view.backgroundColor = Constants.darkBlue
        let swipe = UIPanGestureRecognizer()
        swipe.addTarget(self, action: #selector(didSwipe(_:)))
        view.addGestureRecognizer(swipe)
    }
    
    override func viewDidLayoutSubviews() {
        navigationController?.navigationBar.barTintColor = Constants.darkBlue
        
        let titleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 44))
        titleLabel.attributedText = Constants.getTitleAttributedString("DOORSLICE", size: 16, kern: 6.0)
        titleLabel.textAlignment = .Center
        navigationItem.titleView = titleLabel
        
        let closedView = UIImageView(frame: view.frame)
        closedView.image = UIImage(imageLiteral: "closed")
        view.addSubview(closedView)
        
        
        let menuButton = UIButton(type: .Custom)
        menuButton.setImage(UIImage(imageLiteral: "menu"), forState: .Normal)
        menuButton.addTarget(self, action: #selector(toggleMenu), forControlEvents: .TouchUpInside)
        menuButton.frame = CGRect(x: 0, y: -4, width: 18, height: 18)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: menuButton)
    }
    
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if delegate.menuCurrentlyShowing(){
            toggleMenu()
        }
    }
    
    func toggleMenu(){
        delegate.toggleMenu(nil)
    }

    func didSwipe(recognizer: UIPanGestureRecognizer){
    
        if recognizer.state == .Ended{
            let point = recognizer.translationInView(view)
            if(abs(point.x) >= abs(point.y)){
                if delegate.menuCurrentlyShowing() && point.x < 0{
                    delegate.toggleMenu(nil)
                }
                else if !delegate.menuCurrentlyShowing() && point.x > 40{
                    delegate.toggleMenu(nil)
                }
            }
        }
    }
}
