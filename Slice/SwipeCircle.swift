//
//  SwipeCircle.swift
//  Slice
//
//  Created by Oliver Hill on 6/10/16.
//  Copyright © 2016 Oliver Hill. All rights reserved.
//

import UIKit

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
        backgroundColor = Properties.tiltColor
    }
    func unfill(){
        backgroundColor = UIColor.clearColor()
    }
    
}
