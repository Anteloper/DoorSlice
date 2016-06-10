//
//  SliceController.swift
//  Slice
//
//  Created by Oliver Hill on 6/9/16.
//  Copyright © 2016 Oliver Hill. All rights reserved.
//

import UIKit

//MARK: Slideable Protocol
//A menu can be slid out on top of items that conform to this protocol
protocol Slideable{
    func toggleMenu()
    func userSwipe(recognizer: UIPanGestureRecognizer)
    func userTap()
    func menuCurrentlyShowing()->Bool
    func bringMenuToFullscreen(completion: ((Bool) ->Void))
    func returnFromFullscreen()
}



class SliceController: UIViewController, UIGestureRecognizerDelegate {
    
    //MARK:Properties
    var delegate: Slideable?
    
    var slicesEnRoute = 0{ //Used to check update bar, should be updated upon delivery
        didSet{
            if slicesEnRoute == 0{
                clearCurrentOrder()
            }
        }
    }
    
    var centerNavController: UINavigationController!
    var centerSliceController: SliceController!
    
    
    let cancelLabel = UILabel()
    let cancelButton = UIButton()
    var cancelPath = CircleView()
    let cancelImage = UIImageView()
    var cancelTimer = NSTimer()
    
    let pepperoniButton = UIButton()
    let cheeseButton = UIButton()
    
    var updateBar = UIView()
    let updateLabel = UILabel()
    var settingsButton = UIButton()
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
    
    
    //MARK: viewDidLoad
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
    
    //MARK: Gesture Handling
    //Switches the current button image
    func didSwipe(recognizer: UIPanGestureRecognizer){
        if recognizer.state == .Ended{
            let point = recognizer.translationInView(view)
            //Horizontal Swipe
            if(abs(point.x) >= abs(point.y)){
                
                swapButton(newButtonIsCheese: currentButtonShowing != cheeseButton, comingFromRight: point.x < 0)
                
            }
        }
    }
    
    
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
    
