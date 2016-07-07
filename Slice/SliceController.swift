//
//  SliceController.swift
//  Slice
//
//  Created by Oliver Hill on 6/9/16.
//  Copyright © 2016 Oliver Hill. All rights reserved.
//

import UIKit


class SliceController: UIViewController, UIGestureRecognizerDelegate, Timeable {
    
    //MARK: Properties
    var delegate: Slideable?
    
    var centerNavController: UINavigationController!
    var centerSliceController: SliceController!
    
    var orderProgressBar: OrderProgressView?
    var orderInfoScreen: OrderDetailsView?
    
    let cancelButton = UIButton()
    var cancelPath = CircleView()
    
    let fadeView = UIView()
    lazy private var activityIndicator : CustomActivityIndicatorView = {return CustomActivityIndicatorView(image: UIImage(imageLiteral: "loading-1"))}()
    
    let pepperoniButton = UIButton()
    let cheeseButton = UIButton()
    
    var updateBar = UIView()
    let updateLabel = UILabel()
    
    var updateBarIsShowing = false
    var orderDetailsViewIsExpanded = false{didSet{(print(orderDetailsViewIsExpanded)); print("menuCurrentlyShowing: ", delegate!.menuCurrentlyShowing())}}
    
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
    
    //let cancelImage = UIImageView()
    //var cancelTimer = NSTimer()
   
    //MARK: Slice Pressed and Add Progress Bar
    func slicePressed(){
        if !delegate!.menuCurrentlyShowing(){
            
            //Animate
            currentButtonShowing.transform = CGAffineTransformMakeScale(0, 0)
            
            if orderProgressBar == nil || orderProgressBar?.superview == nil{
                self.addProgressBar()
            }
            
            let sliceType: Slice = currentButtonShowing == cheeseButton ? .Cheese : .Pepperoni
            order.add(sliceType)
            
            
            orderProgressBar?.resetTimer()
            orderProgressBar?.addSlice(sliceType)
            orderProgressBar?.numSlices += 1
            
            
            UIView.animateWithDuration(0.3,
                                       delay: 0.0,
                                       usingSpringWithDamping: 0.5,
                                       initialSpringVelocity: 15,
                                       options: .CurveLinear,
                                       animations: { self.currentButtonShowing.transform = CGAffineTransformIdentity},
                                       completion: nil
            )
        }
            
        else{
            delegate?.toggleMenu()
        }
        
    }
    
    func addProgressBar(){
        
        view.addSubview(self.cancelButton)
        orderProgressBar = OrderProgressView(frame: view.frame)
        orderProgressBar!.delegate = self
        view.addSubview(orderProgressBar!)
        view.sendSubviewToBack(orderProgressBar!)
        view.bringSubviewToFront(cancelButton)
        
    }
    
    
    //MARK: Swipe and Swipe Handling Functions
    func didSwipe(recognizer: UIPanGestureRecognizer){
        if !delegate!.menuCurrentlyShowing(){
            if recognizer.state == .Ended{
                let point = recognizer.translationInView(view)
                //Horizontal swipe
                if(abs(point.x) >= abs(point.y)) && !orderDetailsViewIsExpanded{
                    swapButton(newButtonIsCheese: currentButtonShowing != cheeseButton, comingFromRight: point.x < 0)
                }
                //Vertical swipe
                else if abs(point.y) >= abs(point.x){
                    //Upward
                    if point.y <= 0 && updateBarIsShowing && !orderDetailsViewIsExpanded{
                        addOrderScreen()
                        orderDetailsViewIsExpanded = true
                    }
                    //Downward
                    else if point.y >= 0 {
                        orderInfoScreen?.dismiss()
                        orderDetailsViewIsExpanded = false
                    }
                }
            }
        }
        else{
            //delegate!.toggleMenu()
        }
    }
    
