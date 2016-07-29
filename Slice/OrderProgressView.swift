//
//  OrderProgressView.swift
//  Slice
//
//  Created by Oliver Hill on 6/11/16.
//  Copyright © 2016 Oliver Hill. All rights reserved.
//

import UIKit

//The top bar that appears while a user is in the process of placing an order
class OrderProgressView: UIView{
    
    var timer = TimerView()
    var delegate: Timeable?{
        didSet{
            timer.delegate = delegate
        }
    }
    
    var numSlices: CGFloat = 0//The number of slices showing at the top of the bar. Only a CGFloat to make positioning easier
    
    override init(frame: CGRect){
        super.init(frame: frame)
        self.frame = frame
        
        backgroundColor = UIColor.clearColor()
        alpha = 1.0
        
        timer = TimerView(frame: frame)
        timer.delegate = delegate

        addSubview(timer)
        timer.animate(6.0)
    }
    
    
    func resetTimer(){
        timer.removeFromSuperview()
        addSubview(timer)
        sendSubviewToBack(timer)
        timer.animate(6.0)
        
    }
    
    func addSlice(ofType: Slice){
        let topSlice = UIButton(frame: CGRect(x: frame.width/2-20, y: frame.height/2-20, width: 40, height: 40))
        let image = ofType == .Cheese ? UIImage(imageLiteral: "smallCheese") : UIImage(imageLiteral: "smallPepperoni")
        topSlice.setBackgroundImage(image, forState: .Normal)
        topSlice.alpha = 1
        addSubview(topSlice)
        sendSubviewToBack(topSlice)
        UIView.animateWithDuration(0.1, animations: { topSlice.frame.origin = CGPoint(x: 50 + (self.numSlices*40), y: 70) } )
        
        bringSubviewToFront(topSlice)
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

}
