//
//  OrderDetailsView.swift
//  Slice
//
//  Created by Oliver Hill on 6/14/16.
//  Copyright © 2016 Oliver Hill. All rights reserved.
//

import UIKit

//The slide-up view that appears when the updateBar is swiped upwards
class OrderDetailsView: UIView {
    
    init(withframe frame: CGRect, pepperoniSlices: Int, cheeseSlices: Int, address: String, card: String){
        super.init(frame: frame)
        self.frame = frame
        
        backgroundColor = Constants.tiltColor
        alpha = 1.0
        
        addOrderDetailsLabel()
        addSliceLabel(cheeseSlices, pepperoniSlices: pepperoniSlices)
        addAddressLabel(address)
        addCardLabel(card)
        addCancel()
    }
    
    
    func addCancel(){
        let cancelButton = UIButton(frame: CGRect(x: frame.width-40, y: -20, width: 40, height: 40))
        cancelButton.setBackgroundImage(UIImage(imageLiteral: "cancelblack"), forState: .Normal)
        cancelButton.addTarget(self, action: #selector(dismiss), forControlEvents: .TouchUpInside)
        addSubview(cancelButton)
    }
    
    func dismiss(){
        UIView.animateWithDuration(0.2, animations: {self.frame.origin = CGPoint(x: 0, y: self.frame.height*2)})
    }
    
    func addOrderDetailsLabel(){
        let orderDetailsLabel = UILabel(frame: CGRect(x: 10, y: 20, width: frame.width-10, height: frame.height/10))
        orderDetailsLabel.text = "Order Details:"
        orderDetailsLabel.font = UIFont(name: "GillSans-Light", size: 20)
        orderDetailsLabel.textAlignment = .Center
        orderDetailsLabel.textColor = UIColor.whiteColor()
        addSubview(orderDetailsLabel)
        
    }
    
    func addSliceLabel(cheeseSlices: Int, pepperoniSlices: Int){
        
        let slice = UILabel(frame: CGRect(x: 10, y: 60 + (frame.height/10), width: frame.width-20, height: frame.height/10))
        slice.text = "Slices: "
        slice.font = UIFont(name: "GillSans-Light", size: 20)
        slice.textAlignment = .Left
        slice.textColor = UIColor.whiteColor()
        addSubview(slice)

        
        let sliceDetails = UILabel(frame: CGRect(x: 10, y: 60 + (frame.height/10), width: frame.width-20, height: frame.height/10))
        var sliceString = ""
        if cheeseSlices != 0 {
            sliceString = cheeseSlices == 1 ? "1 cheese slice" : "\(cheeseSlices) cheese slices"
            if pepperoniSlices != 0{
                sliceString += " and "
            }
        }
        if pepperoniSlices != 0{
            sliceString += pepperoniSlices == 1 ? "1 pepperoni slice" :  "\(pepperoniSlices) peperoni slices"
        }
        
        sliceDetails.textColor = UIColor.whiteColor()
        sliceDetails.text = sliceString
        sliceDetails.font = UIFont(name: "GillSans-Light", size: 20)
        sliceDetails.textAlignment = .Right
        addSubview(sliceDetails);
        
    }
    
    func addAddressLabel(address: String){
        let addressLabel = UILabel(frame: CGRect(x: 10, y: 80 + 2*frame.height/10, width: frame.width-20, height: frame.height/10))
        addressLabel.text = "Delivering To: "
        addressLabel.font = UIFont(name: "GillSans-Light", size: 20)
        addressLabel.textAlignment = .Left
        addressLabel.textColor = UIColor.whiteColor()
        addSubview(addressLabel)
        
        let addressLabel2 = UILabel(frame: CGRect(x: 10, y: 80 + 2*frame.height/10, width: frame.width-20, height: frame.height/10))
        addressLabel2.text = address
        addressLabel2.font = UIFont(name: "GillSans-Light", size: 20)
        addressLabel2.textAlignment = .Right
        addressLabel2.textColor = UIColor.whiteColor()
        addSubview(addressLabel2)
    }
    
    func addCardLabel(card: String){
        let cardLabel = UILabel(frame: CGRect(x: 10, y: 120+3*frame.width/10, width: frame.width-20, height: frame.height/10))
        cardLabel.text = "Payment Method: "
        cardLabel.font = UIFont(name: "GillSans-Light", size: 20)
        cardLabel.textAlignment = .Left
        cardLabel.textColor = UIColor.whiteColor()
        addSubview(cardLabel)
        
        
        
        let cardLabel2 = UILabel(frame: CGRect(x: 10, y: 120+3*frame.width/10, width: frame.width-20, height: frame.height/10))
        cardLabel2.text = card
        cardLabel2.font = UIFont(name: "GillSans-Light", size: 20)
        cardLabel2.textAlignment = .Right
        cardLabel2.textColor = UIColor.whiteColor()
        addSubview(cardLabel2)
    }
   
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}