    //Brings up order details screen
    func addOrderScreen(){
        print("yep")
        let detailFrame  = CGRect(x: 0, y: view.frame.height, width: view.frame.width, height: view.frame.height*2/3)
        
        orderInfoScreen = OrderDetailsView(withframe: detailFrame, pepperoniSlices: Int(order.pepperoniSlices), cheeseSlices: Int(order.cheeseSlices), address: delegate!.getPaymentAndAddress().1, card: delegate!.getPaymentAndAddress().0)

        view.addSubview(orderInfoScreen!)
        UIView.animateWithDuration(0.4, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 5.0,
                                   options: [],
                                   animations: {self.orderInfoScreen!.frame.origin = CGPoint(x: 0, y: self.view.frame.height/3)},
                                   completion: nil)
    }
    
    //Animates the new button in and the old one out
    func swapButton(newButtonIsCheese isCheese: Bool, comingFromRight: Bool){
        let positions = startPosition(comingFromRight)
        let newButton = currentButtonShowing == cheeseButton ? pepperoniButton : cheeseButton
        
        newButton.frame.origin = positions[0]
        view.addSubview(newButton)
        UIView.animateWithDuration(0.1,
                                   delay: 0.0,
                                   options: UIViewAnimationOptions.CurveEaseIn,
                                   animations: {
                                        self.currentButtonShowing.frame.origin = positions[1]
                                        newButton.frame.origin = CGPoint(x: self.view.frame.width/12, y: self.view.frame.width/2+30)
                                    
                                   },
                                   completion: { didcomplete in
                                        self.currentButtonShowing = newButton
                                   }
            
        )
        
    }
    
    //Returns an array where the first point is the beginning point for the new button sliding in
    //The second point is the end position of the button sliding out
    func startPosition(right: Bool)-> [CGPoint]{
        
        let pos1 = CGPoint(x: 0 - currentButtonShowing.frame.width, y: view.frame.width/2+30)
        let pos2 = CGPoint(x: view.frame.width, y: view.frame.width/2+30)
        
        if right{
            return [pos2,pos1]
        }
        return [pos1, pos2]
        
    }
    
