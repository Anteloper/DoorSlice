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
        self.backgroundColor = UIColor.clear
        self.frame = frame
        layer.cornerRadius = bounds.size.width/2
        clipsToBounds = true
        layer.borderColor = UIColor.gray.cgColor
        layer.borderWidth = 1.0
    }
    
    required init?(coder aDecoder: NSCoder) {fatalError("init(coder:) has not been implemented")}
    
    func fill(){
        backgroundColor = Constants.tiltColor
        layer.borderColor = UIColor.clear.cgColor
    }
    func unfill(){
        backgroundColor = UIColor.clear
        layer.borderColor = UIColor.gray.cgColor
    }
}
