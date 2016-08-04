//
//  OrderCell.swift
//  Slice
//
//  Created by Oliver Hill on 7/23/16.
//  Copyright © 2016 Oliver Hill. All rights reserved.
//

import UIKit

class OrderCell: UITableViewCell {
    var order: PastOrder!
    let months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    
    let topLabelY:CGFloat = 12
    let midLabelY:CGFloat = 42
    let bottomLabelY: CGFloat = 72
    let labelHeight:CGFloat = 25
    
    var maxX: CGFloat = 14
    
    override func layoutSubviews() {
        super.layoutSubviews()
        for subview in self.subviews{
            if subview is UIImageView || subview is UILabel{
                subview.removeFromSuperview()
            }
        }
        backgroundColor = Constants.darkBlue
        addSlices()
        addAddress()
        addPrice()
        addRightSideLabels()
    }
    
    //MARK: Left Side
    func addSlices(){
        if order.pepperoniSlices != 0{
            for pepp in 0...order.pepperoniSlices-1{
                let imageView = UIImageView(frame: CGRect(x: CGFloat(15 + pepp*28), y: topLabelY, width: labelHeight, height: labelHeight))
                imageView.image = UIImage(imageLiteral: "tinyPepperoni")
                maxX = imageView.frame.maxX
                addSubview(imageView)
                
            }
        }
        if order.cheeseSlices != 0{
            for cheese in 0...order.cheeseSlices-1{
                let imageView = UIImageView(frame: CGRect(x: (maxX+3) + CGFloat(cheese*28), y: topLabelY, width: labelHeight, height: labelHeight))
                imageView.image = UIImage(imageLiteral: "tinyCheese")
                addSubview(imageView)
            }
        }
    }
    
    func addPrice(){
        let label = UILabel(frame: CGRect(x: 20, y: midLabelY, width: frame.width*3/5, height: labelHeight))
        label.attributedText = getAttributedText("$\(order.price)", size: 14, kern: 5.0, color: UIColor.whiteColor())
        addSubview(label)
    }
    
    
    func addAddress(){
        let label = UILabel(frame: CGRect(x: 20, y: bottomLabelY, width: frame.width*3/5, height: labelHeight))
        label.attributedText = getAttributedText(order.address.getName(), size: 14, kern: 5.0, color: UIColor.whiteColor())
        addSubview(label)
    }
    
    
    //MARK: Right Side
    func addRightSideLabels(){
        let dateLabel = UILabel(frame: CGRect(x: maxX, y: topLabelY, width: frame.width - (maxX+5), height: labelHeight))
        dateLabel.textAlignment = .Right
        let components = NSCalendar.currentCalendar().components([.Day , .Month , .Year, .Hour, .Minute], fromDate: order.timeOrdered)
        let dateString = "\(months[components.month-1]) \(components.day), \(components.year)"
        dateLabel.attributedText = getAttributedText(dateString, size: 14, kern: 3.0, color: UIColor.whiteColor())
        addSubview(dateLabel)
        
        let timeLabel = UILabel(frame: CGRect(x: maxX, y: midLabelY, width: frame.width - (maxX+5), height: labelHeight))
        timeLabel.textAlignment = .Right
        
        let formatter = NSDateFormatter()
        formatter.dateFormat = "h:mm a"
        let timeString = formatter.stringFromDate(order.timeOrdered)
        timeLabel.attributedText = getAttributedText(timeString, size: 14, kern: 3.0, color: UIColor.whiteColor())
        addSubview(timeLabel)
        
        let payLabel = UILabel(frame: CGRect(x: maxX, y: bottomLabelY, width: frame.width - (maxX+5), height: labelHeight))
        payLabel.textAlignment = .Right
        
        var payString = ""
        if payString != ""{
            payString = order.paymentMethod == "applePay" ? "Pay" : "\u{2022}\u{2022}\u{2022}\u{2022} \(order.paymentMethod)"
        }
        payLabel.attributedText = getAttributedText(payString, size: 14, kern: 3.0, color: UIColor.whiteColor())
        addSubview(payLabel)
    }
    
    func getAttributedText(text:String, size: CGFloat, kern: Double, color: UIColor)->NSMutableAttributedString{
        let attributedString = NSMutableAttributedString(string: text)
        attributedString.addAttribute(NSForegroundColorAttributeName, value: color, range: (attributedString.string as NSString).rangeOfString(text))
        attributedString.addAttribute(NSKernAttributeName, value: CGFloat(kern), range: (attributedString.string as NSString).rangeOfString(text))
        attributedString.addAttribute(NSFontAttributeName, value: UIFont(name: "Myriad Pro", size: size)!, range: (attributedString.string as NSString).rangeOfString(text))
        return attributedString
    }

}
