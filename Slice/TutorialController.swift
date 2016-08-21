//
//  TutorialController.swift
//  Slice
//
//  Created by Oliver Hill on 8/11/16.
//  Copyright © 2016 Oliver Hill. All rights reserved.
//

import UIKit
import Stripe

class TutorialController: UIViewController, Configurable {
    
    var user: User!
    var addressButton = UIButton()
    var paymentButton = UIButton()
    var addresses = ActiveAddresses()
    
    var addressSpinner: CustomActivityIndicatorView?
    var cardSpinner: CustomActivityIndicatorView?
    
    var pendingCard: STPCardParams?
    var pendingAddress: Address?
    
    let startHeight:CGFloat = UIScreen.mainScreen().bounds.height <= 568.0 ? 104 : 120
    let rowHeight:CGFloat = UIScreen.mainScreen().bounds.height <= 568.0 ? 99 : 115
    let checkSize:CGFloat = 20
    var backgroundColor: UIColor = UIColor()
    
    var hasAddress = false
    var hasPayment = false
    
    let networkController = NetworkingController()
    
    //MARK: Lifecycle Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Constants.darkBlue
        UIApplication.sharedApplication().statusBarHidden = false
        UIApplication.sharedApplication().statusBarStyle = .Default
    }
    
    override func viewDidAppear(animated: Bool){
    
        let fullView = UIImageView(frame: view.frame)
        let tutImage = UIImage(imageLiteral: "tutorial")
        fullView.image = tutImage
        backgroundColor = tutImage.getPixelColor(CGPoint(x: 1, y: 1))
        
        fullView.layer.minificationFilter = kCAFilterTrilinear
        view.addSubview(fullView)
    
        
        if pendingAddress != nil {
            if user.addresses != nil{
                if !user.addressIDs.keys.contains(pendingAddress!.getName()){
                    networkController.saveAddress(pendingAddress!, userID: user.userID)
                    cardSpinner = getSpinnerWithCenter(CGPoint(x: view.frame.width-checkSize, y: startHeight + rowHeight*3/2))
                }
                else{
                    Alerts.duplicate(isCard: false)
                }
            }
        }
        
        
        if pendingCard != nil{
            let lastFour = pendingCard!.last4()!
            if !user.cards!.contains(lastFour){
                let url = (user.cardIDs.count == 0 && !user.hasCreatedFirstCard) ? Constants.firstCardURLString : Constants.newCardURLString
                networkController.saveNewCard(pendingCard!, url: url+user.userID, lastFour: lastFour)
                cardSpinner = getSpinnerWithCenter(CGPoint(x: view.frame.width-checkSize, y: startHeight + rowHeight/2))
            }
                
            else{
                Alerts.duplicate(isCard: true)
            }
        }
        
    
        addAddressButton()
        addPaymentButton()
        addSliceLabel()
        addGoButton()
        addGoLabel()
        
        for i in 1...3{
            let n: CGFloat = CGFloat(i) + CGFloat(i-1)
            let label = UILabel(frame: CGRect(x: 0, y: (startHeight + rowHeight*n/2)-10, width: view.frame.width/4, height: 20))
            label.attributedText = Constants.getTitleAttributedString("\(i).", size: 15, kern: 1.0)
            label.textAlignment = .Center
            label.alpha = 0.0
            view.addSubview(label)
            UIView.animateWithDuration(0.5, delay: 0.5 * (Double(i)-1), options: [], animations: {label.alpha = 1.0}, completion: nil)
        }
        
        checkAndAddAddressCheck()
        checkAndAddPaymentCheck()

    }
    
    //MARK: Address Views
    func addAddressButton(){
        let label = UILabel(frame: CGRect(x: 0, y: startHeight + 7, width: view.frame.width, height: 30))
        label.attributedText = Constants.getTitleAttributedString("ADD YOUR ROOM", size: 14, kern: 4.0)
        label.textAlignment = .Center
        label.alpha = 0.0
        view.addSubview(label)
        
        if user.addresses?.count == 0 || user.addresses == nil{
            addForwardButton(CGRect(x: view.frame.width-30, y: startHeight+(rowHeight/2) - 10, width: 20, height: 20))
            hasAddress = false
        }
        else{
            hasAddress = true
        }
        
        addressButton.frame = CGRect(x: 0, y: startHeight, width: view.frame.width, height: rowHeight)
        addressButton.addTarget(self, action: #selector(addressPressed), forControlEvents: .TouchUpInside)
        view.addSubview(addressButton)
        
        UIView.animateWithDuration(0.5, animations: {label.alpha = 1.0})
    }
    
    func addressPressed(){
        //TODO: Transition horizontally
        let na = NewAddressController()
        na.data = addresses.getData()
        na.user = user
        presentViewController(UINavigationController(rootViewController: na), animated: false, completion: nil)
    }
    
    
    //MARK: Payment Views
    func addPaymentButton(){
        let label = UILabel(frame: CGRect(x: 0, y: startHeight+rowHeight+7, width: view.frame.width, height: 30))
        label.attributedText = Constants.getTitleAttributedString("ADD A PAYMENT METHOD", size: 14, kern: 4.0)
        label.textAlignment = .Center
        label.alpha = 0.0
        view.addSubview(label)

        paymentButton.frame = CGRect(x: 0, y: startHeight+rowHeight, width: view.frame.width, height: rowHeight)
        paymentButton.addTarget(self, action: #selector(paymentPressed), forControlEvents: .TouchUpInside)
        view.addSubview(paymentButton)
        

        if !NetworkingController.canApplePay() && (user.cards?.count == 0 || user.cards == nil){
            addForwardButton(CGRect(x: view.frame.width-30, y: startHeight+(rowHeight*3/2) - 10, width: 20, height: 20))
            hasPayment = false
        }
        else{
            hasPayment = true
        }
        
        UIView.animateWithDuration(0.5, delay: 0.5, options: [], animations: {label.alpha = 1.0}, completion: nil)
    }

    
    func paymentPressed(){
        let nc = NewCardController()
        nc.user = user
        presentViewController(UINavigationController(rootViewController: nc), animated: false, completion: {_ in nc.paymentTextField.becomeFirstResponder()})
    }
    
    
    func getCheckView(frame: CGRect)->UIImageView{
        let checkView = UIImageView(frame: frame)
        checkView.image = UIImage(imageLiteral: "check")
        return checkView
    }
    
    
    //MARK: Slice Views
    func addSliceLabel(){
        let label = UILabel(frame: CGRect(x: 0, y: startHeight + (rowHeight*2) + 7, width: view.frame.width, height: 30))
        label.attributedText = Constants.getTitleAttributedString("TAP A SLICE TO ORDER", size: 14, kern: 4.0)
        label.textAlignment = .Center
        label.alpha = 0.0
        view.addSubview(label)
        UIView.animateWithDuration(0.5, delay: 1.0, options: [], animations: {label.alpha = 1.0}, completion: nil)
    }
    
    //MARK: Bottom Views
    func addGoLabel(){
        let label = UILabel(frame: CGRect(x: 0, y: view.frame.height*4/5-35, width: view.frame.width, height: 40))
        label.attributedText = Constants.getTitleAttributedString("WE'LL BE THERE IN FIVE", size: 20, kern: 6.0)
        label.textAlignment = .Center
        label.alpha = 0.0
        view.addSubview(label)
        UIView.animateWithDuration(0.5, delay: 1.5, options: [], animations: {label.alpha = 1.0}, completion: nil)
    }
    
    func addGoButton(){
        let goButton = UIButton(frame: CGRect(x: view.frame.midX-40, y: view.frame.height*7/8-20, width: 80, height: 80))
        goButton.addTarget(self, action: #selector(goPressed), forControlEvents: .TouchUpInside)
        view.addSubview(goButton)
    }
    
    func goPressed(){
        if pendingCard == nil  && pendingAddress == nil{
            let cc = ContainerController()
            cc.loggedInUser = user
            presentViewController(cc, animated: false, completion: nil)
        }
        else{
            var string = ""
            if pendingAddress != nil{
                string = "address"
            }
            else if pendingCard != nil{
                string = "card"
            }
            SweetAlert().showAlert("HOLD UP", subTitle: "We're still processing your \(string), give us one second", style: .None, buttonTitle: "OKAY", buttonColor: Constants.darkBlue, action: nil)
        }
        
    }
    
    func addForwardButton(frame: CGRect){
        let forward = UIImageView(frame: frame)
        forward.image = UIImage(imageLiteral: "forward")
        forward.layer.minificationFilter = kCAFilterTrilinear
        view.addSubview(forward)
    }
    
    func checkAndAddAddressCheck(){
        if hasAddress{
            let checkFrame = CGRect(x: view.frame.width - checkSize*2, y: startHeight + rowHeight/2 - checkSize/2, width: checkSize, height: checkSize)
            let addCheck = getCheckView(checkFrame)
            let coverView = UIView(frame: checkFrame)
            coverView.backgroundColor = backgroundColor
            view.addSubview(addCheck)
            view.addSubview(coverView)
            UIView.animateWithDuration(0.3, delay: 1.5, options: .CurveLinear, animations: {coverView.frame.origin.x += 25}, completion: nil)
        }
        
    }
    
    func checkAndAddPaymentCheck(){
        
        if hasPayment{
            let checkFrame = CGRect(x: view.frame.width - checkSize*2, y: startHeight + rowHeight*3/2 - checkSize/2, width: checkSize, height: checkSize)
            let addCheck = getCheckView(checkFrame)
            let coverView = UIView(frame: checkFrame)
            coverView.backgroundColor = backgroundColor
            view.addSubview(addCheck)
            view.addSubview(coverView)
            UIView.animateWithDuration(0.3, delay: 1.5, options: .CurveLinear, animations: {coverView.frame.origin.x += 25}, completion: nil)
        }
    }
    
    func getSpinnerWithCenter(center: CGPoint) -> CustomActivityIndicatorView{
        let spinner = CustomActivityIndicatorView(image: UIImage(imageLiteral: "loading-1"))
        spinner.center = center
        spinner.startAnimating()
        return spinner
    }
    
    //MARK: Configureable Delegate Functions
    func addressSaveFailed() {
    }
    
    func addressSaveSucceeded(add: Address, orderID: String) {
        checkAndAddAddressCheck()
        user.addresses!.append(add)
        user.preferredAddress = user.addresses!.count-1
        user.addressIDs[add.getName()] = orderID
        pendingAddress = nil
        checkAndAddAddressCheck()
    }
    
    func cardStoreageFailed(trueFailure trueFailure: Bool) {
    
    }
    
    func storeCardID(cardID: String, lastFour: String) {
        user.hasCreatedFirstCard = true
        user.cards!.append(lastFour)
        user.paymentMethod = .CardIndex(user.cards!.count-1)
        user.cardIDs[lastFour] = cardID
        pendingCard = nil
        checkAndAddPaymentCheck()
        
    }
    
    func unauthenticated() {
    
    }
    
}

extension UIImage {
    func getPixelColor(pos: CGPoint) -> UIColor {
        
        let pixelData = CGDataProviderCopyData(CGImageGetDataProvider(self.CGImage))
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        
        let pixelInfo: Int = ((Int(self.size.width) * Int(pos.y)) + Int(pos.x)) * 4
        
        let r = CGFloat(data[pixelInfo]) / CGFloat(255.0)
        let g = CGFloat(data[pixelInfo+1]) / CGFloat(255.0)
        let b = CGFloat(data[pixelInfo+2]) / CGFloat(255.0)
        let a = CGFloat(data[pixelInfo+3]) / CGFloat(255.0)
        
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }  
}
