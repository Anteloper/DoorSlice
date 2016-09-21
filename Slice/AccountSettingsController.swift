//
//  AccountSettingsController.swift
//  Slice
//
//  Created by Oliver Hill on 8/10/16.
//  Copyright © 2016 Oliver Hill. All rights reserved.
//

import UIKit


enum CellType{
    case receiptCell
    case emailCell
    case confirmCell
}

//Controller for editing account settings. Built as a tableView to allow expanding and collapsing of the email text field
//based on whether the wants receipts switch is toggled on or off

class AccountSettingsController: NavBarred, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate{
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
        DispatchQueue.main.async{
            self.actionForBackButton({self.save()})
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
        data.append(.receiptCell)
        let firstLoadConditional = isFirstLoad && (user.email != nil && user.wantsReceipts)
        let otherwiseConditional = !isFirstLoad && wantsReceipts
        if firstLoadConditional || otherwiseConditional{
                data.append(.emailCell)
        }
        data.append(.confirmCell)
        isFirstLoad = false
        return data
    }
    
    //MARK: Save and Exit
    //This function saves and exits if appropriate
    func save(){
        var shouldExit = true
        user.wantsOrderConfirmation = shouldConfirmOrderSwitch.isOn
        
        var valid = false
        if emailField != nil{
            valid = isValidEmail(emailField.text!)
            emailField.layer.borderColor = UIColor.white.cgColor
        }
        
        //All bases covered. I built a damn logic table
        if (!wantsReceipts && user.email != nil) || (wantsReceiptSwitch.isOn && valid){
            if emailField == nil{
                user.email = nil
            }
            else{
                user.email = emailField.text ?? nil
            }
            user.wantsReceipts = wantsReceiptSwitch.isOn
        }
        
        else if (wantsReceipts && user.email != nil) || (!wantsReceiptSwitch.isOn && user.email == nil){
            user.wantsReceipts = wantsReceiptSwitch.isOn
        }
        
        else if (wantsReceiptSwitch.isOn && user.email == nil) && !valid{
            emailField.layer.borderColor = Constants.lightRed.cgColor
            Alerts.shakeView(emailField, enterTrue: true)
            fakeOnSwitch = true
            shouldExit = false
        }

        saveButton.transform = CGAffineTransform(scaleX: 0, y: 0)
        UIView.animate(withDuration: 0.6, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 15, options: .curveLinear, animations: { self.saveButton.transform = CGAffineTransform.identity}, completion: nil)
        if shouldExit{
            self.delegate.returnFromSettings()
        }
    
    }