    //MARK Touches Began
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if !delegate!.menuCurrentlyShowing() && orderDetailsViewIsExpanded{
            if !CGRectContainsPoint(orderInfoScreen!.frame, (touches.first?.locationInView(view))!){
                orderInfoScreen!.dismiss()
                orderDetailsViewIsExpanded = false
            }
        }
        delegate?.userTap()
    }
    
    
    //MARK: Order Processing Functions
    func orderProcessing(){
        fadeView.frame = view.frame
        fadeView.backgroundColor = UIColor.blackColor()
        fadeView.alpha = 0.6
        view.addSubview(fadeView)
        
        activityIndicator.center = view.center
        view.addSubview(activityIndicator)
        view.bringSubviewToFront(activityIndicator)
        activityIndicator.startAnimating()
    }
    
    func clearCurrentOrder(){
        fadeView.removeFromSuperview()
        activityIndicator.stopAnimating()
        cancelButton.removeFromSuperview()
        updateBar.removeFromSuperview()
        updateLabel.removeFromSuperview()
        orderProgressBar?.removeFromSuperview()
        
    }
    
    func orderCompleted(){
        configureUpdateBar()
       
        //configureCancel()
    
        activityIndicator.stopAnimating()
        fadeView.removeFromSuperview()
        orderProgressBar?.removeFromSuperview()
        cancelButton.removeFromSuperview()
        
        
        UIView.animateWithDuration(0.5,
                                    delay: 0.0,
                                    usingSpringWithDamping: 0.5,
                                    initialSpringVelocity: 15,
                                    options: .CurveLinear,
                                    animations: { self.updateBar.frame.origin = CGPoint(x: 0, y: self.view.frame.height-self.updateBar.frame.height) },
                                    completion: nil
                
        )
        updateLabel.frame = CGRect(origin: updateBar.frame.origin, size: CGSize(width: view.frame.width, height: view.frame.height/12))
        updateLabel.text =  order.totalSlices() == 1 ? "1 slice en route" : "\(order.totalSlices()) slices en route"
        view.addSubview(updateLabel)
        updateBarIsShowing = true

    }
    
    func orderCancelled(){
        order.clear()
        clearCurrentOrder()
    }
    
    
    //MARK: Setup Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationBarSetup()
        configureSlices()
        configureCancel()
        addGestureRecognizer()
        view.addSubview(pepperoniButton)
        currentButtonShowing = pepperoniButton
        configureSwipeCircles()
        view.backgroundColor = UIColor.whiteColor()
    }
    
    func navigationBarSetup(){
        let titleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 44))
        titleLabel.backgroundColor = UIColor.clearColor()
        titleLabel.font = UIFont(name: "GillSans-Light", size: 25)
        titleLabel.textColor = Constants.tiltColor
        titleLabel.alpha = 0.8
        titleLabel.textAlignment = .Center
        titleLabel.text = "Slice"
        navigationItem.titleView = titleLabel
        
        let menuButton = UIButton(type: .Custom)
        menuButton.setImage(UIImage(imageLiteral: "menu"), forState: .Normal)
        menuButton.addTarget(self, action: #selector(SliceController.toggleMenu), forControlEvents: .TouchUpInside)
        menuButton.frame = CGRect(x: 0, y:0, width: 25, height: 25)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: menuButton)
        
    }
    
    //Called by menu press
    func toggleMenu(){
        delegate?.toggleMenu()
    }
    
    func addGestureRecognizer(){
        let swipe = UIPanGestureRecognizer(target: self, action: #selector(SliceController.didSwipe))
        swipe.delegate = self
        view.addGestureRecognizer(swipe)
    }
    
    func configureSlices(){
        pepperoniButton.setBackgroundImage(UIImage(imageLiteral: "pepperoni"), forState: .Normal)
        pepperoniButton.contentMode = .ScaleAspectFit
        pepperoniButton.frame = CGRect(origin: CGPoint(x: view.frame.width/12, y: view.frame.width/2+30), size: CGSize(width: view.frame.width*5/6, height: view.frame.width*5/6))
        pepperoniButton.adjustsImageWhenHighlighted = false
        pepperoniButton.addTarget(self, action: #selector(SliceController.slicePressed), forControlEvents: .TouchUpInside)
        
        cheeseButton.setBackgroundImage(UIImage(imageLiteral: "cheese"), forState: .Normal)
        cheeseButton.adjustsImageWhenHighlighted = false
        cheeseButton.contentMode = .ScaleAspectFit
        cheeseButton.frame = CGRect(origin: CGPoint(x: view.frame.width/12, y: view.frame.width/2+30), size: CGSize(width: view.frame.width*5/6, height: view.frame.width*5/6))
        cheeseButton.addTarget(self, action: #selector(SliceController.slicePressed), forControlEvents: .TouchUpInside)
    }
    
    func configureUpdateBar(){
        //Set properties of updateBar off screen
        updateBar = UIView(frame: CGRect(x: 0, y: view.frame.height, width: view.frame.width, height: view.frame.height/10))
        updateBar.alpha = 0.8
        updateBar.backgroundColor = Constants.tiltColor
        view.addSubview(updateBar)
        
        
        //Set all properties except text of updateLabel
        updateLabel.alpha = 0.8
        updateLabel.backgroundColor = UIColor.clearColor()
        updateLabel.textColor = UIColor.whiteColor()
        updateLabel.font = UIFont(name: "GillSans-Light", size: 30)
        updateLabel.textAlignment = .Center
        
        //Add upArrow ImageView
        let upArrowView = UIImageView(frame: CGRect(x: view.frame.width/2-20, y:view.frame.height/10-20, width: 40, height: 20))
        upArrowView.image = UIImage(imageLiteral: "uparrow")
        updateBar.addSubview(upArrowView)
        updateBar.bringSubviewToFront(upArrowView)

    }
    
    func configureCancel(){
        //cancelButton
        cancelButton.setBackgroundImage(UIImage(imageLiteral: "cancel2"), forState: .Normal)
        cancelButton.contentMode = .ScaleAspectFit
        cancelButton.frame = CGRect(x: 10, y: 73, width: view.frame.height/20, height: view.frame.height/20)
        cancelButton.addTarget(self, action: #selector(SliceController.orderCancelled), forControlEvents: .TouchUpInside)
        view.bringSubviewToFront(cancelButton)
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
    func timerEnded(didComplete: Bool) {
        if didComplete{
            delegate?.payForOrder(cheese: order.cheeseSlices, pepperoni: order.pepperoniSlices)
        }
    }
 
}