    func addGestureRecognizer(){
        let swipe = UIPanGestureRecognizer(target: self, action: #selector(SliceController.didSwipe))
        swipe.delegate = self
        view.addGestureRecognizer(swipe)
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        delegate?.userTap()
    }
    
    func slicePressed(){
        if !delegate!.menuCurrentlyShowing(){
            
            //Animate
            currentButtonShowing.transform = CGAffineTransformMakeScale(0, 0)
            UIView.animateWithDuration(0.5,
                                       delay: 0.0,
                                       usingSpringWithDamping: 0.5,
                                       initialSpringVelocity: 15,
                                       options: .CurveLinear,
                                       animations: { self.currentButtonShowing.transform = CGAffineTransformIdentity},
                                       completion: { didComplete in
                                        if didComplete {
                                            self.orderNextSlice()
                                        }
                }
            )
        }
        else{delegate?.toggleMenu()}
    }
    
    func orderNextSlice(){
        //TODO: This code after order is properly processed
        settingsButton.removeFromSuperview()
        if slicesEnRoute == 0 {
            configureUpdateBar()
            configureCancel()
            UIView.animateWithDuration(0.5,
                                       delay: 0.0,
                                       usingSpringWithDamping: 0.5,
                                       initialSpringVelocity: 15,
                                       options: .CurveLinear,
                                       animations: { self.updateBar.frame.origin = CGPoint(x: 0, y: self.view.frame.height-self.updateBar.frame.height) },
                                       completion: { (didComplete) in
                                        if didComplete{
                                            UIView.animateWithDuration(0.5, animations: {
                                                self.cancelLabel.frame.origin = CGPoint(x: 0, y: 64)
                                                self.cancelButton.frame.origin = CGPoint(x: self.view.frame.width - (self.updateBar.frame.height/2+15), y:64+self.updateBar.frame.height/4+3)
                                            })
                                        }
                }
            )
        }
        
        slicesEnRoute+=1
        updateLabel.frame = updateBar.frame
        updateLabel.text =  slicesEnRoute == 1 ? "\(slicesEnRoute) slice en route" : "\(slicesEnRoute) slices en route"
        view.addSubview(updateLabel)
        
    }
    
    func clearCurrentOrder(){
        cancelLabel.removeFromSuperview()
        cancelButton.removeFromSuperview()
        updateBar.removeFromSuperview()
        updateLabel.removeFromSuperview()
    }
    
    func toggleMenu(){
        delegate?.toggleMenu()
    }
    
    
    
    //MARK: Cancel Animation and Processing Functions
    func cancelBegan(){
        
        cancelButton.transform = CGAffineTransformMakeScale(0, 0)
        UIView.animateWithDuration(0.5,
                                   delay: 0.0,
                                   usingSpringWithDamping: 0.5,
                                   initialSpringVelocity: 15,
                                   options: .CurveLinear,
                                   animations: { self.cancelButton.transform = CGAffineTransformIdentity},
                                   completion: nil
        )
        
        cancelImage.frame = CGRect(x: view.frame.width/2-30, y: cancelLabel.frame.maxY+10, width: 60, height: 60)
        cancelImage.image = UIImage(imageLiteral: "cancel2")
        view.addSubview(cancelImage)
        
        //Not sure why these numbers work but they do
        cancelPath = CircleView(frame: CGRect(x: cancelImage.frame.origin.x-10, y: cancelImage.frame.origin.y-10, width: 80, height: 80))
        view.addSubview(cancelPath)
        cancelPath.animateCricle(1.5)
        
    }
    
    func cancelEnded(){
        cancelPath.removeFromSuperview()
        cancelImage.removeFromSuperview()
        
        if cancelPath.timeElapsed >= 1.2{
            slicesEnRoute = 0
        }
    }
    
    
    
    //MARK: Setup Functions
    func navigationBarSetup(){
        let titleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 44))
        titleLabel.backgroundColor = UIColor.clearColor()
        titleLabel.font = UIFont(name: "GillSans-Light", size: 25)
        titleLabel.textColor = Properties.tiltColor
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
    
    
    func configureSlices(){
        pepperoniButton.setBackgroundImage(UIImage(imageLiteral: "pepperoni"), forState: .Normal)
        pepperoniButton.contentMode = .ScaleAspectFit
        pepperoniButton.frame = CGRect(origin: CGPoint(x: view.frame.width/12, y: view.frame.width/2+30), size: CGSize(width: view.frame.width*5/6, height: view.frame.width*5/6))
        pepperoniButton.addTarget(self, action: #selector(SliceController.slicePressed), forControlEvents: .TouchUpInside)
        
        cheeseButton.setBackgroundImage(UIImage(imageLiteral: "cheese"), forState: .Normal)
        cheeseButton.contentMode = .ScaleAspectFit
        cheeseButton.frame = CGRect(origin: CGPoint(x: view.frame.width/12, y: view.frame.width/2+30), size: CGSize(width: view.frame.width*5/6, height: view.frame.width*5/6))
        cheeseButton.addTarget(self, action: #selector(SliceController.slicePressed), forControlEvents: .TouchUpInside)
    }
    
    func configureUpdateBar(){
        //Set properties of updateBar off screen
        updateBar = UIView(frame: CGRect(x: 0, y: view.frame.height, width: view.frame.width, height: view.frame.height/10))
        updateBar.alpha = 0.8
        updateBar.backgroundColor = Properties.tiltColor
        view.addSubview(updateBar)
        
        //Set all properties except text of updateLabel
        updateLabel.alpha = 0.8
        updateLabel.backgroundColor = UIColor.clearColor()
        updateLabel.textColor = UIColor.whiteColor()
        updateLabel.font = UIFont(name: "GillSans-Light", size: 30)
        updateLabel.textAlignment = .Center
        
    }
    
    func configureCancel(){
        //cancelLabel
        cancelLabel.frame = CGRect(x: 0, y: 0-updateBar.frame.height, width: view.frame.width, height: updateBar.frame.height)
        cancelLabel.backgroundColor = UIColor.redColor()
        cancelLabel.textColor = UIColor.whiteColor()
        cancelLabel.alpha = 0.5
        cancelLabel.textAlignment = .Left
        cancelLabel.font = UIFont(name: "GillSans-Light", size: 20)
        cancelLabel.textAlignment = .Center
        cancelLabel.text = "Hold to cancel order"
        view.addSubview(cancelLabel)
        
        
        //cancelButton
        cancelButton.setBackgroundImage(UIImage(imageLiteral: "cancel"), forState: .Normal)
        cancelButton.contentMode = .ScaleAspectFit
        cancelButton.frame = CGRect(x: self.view.frame.width - (self.updateBar.frame.height/2+15), y: cancelLabel.frame.origin.y + cancelLabel.frame.height/2, width: cancelLabel.frame.height/2, height: cancelLabel.frame.height/2)
        cancelButton.addTarget(self, action: #selector(SliceController.cancelBegan), forControlEvents: .TouchDown)
        cancelButton.addTarget(self, action: #selector(SliceController.cancelEnded), forControlEvents: [.TouchUpInside, .TouchDragExit, .TouchCancel])
        view.addSubview(cancelButton)
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
    
}