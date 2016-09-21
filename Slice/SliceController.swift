//
//  SliceController.swift
//  Slice
//
//  Created by Oliver Hill on 6/9/16.
//  Copyright © 2016 Oliver Hill. All rights reserved.
//

import UIKit

//The main view controller displayed when a user is logged in and Doorslice is open.
//The main role of this class is to allow a user to place an order and notify the delegate when they do
class SliceController: UIViewController, UIGestureRecognizerDelegate, Timeable {
    
    //MARK: Properties
    var delegate: Slideable?
    
    var orderProgressBar: OrderProgressView?
    let cancelButton = UIButton()
    
    let fadeView = UIView()
    lazy fileprivate var activityIndicator : CustomActivityIndicatorView = {return CustomActivityIndicatorView(image: UIImage(imageLiteralResourceName: "loading"))}()
    
    let pepperoniButton = UIButton()
    let cheeseButton = UIButton()

    var order = Order()
    
    var currentButtonShowing: UIButton!{
        didSet{
            if ( swipeCircles != nil){
                let currentInt = currentButtonShowing != pepperoniButton ? 1 : 0
                swipeCircles![currentInt].fill()
                swipeCircles![(currentInt+1)%2].unfill()
            }
        }
    }
    var swipeCircles: [SwipeCircle]?
   
    //MARK: Slice Pressed and Add Progress Bar
    func slicePressed(){
        if !delegate!.menuCurrentlyShowing(){
            if orderProgressBar == nil || orderProgressBar?.superview == nil{
                self.addProgressBar()
            }
            if order.totalSlices() < 8{
                currentButtonShowing.transform = CGAffineTransform(scaleX: 0, y: 0)
                let sliceType: Slice = currentButtonShowing == cheeseButton ? .cheese : .pepperoni
                order.add(sliceType)
                orderProgressBar?.resetTimer()
                orderProgressBar?.addSlice(sliceType)
                orderProgressBar?.numSlices += 1
            
                UIView.animate(withDuration: 0.2,
                                           delay: 0.0,
                                           usingSpringWithDamping: 0.5,
                                           initialSpringVelocity: 15,
                                           options: .curveLinear,
                                           animations: { self.currentButtonShowing.transform = CGAffineTransform.identity},
                                           completion: nil)
            }
            else{
                orderProgressBar?.timer.pause()
                Alerts.overload(self)
            }
        }
        else{
            delegate?.toggleMenu(nil)
        }
    }
    
    func addProgressBar(){
        view.addSubview(self.cancelButton)
        orderProgressBar = OrderProgressView(frame: view.frame)
        orderProgressBar!.delegate = self
        view.addSubview(orderProgressBar!)
        view.sendSubview(toBack: orderProgressBar!)
        view.bringSubview(toFront: cancelButton)
    }
    
    
    //MARK: Swipe and Swipe Handling Functions
    func didSwipe(_ recognizer: UIPanGestureRecognizer){
        if recognizer.state == .ended{
            if !delegate!.menuCurrentlyShowing(){
                let point = recognizer.translation(in: view)
                //Horizontal swipe
                if(abs(point.x) >= abs(point.y)){
                    swapButton(newButtonIsCheese: currentButtonShowing != cheeseButton, comingFromRight: point.x < 0)
                }
            }
            else{
                delegate!.toggleMenu(nil)
            }
        }
    }
    
    //Animates the new button in and the old one out
    func swapButton(newButtonIsCheese isCheese: Bool, comingFromRight: Bool){
        let positions = startPosition(fromRight: comingFromRight)
        let newButton = currentButtonShowing == cheeseButton ? pepperoniButton : cheeseButton
        
        newButton.frame.origin.x = positions[0]
        view.addSubview(newButton)
        UIView.animate(withDuration: 0.1,
                                   delay: 0.0,
                                   options: UIViewAnimationOptions.curveEaseIn,
                                   animations: {
                                        self.currentButtonShowing.frame.origin.x = positions[1]
                                        newButton.frame.origin.x = self.view.frame.width/12
                                   },
                                   completion: { _ in self.currentButtonShowing = newButton }
        )
    }
    
    //Returns an array where the first number is the beginning x position for the new button sliding in
    //The second number is the end x position of the button sliding out
    func startPosition(fromRight right: Bool)-> [CGFloat]{
        let positions = [0 - currentButtonShowing.frame.width, view.frame.width]
        return right ? positions.reversed() : positions
    }
    