    //MARK: TableView Delegate Functions
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellData.count
    }
    
    //Cell for row
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch cellData[(indexPath as NSIndexPath).row]{
        case .receiptCell:
            return receiptCell()
        case .emailCell:
            return emailCell()
        case .confirmCell:
            return confirmOrderCell()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return rowHeight
    }
    
    //MARK: USwitch Handler
    func wantsReceiptsChanged(_ sender: UISwitch){
        if wantsReceiptSwitch.isOn{
            wantsReceipts = true
            if cellData.count != 3{
                cellData = getCellData()
                tableView.insertRows(at: [IndexPath(row: 1, section: 0)], with: .automatic)
                animateExplainLabel()
            }
        }
        else if !wantsReceiptSwitch.isOn{
            wantsReceipts = false
            cellData = getCellData()
            tableView.deleteRows(at: [IndexPath(row: 1, section: 0)], with: .automatic)
            animateExplainLabel()
        }
    }
    
    //MARK: TextField Delegate Functions
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if isValidEmail(emailField.text!){
            emailField.layer.borderColor = Constants.seaFoam.cgColor
            return true
        }
        else{
            emailField.layer.borderColor = Constants.lightRed.cgColor
            Alerts.shakeView(emailField, enterTrue: true)
            return false
        }
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        emailField.text = ""
        emailField.font = UIFont(name: "Myriad Pro", size: 14)
        emailField.textColor = UIColor.white
        return true
    }

    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if emailField != nil{
            emailField.resignFirstResponder()
        }
    }
    
    
    //MARK: Setup Functions
    func tableViewSetup(){
        tableView = UITableView(frame: CGRect(x: 0, y: 70, width: view.frame.width, height: rowHeight*3))
        self.automaticallyAdjustsScrollViewInsets = false
        tableView.backgroundColor = Constants.darkBlue
        tableView.isScrollEnabled = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SettingCell")
        tableView.showsVerticalScrollIndicator = false
        tableView.allowsSelection = false
        view.addSubview(tableView)
        
    }
    
    func addSaveButton(){
        saveButton = UIButton(frame: CGRect(x: view.frame.midX-60, y: view.frame.height*3/4, width: 120, height: 40))
        let cat = Constants.getTitleAttributedString("SAVE", size: 20, kern: 10.0)
        cat.addAttribute(NSForegroundColorAttributeName, value: Constants.seaFoam, range: (cat.string as NSString).range(of: "SAVE"))
        saveButton.setAttributedTitle(cat, for: UIControlState())
        saveButton.addTarget(self, action: #selector(save), for: .touchUpInside)
        view.addSubview(saveButton)
    }
    
    
    //MARK: Cell Setup Functions
    func receiptCell()->UITableViewCell{
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell") as UITableViewCell!
        for sub in (cell?.contentView.subviews)!{
            sub.removeFromSuperview()
        }
        cell?.backgroundColor = Constants.darkBlue
        cell?.contentView.addSubview(setupLeftImage("receipt"))
        wantsReceiptSwitch = getRightSwitch()
        wantsReceiptSwitch.isOn = (user.wantsReceipts || (fakeOnSwitch != nil && fakeOnSwitch!)) && cellData.count != 2
        wantsReceiptSwitch.addTarget(self, action: #selector(wantsReceiptsChanged(_:)), for: .valueChanged)
        cell?.accessoryView = (wantsReceiptSwitch)
        cell?.contentView.addSubview(getCenterLabel("RECEIPTS"))
        return cell!
        
    }
    
    func emailCell()->UITableViewCell{
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell") as UITableViewCell!
        for sub in (cell?.contentView.subviews)!{
            sub.removeFromSuperview()
        }
        cell?.backgroundColor = Constants.darkBlue
        cell?.contentView.addSubview(setupLeftImage("@"))
        emailField = UITextField(frame: CGRect(x: 60, y: rowHeight/2-20, width: view.frame.width-70, height: 40))
        emailField.delegate = self
        emailField.layer.cornerRadius = 5
        if fakeOnSwitch != nil && fakeOnSwitch!{
            emailField.layer.borderColor = Constants.lightRed.cgColor
        }
        else{
            emailField.layer.borderColor = UIColor.white.cgColor
        }
        emailField.layer.borderWidth = 1.0
        emailField.clipsToBounds = true
        if user.email == nil{
            emailField.attributedText = Constants.getTitleAttributedString(" EMAIL ADDRESS", size: 14, kern: 3.0)
        }
        else{
            emailField.text = user.email!
            emailField.font = UIFont(name: "Myriad Pro", size: 14)
            emailField.textColor = UIColor.white
        }
        emailField.keyboardType = .emailAddress
        emailField.autocorrectionType = .no
        emailField.autocapitalizationType = .none
        cell?.contentView.addSubview(emailField)
        return cell!
    }
    
    func confirmOrderCell()->UITableViewCell{
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell") as UITableViewCell!
        for sub in (cell?.contentView.subviews)!{
            sub.removeFromSuperview()
        }
        cell?.backgroundColor = Constants.darkBlue
        cell?.contentView.addSubview(setupLeftImage("confirm"))
        cell?.contentView.addSubview(getCenterLabel("ORDER CONFIRMATION"))
        shouldConfirmOrderSwitch = getRightSwitch()
        shouldConfirmOrderSwitch.isOn = user.wantsOrderConfirmation
        cell?.contentView.addSubview(shouldConfirmOrderSwitch)
        return cell!
    }

    func setupLeftImage(_ name: String) -> UIImageView{
        let imageView = UIImageView(frame: CGRect(x: 12, y: rowHeight/2-20, width: 40, height: 40))
        imageView.image = UIImage(imageLiteralResourceName: name)
        imageView.layer.cornerRadius = imageView.frame.width/2
        imageView.clipsToBounds = true
        imageView.layer.borderColor = Constants.seaFoam.cgColor
        imageView.layer.borderWidth = 1.0
        imageView.layer.minificationFilter = kCAFilterTrilinear
        return imageView
    }
    
    func getRightSwitch()->UISwitch{
        let toggle = UISwitch(frame: CGRect(x:view.frame.width-60, y: rowHeight/2-20, width: 40, height: 40))
        toggle.onTintColor = Constants.seaFoam
        return toggle
    }
    
    func getCenterLabel(_ text: String)->UILabel{
        let label = UILabel(frame: CGRect(x: 60, y: rowHeight/2 - 20, width: view.frame.width-120, height: 40))
        label.attributedText = Constants.getTitleAttributedString(text, size: 14, kern: 3.0)
        label.textAlignment = .left
        return label
    }
    
    func addExplainLabel(){
        explainLabel = UILabel(frame: CGRect(x: 15, y: tableView.frame.origin.y + rowHeight*CGFloat(cellData.count) + 3, width: view.frame.width-30, height: 30))
        explainLabel.numberOfLines = 0
        explainLabel.font = UIFont(name: "Myriad Pro", size: 12)
        explainLabel.text = "When turned on, we'll double check that you really meant to order when the timer runs out"
        explainLabel.textColor = UIColor.white
        view.addSubview(explainLabel)
    }
    
    func coverUp(){
        let line = CALayer()
        line.frame = CGRect(x: 0, y: tableView.frame.maxY-2, width: view.frame.width, height: 5)
        line.backgroundColor = Constants.darkBlue.cgColor
        view.layer.addSublayer(line)
    }
    
    func animateExplainLabel(){
        UIView.animate(withDuration: 0.3, animations: {
            self.explainLabel.frame.origin.y = self.tableView.frame.origin.y + self.rowHeight * CGFloat(self.cellData.count) + 3
        })
    }

    func isValidEmail(_ testStr:String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: testStr)
    }
}
