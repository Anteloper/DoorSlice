//
//  ClosedController.swift
//  Slice
//
//  Created by Oliver Hill on 8/10/16.
//  Copyright © 2016 Oliver Hill. All rights reserved.
//

import UIKit

//Displayed if pizza serving is not in operation when the user is on the app. The user may still access the menu and all options in the menu
//In the same way the user may access the menu and all options in the menu when viewing an instance of SliceControler
class ClosedController: UIViewController, UIGestureRecognizerDelegate{
    
    var delegate: Slideable!
    var userID: String!
    var closedMessage: String!
    
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
        
        
        let closedView = UIImageView(frame: CGRect(x: 0, y: view.frame.midY-view.frame.width/3+15, width: view.frame.width, height: view.frame.width))
        closedView.layer.minificationFilter = kCAFilterTrilinear
        closedView.image = UIImage(imageLiteral: "closed")
        view.addSubview(closedView)
        
        let closedLabel = UILabel(frame: CGRect(x: 0, y: closedView.frame.minY-80, width: view.frame.width, height: 40))
        closedLabel.textAlignment = .Center
        closedLabel.attributedText = Constants.getTitleAttributedString("WE'RE CLOSED RIGHT NOW :(", size: 18, kern: 4.0)
        view.addSubview(closedLabel)
        
        let closedMess = UILabel(frame: CGRect(x: 10, y: closedView.frame.midY + 80, width: view.frame.width-20, height: 90))
        closedMess.numberOfLines = 0
        let attString = Constants.getTitleAttributedString(closedMessage, size: 16, kern: 2.0)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 9
        attString.addAttribute(NSParagraphStyleAttributeName, value:paragraphStyle, range:NSMakeRange(0, attString.length))
        closedMess.attributedText = attString
        closedMess.textAlignment = .Center
        view.addSubview(closedMess)
        
        
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
