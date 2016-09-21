//
//  OrderProgressView.swift
//  Slice
//
//  Created by Oliver Hill on 6/11/16.
//  Copyright © 2016 Oliver Hill. All rights reserved.


import UIKit

//The top bar that appears while a user is in the process of placing an order
class OrderProgressView: UIView{
    
    var slices = [UIImageView]()
    var sliceOutlines = [UIImageView]()
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
        
        backgroundColor = UIColor.clear
        alpha = 1.0
        
        timer = TimerView(frame: frame)
        timer.delegate = delegate

        addSubview(timer)
        timer.animate(6.0)
    }
    
    
    func resetTimer(){
        timer.removeFromSuperview()
        addSubview(timer)
        sendSubview(toBack: timer)
        timer.animate(6.0)
        
    }
    
    func addSlice(_ ofType: Slice){
        let size:CGFloat = frame.width >= 375 ? 40 : 33
        let yVal:CGFloat = frame.width >= 375 ? 70 : 75
        let topSlice = UIImageView(frame: CGRect(x: frame.width/2-20, y: frame.height/2-20, width: size, height: size))
        topSlice.layer.minificationFilter = kCAFilterTrilinear
        let image = ofType == .cheese ? UIImage(imageLiteralResourceName: "smallCheese") : UIImage(imageLiteralResourceName: "smallPepperoni")
        topSlice.image = image
        topSlice.alpha = 1
        addSubview(topSlice)
        sendSubview(toBack: topSlice)
        slices.append(topSlice)
        
        UIView.animate(withDuration: 0.1, animations: { topSlice.frame.origin = CGPoint(x: 50 + (self.numSlices*size), y: yVal) } )
        bringSubview(toFront: topSlice)

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
