//
//  CircleView.swift
//  Slice
//
//  Created by Oliver Hill on 6/9/16.
//  Copyright © 2016 Oliver Hill. All rights reserved.
//

import UIKit


//View wrapper for a circle drawing animation
class CircleView: UIView {
    
    var circleLayer: CAShapeLayer!
    var startTime: NSDate!
    
    
    var timeElapsed: NSTimeInterval?{
        didSet{
            if timeElapsed > 1.2{
                popCircle()
            }
        }
    }
    
    override init(frame: CGRect){
        
        super.init(frame: frame)
        self.backgroundColor = UIColor.clearColor()
        
        
        
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: frame.size.width/2.0, y:frame.size.height/2.0),
                                      radius: (frame.size.width-10)/2, startAngle: 0.0,
                                      endAngle: CGFloat(M_PI * 2.0), clockwise: true)
        
        circleLayer = CAShapeLayer()
        circleLayer.path = circlePath.CGPath
        circleLayer.fillColor = UIColor.clearColor().CGColor
        circleLayer.strokeColor = UIColor.redColor().CGColor
        circleLayer.lineWidth = 5.0
        circleLayer.opacity = 0.5
        circleLayer.strokeEnd = 0.0
        
        layer.addSublayer(circleLayer)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func animateCircle(duration: NSTimeInterval){
        
        startTime = NSDate()
        CATransaction.begin()
        CATransaction.setCompletionBlock({ self.timeElapsed = NSDate().timeIntervalSinceDate(self.startTime) })
        
        //animate the strokeEnd property of the circleLayer
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        
        animation.duration = duration
        
        //Animate from no circle to a full circle
        animation.fromValue = 0
        animation.toValue = 1
        
        //Linear animation
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        
        
        //So that the value is correct when the animation ends
        circleLayer.strokeEnd = 1.0
        
        //Do the actual animation
        circleLayer.addAnimation(animation, forKey: "animateCircle")
        CATransaction.commit()
        
    }
    
    
    func popCircle(){
        
        self.transform = CGAffineTransformMakeScale(0, 0)
        UIView.animateWithDuration(0.5,
                                   delay: 0.0,
                                   usingSpringWithDamping: 0.5,
                                   initialSpringVelocity: 15,
                                   options: .CurveLinear,
                                   animations: { self.transform = CGAffineTransformIdentity},
                                   completion: nil
        )
    }
}