    //MARK Touches Began
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        delegate?.userTap()
    }
    
    
    //MARK: Order Processing Functions
    func orderProcessing(){
        fadeView.frame = view.frame
        fadeView.backgroundColor = UIColor.black
        fadeView.alpha = 0.6
        view.addSubview(fadeView)
        
        activityIndicator.center = view.center
        view.addSubview(activityIndicator)
        view.bringSubview(toFront: activityIndicator)
        activityIndicator.startAnimating()
    }
    
    func clearCurrentOrder(){
        fadeView.removeFromSuperview()
        activityIndicator.stopAnimating()
        cancelButton.removeFromSuperview()
        orderProgressBar?.removeFromSuperview()
    }
    
    func orderCompleted(){
        activityIndicator.stopAnimating()
        fadeView.removeFromSuperview()
        orderProgressBar?.removeFromSuperview()
        cancelButton.removeFromSuperview()
        order.clear()
    }
    
    func orderCancelled(){
        order.clear()
        clearCurrentOrder()
    }
    
    //MARK: Setup Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Constants.darkBlue
        navigationBarSetup()
        configureSlices()
        configureCancel()
        addGestureRecognizer()
        view.addSubview(pepperoniButton)
        currentButtonShowing = pepperoniButton
        configureSwipeCircles()
    }
    
    func navigationBarSetup(){
        navigationController?.navigationBar.barTintColor = Constants.darkBlue
    
        let titleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 44))
        titleLabel.attributedText = Constants.getTitleAttributedString("DOORSLICE", size: 16, kern: 6.0)
        titleLabel.textAlignment = .center
        navigationItem.titleView = titleLabel
        
        let menuButton = UIButton(type: .custom)
        menuButton.setImage(UIImage(imageLiteralResourceName: "menu"), for: UIControlState())
        menuButton.addTarget(self, action: #selector(SliceController.toggleMenu), for: .touchUpInside)
        menuButton.frame = CGRect(x: 0, y: -4, width: 18, height: 18)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: menuButton)
    }
    
    //Called by menu press
    func toggleMenu(){
        delegate?.toggleMenu(nil)
    }
    
    func addGestureRecognizer(){
        let swipe = UIPanGestureRecognizer(target: self, action: #selector(SliceController.didSwipe))
        swipe.delegate = self
        view.addGestureRecognizer(swipe)
    }
    
    func configureSlices(){
        pepperoniButton.setBackgroundImage(UIImage(imageLiteralResourceName: "pepperoni"), for: UIControlState())
        pepperoniButton.contentMode = .scaleAspectFit
        
        let screenSizeAdjuster: CGFloat = UIScreen.main.bounds.height <= 480.0 ? -5 : 30
        pepperoniButton.frame = CGRect(origin: CGPoint(x: view.frame.width/12, y: view.frame.width/2+screenSizeAdjuster), size: CGSize(width: view.frame.width*5/6, height: view.frame.width*5/6))
        pepperoniButton.layer.minificationFilter = kCAFilterTrilinear
        pepperoniButton.adjustsImageWhenHighlighted = false
        pepperoniButton.alpha = 1.0
        pepperoniButton.addTarget(self, action: #selector(SliceController.slicePressed), for: .touchUpInside)
        
        cheeseButton.setBackgroundImage(UIImage(imageLiteralResourceName: "cheese"), for: UIControlState())
        cheeseButton.layer.minificationFilter = kCAFilterTrilinear
        cheeseButton.adjustsImageWhenHighlighted = false
        cheeseButton.contentMode = .scaleAspectFit
        cheeseButton.frame = CGRect(origin: CGPoint(x: view.frame.width/12, y: view.frame.width/2+screenSizeAdjuster), size: CGSize(width: view.frame.width*5/6, height: view.frame.width*5/6))
        cheeseButton.alpha = 1.0
        cheeseButton.addTarget(self, action: #selector(SliceController.slicePressed), for: .touchUpInside)
    }
    
    
    func configureCancel(){
        //cancelButton
        cancelButton.setBackgroundImage(UIImage(imageLiteralResourceName: "cancel"), for: UIControlState())
        cancelButton.layer.minificationFilter = kCAFilterTrilinear
        cancelButton.contentMode = .scaleAspectFit
        cancelButton.frame = CGRect(x: 10, y: 73, width: 34, height: 34)
        cancelButton.addTarget(self, action: #selector(SliceController.orderCancelled), for: .touchUpInside)
        view.bringSubview(toFront: cancelButton)
    }
    
    func configureSwipeCircles(){
        let cat: CGFloat = 7/2
        let one = SwipeCircle(frame: CGRect(x: view.frame.width/2 - (10 + cat), y: currentButtonShowing.frame.maxY+30, width: 7, height: 7))
        let two = SwipeCircle(frame: CGRect(x: view.frame.width/2 + (10 - cat), y: currentButtonShowing.frame.maxY+30, width: 7, height: 7))
        swipeCircles = [one, two]
        one.fill()
        view.addSubview(swipeCircles![0])
        view.addSubview(swipeCircles![1])
    }

    
    //MARK: Timeable Protocol Functions
    func timerEnded(_ didComplete: Bool) {
        if didComplete{
            delegate!.timerEnded(cheese: order.cheeseSlices, pepperoni: order.pepperoniSlices)
        }
    }
}

enum Slice{
    case cheese
    case pepperoni
}
