//
//  TimerView.swift
//  Slice
//
//  Created by Oliver Hill on 6/11/16.
//  Copyright © 2016 Oliver Hill. All rights reserved.
//

import UIKit

//The bar that moves across the OrderProgressView to indicate timing
class TimerView: UIView {
    
    var delegate: Timeable?
    var lineLayer: CAShapeLayer!
    
    var startTime: NSDate!
    
    
    override init(frame: CGRect){
        
        super.init(frame: frame)
    
        self.backgroundColor = UIColor.clearColor()
        alpha = 0.7
        
        let linePath = UIBezierPath()
        
        //No idea why the frames aren't lining up the same
        linePath.moveToPoint(CGPoint(x: 0, y: 87))
        linePath.addLineToPoint(CGPoint(x: frame.maxX , y: 87))
       
        lineLayer = CAShapeLayer()
        lineLayer.path = linePath.CGPath
        lineLayer.fillColor = UIColor.clearColor().CGColor
        lineLayer.strokeColor = Constants.tiltColorFade.CGColor
        lineLayer.lineWidth = 60
        lineLayer.opacity = 1.0
        lineLayer.strokeEnd = 0.0
        
        layer.addSublayer(lineLayer)

    }
    

    func animate(duration: NSTimeInterval){
        
        startTime = NSDate()
        CATransaction.begin()
        CATransaction.setCompletionBlock({
            if self.delegate != nil {
                let timeElapsed = NSDate().timeIntervalSinceDate(self.startTime)
                self.delegate!.timerEnded(timeElapsed >= 6.0)
                
            }
        })
        
        //animate the strokeEnd property of the lineLayer
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        
        animation.duration = duration
        
        //Animate from no circle to a full circle
        animation.fromValue = 0
        animation.toValue = 1
        
        //Linear animation
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        
        //So that the value is correct when the animation ends
        lineLayer.strokeEnd = 1.0
        
        //Do the actual animation
        lineLayer.addAnimation(animation, forKey: "animateCircle")
        CATransaction.commit()
        
    }

    func pause(){
        let pausedTime = lineLayer.convertTime(CACurrentMediaTime(), fromLayer: nil)
        lineLayer.speed = 0.0
        lineLayer.timeOffset = pausedTime
        
    }
    
    func resume(){
        let pausedTime = lineLayer.timeOffset
        lineLayer.speed = 1.0
        lineLayer.timeOffset = 0.0
        lineLayer.beginTime = 0.0
        let timeSincePause = layer.convertTime(CACurrentMediaTime(), fromLayer: nil)-pausedTime
        layer.beginTime = timeSincePause
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
