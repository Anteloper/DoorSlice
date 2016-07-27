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
    var maxX: CGFloat = 14
    
    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundColor = Constants.darkBlue
        addSlices()
        addAddress()
        addTimeOrdered()
    }
    
    func addSlices(){
        if order.pepperoniSlices != 0{
            for pepp in 0...order.pepperoniSlices-1{
                let imageView = UIImageView(frame: CGRect(x: 15 + pepp*28, y: 12, width: 25, height: 25))
                imageView.image = UIImage(imageLiteral: "tinyPepperoni")
                maxX = imageView.frame.maxX
                addSubview(imageView)
                
            }
        }
        if order.cheeseSlices != 0{
            for cheese in 0...order.cheeseSlices-1{
                let imageView = UIImageView(frame: CGRect(x: Int(maxX+3) + cheese*28, y: 12, width: 25, height: 25))
                imageView.image = UIImage(imageLiteral: "tinyCheese")
                addSubview(imageView)
            }
        }
    }
    
    func addTimeOrdered(){
        let dateLabel = UILabel(frame: CGRect(x: maxX, y: 12, width: frame.width - (maxX+5), height: 25))
        dateLabel.textAlignment = .Right
        let components = NSCalendar.currentCalendar().components([.Day , .Month , .Year, .Hour, .Minute], fromDate: order.timeOrdered)
        let dateString = "\(months[components.month-1]) \(components.day), \(components.year)"
        dateLabel.attributedText = getAttributedText(dateString, size: 14, kern: 3.0, color: UIColor.whiteColor())
        addSubview(dateLabel)
        
        let timeLabel = UILabel(frame: CGRect(x: maxX, y: dateLabel.frame.maxY, width: frame.width - (maxX+5), height: 25))
        timeLabel.textAlignment = .Right
        
        let formatter = NSDateFormatter()
        formatter.dateFormat = "h:mm a"
        let timeString = formatter.stringFromDate(order.timeOrdered)
        timeLabel.attributedText = getAttributedText(timeString, size: 14, kern: 3.0, color: UIColor.whiteColor())
        addSubview(timeLabel)
        
        let payLabel = UILabel(frame: CGRect(x: maxX, y: timeLabel.frame.maxY, width: frame.width - (maxX+5), height: 25))
        payLabel.textAlignment = .Right
        let payString = order.paymentMethod == "applePay" ? "Pay" : "\u{2022}\u{2022}\u{2022}\u{2022} "+order.paymentMethod
        payLabel.attributedText = getAttributedText(payString, size: 14, kern: 3.0, color: UIColor.whiteColor())
        addSubview(payLabel)
    }
    
    
    func addAddress(){
        let label = UILabel(frame: CGRect(x: 20, y: 50, width: frame.width*3/5, height: 50))
        label.attributedText = getAttributedText(order.address.getName(), size: 14, kern: 5.0, color: UIColor.whiteColor())
        addSubview(label)
    }
    
    func getAttributedText(text:String, size: CGFloat, kern: Double, color: UIColor)->NSMutableAttributedString{
        let attributedString = NSMutableAttributedString(string: text)
        attributedString.addAttribute(NSForegroundColorAttributeName, value: color, range: (attributedString.string as NSString).rangeOfString(text))
        attributedString.addAttribute(NSKernAttributeName, value: CGFloat(kern), range: (attributedString.string as NSString).rangeOfString(text))
        attributedString.addAttribute(NSFontAttributeName, value: UIFont(name: "Myriad Pro", size: size)!, range: (attributedString.string as NSString).rangeOfString(text))
        return attributedString
    }

}
