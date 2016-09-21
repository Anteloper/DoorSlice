//
//  RatingController.swift
//  Slice
//
//  Created by Oliver Hill on 7/31/16.
//  Copyright © 2016 Oliver Hill. All rights reserved.
//

import UIKit

//Alert specifically for prompting the user for their rating and comment if applicable
class RatingController: UIViewController, UITextViewDelegate {
    
    var contentView = UIView()
    var strongSelf: RatingController?
    var titleLabel = UILabel()
    var button = UIButton()
    var ratingControl = RatingControl()
    var textField = UITextView()
    var okayButton = UIButton()
    var delegate: Rateable!
    var keyboardIsRaised = false
    
    init(){ 
        super.init(nibName: nil, bundle: nil)
        let window: UIWindow = UIApplication.shared.keyWindow!
        window.addSubview(view)
        window.bringSubview(toFront: view)

        view.frame = window.bounds
        view.frame = UIScreen.main.bounds
        view.autoresizingMask = [UIViewAutoresizing.flexibleHeight, UIViewAutoresizing.flexibleWidth]
        view.backgroundColor = UIColor(red:0, green:0, blue:0, alpha:0.3)
        
        strongSelf = self
        setupContentView()
        addTitleView()
        addRatingControl()
        addTextField()
        addOkayButton()
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    func setupContentView(){
        contentView.frame = CGRect(x: view.frame.width/2-150, y: view.frame.height/2-150, width: 300, height: 300)
        contentView.backgroundColor = Constants.darkBlue
        contentView.layer.cornerRadius = 5.0
        contentView.layer.masksToBounds = true
        contentView.addSubview(titleLabel)
        contentView.layer.borderColor = UIColor.white.cgColor
        contentView.layer.borderWidth = 1.0
        view.addSubview(contentView)
    }
    
    func addTitleView(){
        titleLabel.attributedText = Constants.getTitleAttributedString("HOW WAS YOUR SLICE", size: 18, kern: 5.0)
        titleLabel.textAlignment = .center
        titleLabel.frame = CGRect(x:0, y:0, width: 300, height: 60)
        contentView.addSubview(titleLabel)
        
        let line = CALayer()
        line.frame = CGRect(x: 0, y: 50, width: 300, height: 1)
        line.backgroundColor = UIColor.white.cgColor
        line.opacity = 0.5
        contentView.layer.addSublayer(line)
    }
    
    func addRatingControl(){
        ratingControl = RatingControl(frame: CGRect(x:15, y:60, width: 300, height: 100))
        contentView.addSubview(ratingControl)
    }
    
    func addTextField(){
        textField.frame = CGRect(x: 15, y: 160, width: 270, height: 70)
        textField.font = UIFont(name: "Myriad Pro", size: 18)
        textField.textColor = Constants.darkBlue
        textField.backgroundColor = UIColor.white
        textField.textAlignment = .center
        textField.layer.cornerRadius = 5
        textField.clipsToBounds = true
        textField.layer.borderColor = UIColor(white: 0.8, alpha: 0.0).cgColor
        textField.layer.borderWidth = 1.0
        textField.delegate = self
        contentView.addSubview(textField)
        
        let lineLeft = CALayer()
        lineLeft.frame = CGRect(x: 0, y: 145, width: 95, height: 1)
        lineLeft.opacity = 0.5
        lineLeft.backgroundColor = UIColor.white.cgColor
        contentView.layer.addSublayer(lineLeft)
        
        let label = UILabel(frame: CGRect(x: 100, y: 130, width: 100, height: 30))
        label.attributedText = Constants.getTitleAttributedString("COMMENTS", size: 10, kern: 6.0)
        label.textAlignment = .center
        contentView.addSubview(label)
        
        let lineRight = CALayer()
        lineRight.frame = CGRect(x: 205, y: 145, width: 95, height: 1)
        lineRight.opacity = 0.5
        lineRight.backgroundColor = UIColor.white.cgColor
        contentView.layer.addSublayer(lineRight)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func keyboardWillShow(){
        if !keyboardIsRaised{
            UIView.animate(withDuration: 0.5, animations: { self.contentView.frame.origin.y -= 100 })
            keyboardIsRaised = true
        }
    }
    
    func keyboardWillHide(){
        if keyboardIsRaised{
            UIView.animate(withDuration: 0.5, animations: {self.contentView.frame.origin.y += 100})
            keyboardIsRaised = false
        }
    }

    func addOkayButton(){
        okayButton.frame = CGRect(x: -5, y: 255, width: 320, height: 40)
        let attString = Constants.getTitleAttributedString("SUBMIT", size: 18, kern: 6.0)
        //attString.addAttribute(NSForegroundColorAttributeName, value: Constants.darkBlue.CGColor, range: (attString.string as NSString).rangeOfString("SUBMIT"))
        okayButton.addTarget(self, action: #selector(okayPressed), for: .touchUpInside)
        okayButton.setAttributedTitle(attString, for: UIControlState())
        
        let line = UIView()
        line.backgroundColor = UIColor.white
        line.alpha = 0.6
        line.frame = CGRect(x: 0, y: 245, width: 300, height: 1)
        contentView.addSubview(okayButton)
        contentView.addSubview(line)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        textField.resignFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    
    func showAlert(){
        view.alpha = 0;
        UIView.animate(withDuration: 0.1, animations: { () -> Void in
            self.view.alpha = 1.0;
        })
        let previousTransform = self.contentView.transform
        self.contentView.layer.transform = CATransform3DMakeScale(0.9, 0.9, 0.0)
        UIView.animate(withDuration: 0.2, animations: { () -> Void in
            self.contentView.layer.transform = CATransform3DMakeScale(1.1, 1.1, 0.0)
        }, completion: { (Bool) -> Void in
            UIView.animate(withDuration: 0.1, animations: { () -> Void in
                self.contentView.layer.transform = CATransform3DMakeScale(0.9, 0.9, 0.0)
            }, completion: { (Bool) -> Void in
                UIView.animate(withDuration: 0.1, animations: { () -> Void in
                    self.contentView.layer.transform = CATransform3DMakeScale(1.0, 1.0, 0.0)
                }, completion: { (Bool) -> Void in
                    self.contentView.transform = previousTransform
                }) 
            }) 
        }) 
    }
    
    func okayPressed(){

        let stars = ratingControl.rating
        if stars == 0{
            ratingControl.invalidRating()
        }
        else{
            if textField.isFirstResponder { textField.resignFirstResponder() }
            delegate.dismissed(withRating: stars, comment: textField.text == "" ? nil : textField.text)
            UIView.animate(withDuration: 0.3,
                                   delay: 0.0,
                                   options: UIViewAnimationOptions.curveEaseOut,
                                   animations: { self.view.alpha = 0.0}, completion: { _ in
                                    self.view.removeFromSuperview()
                                    self.contentView.removeFromSuperview()
                                    self.contentView = UIView()
                                    }
            )
            self.strongSelf = nil //Releasing strong refrence of itself.
        }
    }
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        UIView.animate(withDuration: 0.5, animations: {})
        return true
    }
}





class RatingControl: UIView {
    var rating = 0 {
        didSet {
            setNeedsLayout()
        }
    }
    var ratingButtons = [UIButton]()
    var spacing = 5
    var stars = 5
    
    // MARK: Initialization
    required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder) }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let filledStarImage = UIImage(named: "starFilled")
        let emptyStarImage = UIImage(named: "starEmpty")
        
        for _ in 0..<5 {
            let button = UIButton()
            
            button.setImage(emptyStarImage, for: UIControlState())
            button.setImage(filledStarImage, for: .selected)
            button.setImage(filledStarImage, for: [.highlighted, .selected])
            button.adjustsImageWhenHighlighted = true
            
            button.addTarget(self, action: #selector(RatingControl.ratingButtonTapped(_:)), for: .touchDown)
            ratingButtons += [button]
            button.layer.minificationFilter = kCAFilterTrilinear
            addSubview(button)
        }
    }
    
    override func layoutSubviews() {
        // Set the button's width and height to a square the size of the frame's height.
        let buttonSize = Int(300/6)
        var buttonFrame = CGRect(x: 0, y: 4, width: buttonSize, height: buttonSize)
        
        // Offset each button's origin by the length of the button plus spacing.
        for (index, button) in ratingButtons.enumerated() {
            buttonFrame.origin.x = CGFloat(index * (buttonSize + spacing))
            button.frame = buttonFrame
        }
        updateButtonSelectionStates()
    }
    
    override var intrinsicContentSize : CGSize {
        let buttonSize = Int(frame.size.height)
        let width = (buttonSize + spacing) * stars
        return CGSize(width: width, height: buttonSize)
    }
    
    // MARK: Button Action
    func ratingButtonTapped(_ button: UIButton) {
        rating = ratingButtons.index(of: button)! + 1
        updateButtonSelectionStates()
    }
    
    func updateButtonSelectionStates() {
        for (index, button) in ratingButtons.enumerated() {
            // If the index of a button is less than the rating, that button should be selected.
            button.isSelected = index < rating
        }
    }
    
    func invalidRating(){
        for button in ratingButtons{
            Alerts.shakeView(button, enterTrue: true)
        }
    }
}
