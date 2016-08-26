//
//  AccountSettingsController.swift
//  Slice
//
//  Created by Oliver Hill on 8/10/16.
//  Copyright © 2016 Oliver Hill. All rights reserved.
//

import UIKit


enum CellType{
    case ReceiptCell
    case EmailCell
    case ConfirmCell
}

//Controller for editing account settings. Built as a tableView to allow expanding and collapsing of the email text field
//based on whether the wants receipts switch is toggled on or off

class AccountSettingsController: UIViewController, UIGestureRecognizerDelegate, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate{
    
    var delegate: Slideable!
    var user: User!
    
    var wantsReceiptSwitch: UISwitch!
    var shouldConfirmOrderSwitch: UISwitch!
    var tableView: UITableView!
    var emailField: UITextField!
    var saveButton: UIButton!
    var explainLabel: UILabel!
    var cellData = [CellType]()
    var isFirstLoad = true
    let acceptableCharacters = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"

     //True when a user has tried to save their preference towards receving a receipt without providing an email. Important for logic in save  function
    var fakeOnSwitch: Bool?
   
    var wantsReceipts = false//NOT the same as user.wantsReceipts. Can be true even if there is no email address. It is for local use only
    let rowHeight: CGFloat = 90
    
    //MARK: Lifecycle Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        dispatch_async(dispatch_get_main_queue()){
            self.view.backgroundColor = Constants.darkBlue
            self.navBarSetup()
            let swipe = UIPanGestureRecognizer()
            swipe.addTarget(self, action: #selector(self.didSwipe(_:)))
            self.view.addGestureRecognizer(swipe)
            self.wantsReceipts = self.user.wantsReceipts
            self.cellData = self.getCellData()
            self.addSaveButton()
            self.tableViewSetup()
            self.addExplainLabel()
            self.coverUp()
        }
    }

    //MARK: Data Management
    func getCellData() -> [CellType]{
        var data = [CellType]()
        data.append(.ReceiptCell)
        let firstLoadConditional = isFirstLoad && (user.email != nil && user.wantsReceipts)
        let otherwiseConditional = !isFirstLoad && wantsReceipts
        if firstLoadConditional || otherwiseConditional{
                data.append(.EmailCell)
        }
        data.append(.ConfirmCell)
        isFirstLoad = false
        return data
    }
    
    //MARK: Save and Exit
    //This function saves and exits if appropriate
    func save(sender: AnyObject){
        var shouldExit = true
        user.wantsOrderConfirmation = shouldConfirmOrderSwitch.on
        
        var valid = false
        if emailField != nil{
            valid = isValidEmail(emailField.text!)
            emailField.layer.borderColor = UIColor.whiteColor().CGColor
        }
        
        //All bases covered. I built a damn logic table
        if (!wantsReceipts && user.email != nil) || (wantsReceiptSwitch.on && valid){
            if emailField == nil{
                user.email = nil
            }
            else{
                user.email = emailField.text ?? nil
            }
            user.wantsReceipts = wantsReceiptSwitch.on
        }
        
        else if (wantsReceipts && user.email != nil) || (!wantsReceiptSwitch.on && user.email == nil){
            user.wantsReceipts = wantsReceiptSwitch.on
        }
        
        else if (wantsReceiptSwitch.on && user.email == nil) && !valid{
            emailField.layer.borderColor = Constants.lightRed.CGColor
            shakeTextField(emailField, enterTrue: true)
            fakeOnSwitch = true
            shouldExit = false
            
        }

        saveButton.transform = CGAffineTransformMakeScale(0, 0)
        UIView.animateWithDuration(0.6, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 15, options: .CurveLinear, animations: { self.saveButton.transform = CGAffineTransformIdentity}, completion: nil)
        if shouldExit{
            self.delegate.returnFromFullscreen(withCard: nil, orAddress: nil, fromSettings: true)
        }
    
    }

    //MARK: TableView Delegate Functions
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellData.count
    }
    
    //Cell for row
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        switch cellData[indexPath.row]{
        case .ReceiptCell:
            return receiptCell()
        case .EmailCell:
            return emailCell()
        case .ConfirmCell:
            return confirmOrderCell()
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return rowHeight
    }
    
    //MARK: USwitch Handler
    func wantsReceiptsChanged(sender: UISwitch){
        if wantsReceiptSwitch.on{
            wantsReceipts = true
            if cellData.count != 3{
                cellData = getCellData()
                tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: 1, inSection: 0)], withRowAnimation: .Automatic)
                animateExplainLabel()
            }
        }
        else if !wantsReceiptSwitch.on{
            wantsReceipts = false
            cellData = getCellData()
            tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: 1, inSection: 0)], withRowAnimation: .Automatic)
            animateExplainLabel()
        }

    }
    
    //MARK: TextField Delegate Functions
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if isValidEmail(emailField.text!){
            emailField.layer.borderColor = Constants.seaFoam.CGColor
            return true
        }
        else{
            emailField.layer.borderColor = Constants.lightRed.CGColor
            shakeTextField(emailField, enterTrue: true)
            return false
        }
    }
    
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        emailField.text = ""
        emailField.font = UIFont(name: "Myriad Pro", size: 14)
        emailField.textColor = UIColor.whiteColor()
        return true
    }

    
    //MARK: Touch Handling
    func didSwipe(recognizer: UIPanGestureRecognizer){
        if recognizer.state == .Ended{
            let point = recognizer.translationInView(view)
            if(abs(point.x) >= abs(point.y)){
                if point.x > 20{
                    let sender = UIView()
                    sender.tag = 2
                    save(sender)
                }
            }
        }
    }
    
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if emailField != nil{
            emailField.resignFirstResponder()
        }
    }
    
    
    //MARK: Setup Functions
    func tableViewSetup(){
        tableView = UITableView(frame: CGRect(x: 0, y: 70, width: view.frame.width, height: rowHeight*3))
        self.automaticallyAdjustsScrollViewInsets = false
        tableView.backgroundColor = Constants.darkBlue
        tableView.scrollEnabled = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "SettingCell")
        tableView.showsVerticalScrollIndicator = false
        tableView.allowsSelection = false
        view.addSubview(tableView)
        
    }
    
    func navBarSetup(){
        navigationController?.navigationBar.barTintColor = Constants.darkBlue
        let titleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 44))
        titleLabel.attributedText = Constants.getTitleAttributedString("DOORSLICE", size: 16, kern: 6.0)
        titleLabel.textAlignment = .Center
        navigationItem.titleView = titleLabel
        
        let backButton = UIButton(type: .Custom)
        backButton.tag = 2
        backButton.setImage(UIImage(imageLiteral: "back"), forState: .Normal)
        backButton.addTarget(self, action: #selector(save(_:)), forControlEvents: .TouchUpInside)
        backButton.frame = CGRect(x: -40, y: -4, width: 20, height: 20)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
    }
    
    
    func addSaveButton(){
        saveButton = UIButton(frame: CGRect(x: view.frame.midX-60, y: view.frame.height*3/4, width: 120, height: 40))
        let cat = Constants.getTitleAttributedString("SAVE", size: 20, kern: 10.0)
        cat.addAttribute(NSForegroundColorAttributeName, value: Constants.seaFoam, range: (cat.string as NSString).rangeOfString("SAVE"))
        saveButton.setAttributedTitle(cat, forState: .Normal)
        saveButton.addTarget(self, action: #selector(save), forControlEvents: .TouchUpInside)
        view.addSubview(saveButton)
    }
    
    
    //MARK: Cell Setup Functions
    func receiptCell()->UITableViewCell{
        let cell = tableView.dequeueReusableCellWithIdentifier("SettingCell") as UITableViewCell!
        for sub in cell.contentView.subviews{
            sub.removeFromSuperview()
        }
        cell.backgroundColor = Constants.darkBlue
        cell.contentView.addSubview(setupLeftImage("receipt"))
        wantsReceiptSwitch = getRightSwitch()
        wantsReceiptSwitch.on = (user.wantsReceipts || (fakeOnSwitch != nil && fakeOnSwitch!)) && cellData.count != 2
        wantsReceiptSwitch.addTarget(self, action: #selector(wantsReceiptsChanged(_:)), forControlEvents: .ValueChanged)
        cell.accessoryView = (wantsReceiptSwitch)
        cell.contentView.addSubview(getCenterLabel("RECEIPTS"))
        return cell
        
    }
    
    func emailCell()->UITableViewCell{
        let cell = tableView.dequeueReusableCellWithIdentifier("SettingCell") as UITableViewCell!
        for sub in cell.contentView.subviews{
            sub.removeFromSuperview()
        }
        cell.backgroundColor = Constants.darkBlue
        cell.contentView.addSubview(setupLeftImage("@"))
        emailField = UITextField(frame: CGRect(x: 60, y: rowHeight/2-20, width: view.frame.width-70, height: 40))
        emailField.delegate = self
        emailField.layer.cornerRadius = 5
        if fakeOnSwitch != nil && fakeOnSwitch!{
            emailField.layer.borderColor = Constants.lightRed.CGColor
        }
        else{
            emailField.layer.borderColor = UIColor.whiteColor().CGColor
        }
        emailField.layer.borderWidth = 1.0
        emailField.clipsToBounds = true
        if user.email == nil{
            emailField.attributedText = Constants.getTitleAttributedString(" EMAIL ADDRESS", size: 14, kern: 3.0)
        }
        else{
            emailField.text = user.email!
            emailField.font = UIFont(name: "Myriad Pro", size: 14)
            emailField.textColor = UIColor.whiteColor()
        }
        emailField.keyboardType = .EmailAddress
        emailField.autocorrectionType = .No
        emailField.autocapitalizationType = .None
        cell.contentView.addSubview(emailField)
        return cell
    }
    
    func confirmOrderCell()->UITableViewCell{
        let cell = tableView.dequeueReusableCellWithIdentifier("SettingCell") as UITableViewCell!
        for sub in cell.contentView.subviews{
            sub.removeFromSuperview()
        }
        cell.backgroundColor = Constants.darkBlue
        cell.contentView.addSubview(setupLeftImage("confirm"))
        cell.contentView.addSubview(getCenterLabel("ORDER CONFIRMATION"))
        shouldConfirmOrderSwitch = getRightSwitch()
        shouldConfirmOrderSwitch.on = user.wantsOrderConfirmation
        cell.contentView.addSubview(shouldConfirmOrderSwitch)
        return cell
    }

    func setupLeftImage(name: String) -> UIImageView{
        let imageView = UIImageView(frame: CGRect(x: 12, y: rowHeight/2-20, width: 40, height: 40))
        imageView.image = UIImage(imageLiteral: name)
        imageView.layer.cornerRadius = imageView.frame.width/2
        imageView.clipsToBounds = true
        imageView.layer.borderColor = Constants.seaFoam.CGColor
        imageView.layer.borderWidth = 1.0
        imageView.layer.minificationFilter = kCAFilterTrilinear
        return imageView
    }
    
    func getRightSwitch()->UISwitch{
        let toggle = UISwitch(frame: CGRect(x:view.frame.width-60, y: rowHeight/2-20, width: 40, height: 40))
        toggle.onTintColor = Constants.seaFoam
        return toggle
    }
    
    func getCenterLabel(text: String)->UILabel{
        let label = UILabel(frame: CGRect(x: 60, y: rowHeight/2 - 20, width: view.frame.width-120, height: 40))
        label.attributedText = Constants.getTitleAttributedString(text, size: 14, kern: 3.0)
        label.textAlignment = .Left
        return label
    }
    
    func addExplainLabel(){
        explainLabel = UILabel(frame: CGRect(x: 15, y: tableView.frame.origin.y + rowHeight*CGFloat(cellData.count) + 3, width: view.frame.width-30, height: 30))
        explainLabel.numberOfLines = 0
        explainLabel.font = UIFont(name: "Myriad Pro", size: 12)
        explainLabel.text = "When turned on, we'll double check that you really meant to order when the timer runs out"
        explainLabel.textColor = UIColor.whiteColor()
        view.addSubview(explainLabel)
    }
    
    func coverUp(){
        let line = CALayer()
        line.frame = CGRect(x: 0, y: tableView.frame.maxY-2, width: view.frame.width, height: 5)
        line.backgroundColor = Constants.darkBlue.CGColor
        view.layer.addSublayer(line)
    }
    
    func animateExplainLabel(){
        
        UIView.animateWithDuration(0.3, animations: {
            self.explainLabel.frame.origin.y = self.tableView.frame.origin.y + self.rowHeight * CGFloat(self.cellData.count) + 3
            //blocker.alpha = 1.0
        })
       
    }

    
    func isValidEmail(testStr:String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluateWithObject(testStr)
    }
    
    //MARK: Animation
    func shakeTextField(textField: UITextField, enterTrue: Bool){
        UIView.animateWithDuration(0.1, animations: {
            textField.frame.origin.x += 3
            }, completion:{ _ in UIView.animateWithDuration(0.1, animations: {
                textField.frame.origin.x -= 3
                }, completion: { _ in
                    UIView.animateWithDuration(0.1, animations: {
                        textField.frame.origin.x += 3
                        }, completion: { _ in
                            UIView.animateWithDuration(0.1, animations: {
                                textField.frame.origin.x -= 3
                                }, completion: { _ in
                                    if enterTrue{
                                        self.shakeTextField(textField, enterTrue: false)
                                    }
                                })
                            }
                        )
                    }
                )
            }
        )
    }
}
