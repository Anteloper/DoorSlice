//
//  ActivityIndicator.swift
//  Slice
//
//  Created by Oliver Hill on 7/2/16.
//  Copyright © 2016 Oliver Hill. All rights reserved.
//

import UIKit
import QuartzCore

//Spinner Class. To use just init, set center, and call startAnimating and stopAnimating. 
class CustomActivityIndicatorView: UIView {
    
    lazy fileprivate var animationLayer : CALayer = {
        return CALayer()
    }()
    
    var isAnimating : Bool = false
    var hidesWhenStopped : Bool = true
    
    //MARK: Initializers
    init(image : UIImage) {
        let frame : CGRect = CGRect(x: 0.0, y: 0.0, width: image.size.width, height: image.size.height)
        
        super.init(frame: frame)
        
        animationLayer.frame = frame
        animationLayer.contents = image.cgImage
        animationLayer.masksToBounds = true
        
        self.layer.addSublayer(animationLayer)
        
        addRotation(forLayer: animationLayer)
        pause(layer: animationLayer)
        self.isHidden = true
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    //MARK: Animation Functions
    func addRotation(forLayer layer : CALayer) {
        let rotation : CABasicAnimation = CABasicAnimation(keyPath:"transform.rotation.z")
        
        rotation.duration = 1.0
        rotation.isRemovedOnCompletion = false
        rotation.repeatCount = HUGE
        rotation.fillMode = kCAFillModeForwards
        rotation.fromValue = NSNumber(value: 0.0 as Float)
        rotation.toValue = NSNumber(value: 3.14 * 2.0 as Float)
        
        layer.add(rotation, forKey: "rotate")
    }
    
    func pause(layer : CALayer) {
        let pausedTime = layer.convertTime(CACurrentMediaTime(), from: nil)
        
        layer.speed = 0.0
        layer.timeOffset = pausedTime
        
        isAnimating = false
    }
    
    func resume(layer : CALayer) {
        let pausedTime : CFTimeInterval = layer.timeOffset
        
        layer.speed = 1.0
        layer.timeOffset = 0.0
        layer.beginTime = 0.0
        
        let timeSincePause = layer.convertTime(CACurrentMediaTime(), from: nil) - pausedTime
        layer.beginTime = timeSincePause
        
        isAnimating = true
    }
    
    func startAnimating () {
        if isAnimating { return }
        
        if hidesWhenStopped {
            self.isHidden = false
        }
        resume(layer: animationLayer)
    }
    
    func stopAnimating () {
        if hidesWhenStopped {
            self.isHidden = true
        }
        pause(layer: animationLayer)
    }
}
