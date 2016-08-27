//
//  SwipeCircle.swift
//  Slice
//
//  Created by Oliver Hill on 6/10/16.
//  Copyright © 2016 Oliver Hill. All rights reserved.
//


import UIKit

//One of the navigation dots that appear below the slice button
class SwipeCircle: UIView {
    
    
    override init(frame: CGRect){
        
        super.init(frame: frame)
        self.backgroundColor = UIColor.clearColor()
        self.frame = frame
        layer.cornerRadius = bounds.size.width/2
        clipsToBounds = true
        layer.borderColor = UIColor.grayColor().CGColor
        layer.borderWidth = 1.0
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func fill(){
        backgroundColor = Constants.tiltColor
        layer.borderColor = UIColor.clearColor().CGColor
    }
    func unfill(){
        backgroundColor = UIColor.clearColor()
        layer.borderColor = UIColor.grayColor().CGColor
    }
}
