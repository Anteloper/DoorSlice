//
//  MenuController.swift
//  Slice
//
//  Created by Oliver Hill on 6/9/16.
//  Copyright © 2016 Oliver Hill. All rights reserved.
//

import UIKit

//The slide out menu that appears when the user taps the menu button in the navigation bar
//The main purpose of this class is to display a menu of options to the user and alert the delegate to the users selection
class MenuController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate {
    
    var delegate: Slideable?
    var menuWidth: CGFloat?
    
    let accountStrings = ["SETTINGS", "ORDER HISTORY", "LOGOUT"]
    let accountScreens: [Int?] = [4, 3, nil]
    
    let tableView = MenuTable()
    let cellHeight: CGFloat = 80
    
    //User Info
    var addresses: [Address]!
    var cards: [String]!
    
    var preferredAddress: Int! { didSet{ tableView.reloadData() } }
    var preferredCard: Int! { didSet{ tableView.reloadData()} }
    
    var cardBeingProcessed: String?{didSet{ tableView.reloadData() }}//Will be not nil while a card is being verified by the backend
    var addressBeingProcessed: Address?{didSet{ tableView.reloadData() }}
    
    let cardBeginning = "\u{2022}\u{2022}\u{2022}\u{2022} "
    
    //MARK: ViewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Constants.darkBlue
        tableViewSetup()
    }
    
    func getCircleView(origin: CGPoint) -> PreferenceLight{
        let circleView = PreferenceLight(frame: CGRect(origin: origin, size: CGSize(width: 10, height: 10)))
        circleView.backgroundColor = Constants.tiltColor
        circleView.layer.cornerRadius = circleView.frame.height/2
        circleView.clipsToBounds = true
        return circleView
    }
    
    //MARK: TableView Setup
    func tableViewSetup(){
        tableView.frame = CGRect(x: 0,
                                 y: 64,
                                 width: menuWidth ?? view.frame.width-Constants.sliceControllerShowing,
                                 height: view.frame.size.height-64)
        tableView.backgroundView?.backgroundColor = Constants.darkBlue
        tableView.backgroundColor = Constants.darkBlue
        tableView.delegate = self
        tableView.dataSource = self
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "InfoCell")
        tableView.showsVerticalScrollIndicator = false
        tableView.allowsSelectionDuringEditing = false
        self.view.addSubview(tableView)
    }
    
    
    
    //MARK: TableView Delegate Methods
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return cellHeight
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0{
            return addressBeingProcessed == nil ? addresses.count + 1 : addresses.count + 2
        }
        else if section == 1{
            return cardBeingProcessed == nil ? cards.count + 1 : cards.count + 2
        }
        else{
            return accountStrings.count
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0{
            return "Deliver To"
        }
        else if section == 1{
            return "Pay With"
        }
        else{
            return "Account"
        }
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return cellHeight*3/4
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: cellHeight*3/4))
        headerView.backgroundColor = Constants.seaFoam
        headerView.alpha = 1.0
        
        let title = UILabel(frame: headerView.frame)
        let message = section == 2 ? "ACCOUNT" : (section == 0 ? "DELIVER TO" : "PAY WITH")
        title.attributedText =  Constants.getTitleAttributedString(message, size: 16, kern: 4.0)
        title.backgroundColor = UIColor.clearColor()
        title.textAlignment = .Center
        
        headerView.addSubview(title)
        return headerView
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0{
            if indexPath.row < addresses.count{
                return preferenceCellWithTitle((addresses[indexPath.row]).getName(), isPreferred: indexPath.row == preferredAddress)
            }
            else if indexPath.row == addresses.count && addressBeingProcessed != nil{
                return preferenceCellBeingProcessed(addressBeingProcessed!.getName())
            }
            else{
                return newCell()
            }
        }
        else if indexPath.section == 1{
            if indexPath.row < cards.count{
                return preferenceCellWithTitle(cardBeginning + cards[indexPath.row], isPreferred: indexPath.row == preferredCard)
            }
            else if indexPath.row == cards.count && cardBeingProcessed != nil {
                return preferenceCellBeingProcessed(cardBeginning + cardBeingProcessed!)
            }
            else{
                return newCell()
            }
        }
        else{
            return accountCell(accountStrings[indexPath.row], isRed: indexPath.row == accountStrings.count-1)
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0{
            if indexPath.row < addresses.count{
                preferredAddress = indexPath.row
            }
            else{
                delegate!.bringMenuToNewAddress()
            }
        }
        else if indexPath.section == 1{
            if indexPath.row < cards.count{
                preferredCard = indexPath.row
            }
            else{
                delegate!.bringMenuToNewCard()
            }
        }
        else{
            if indexPath.row == 0{
                delegate!.bringMenuToSettings()
            }
            else if indexPath.row == 1{
                delegate!.bringMenuToOrderHistory()
            }
            else if indexPath.row == 2{
                delegate!.logoutConfirmation()
            }
        }
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if indexPath.section == 0{
            if indexPath.row < addresses.count || (indexPath.row == addresses.count && addressBeingProcessed != nil){
                return true
            }
        }
        else if indexPath.section == 1{
            if indexPath.row < cards.count || (indexPath.row == cards.count && cardBeingProcessed != nil){
                return true
            }
        }
        return false
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath:NSIndexPath){}
    
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        UIButton.appearance().setAttributedTitle(Constants.getTitleAttributedString("DELETE", size: 14, kern: 3.0), forState: .Normal)
        
        let deleteAction = UITableViewRowAction(style: .Normal, title: "DELETE"){ (action, indexPath) in
            if indexPath.section == 0{
                self.delegate?.addressRemoved(indexPath.row)
                self.addresses.removeAtIndex(indexPath.row)
            }
            else{
                self.delegate?.cardRemoved(indexPath.row)
                self.cards.removeAtIndex(indexPath.row)
            }
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        }
        deleteAction.backgroundColor = Constants.lightRed
        return [deleteAction]
    }
    
    //MARK: Helper Functions
    func preferenceCellWithTitle(title: String, isPreferred: Bool) -> UITableViewCell{
        let cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier("InfoCell")! as UITableViewCell
        for subview in cell.subviews{
            if subview is PreferenceLight || subview is CustomActivityIndicatorView{
                subview.removeFromSuperview()
            }
        }
        
        cell.backgroundColor = Constants.darkBlue
        cell.textLabel?.attributedText = Constants.getTitleAttributedString(title, size: 16, kern: 4.0)
        cell.textLabel?.textAlignment = .Left
        cell.selectionStyle = .None
        let width = menuWidth ?? view.frame.width-Constants.sliceControllerShowing
     
        if isPreferred{
            cell.addSubview(getCircleView(CGPoint(x: width - 20, y: cellHeight/2 - 5)))
        }
        return cell
    }
    
    func preferenceCellBeingProcessed(title: String) -> UITableViewCell{
        let cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier("InfoCell")! as UITableViewCell
        for subview in cell.subviews{
            if subview is PreferenceLight || subview is CustomActivityIndicatorView{
                subview.removeFromSuperview()
            }
        }
        cell.backgroundColor = Constants.darkBlue
        cell.textLabel?.attributedText = Constants.getTitleAttributedString(title, size: 16, kern: 4.0)
        cell.textLabel?.textAlignment = .Left
        let width = menuWidth ?? view.frame.width-Constants.sliceControllerShowing
        let spinner = CustomActivityIndicatorView(image: UIImage(imageLiteral: "loading-1"))
        spinner.center = CGPoint(x: width-12, y: cellHeight/2)
        cell.addSubview(spinner)
        spinner.startAnimating()
        
        return cell
    }
    
    
    func newCell() -> UITableViewCell{
        let cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier("InfoCell")! as UITableViewCell
        for subview in cell.subviews{
            if subview is PreferenceLight || subview is CustomActivityIndicatorView{
                subview.removeFromSuperview()
            }
        }
        cell.backgroundColor = Constants.darkBlue
        cell.textLabel?.textAlignment = .Center
        cell.textLabel?.textColor = Constants.seaFoam
        cell.textLabel?.font = UIFont(name: "Myriad Pro", size: 20)
        cell.textLabel?.text = "+"
        cell.selectionStyle = .None
        return cell
    }
    
    func accountCell(text: String, isRed: Bool) -> UITableViewCell{
        let cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier("InfoCell")! as UITableViewCell
        for subview in cell.subviews{
            if subview is PreferenceLight || subview is CustomActivityIndicatorView{
                subview.removeFromSuperview()
            }
        }
        
        cell.backgroundColor = Constants.darkBlue
        cell.textLabel?.attributedText = Constants.getTitleAttributedString(text, size: 16, kern: 4.0)
        if isRed{
            cell.textLabel?.textColor = Constants.lightRed
        }
        cell.textLabel?.textAlignment = .Center
        cell.selectionStyle = .None
        return cell
    }
    
}

class PreferenceLight: UIView{}

class MenuTable: UITableView{
    override func reloadData() {
        super.reloadData()
        UIButton.appearance().setAttributedTitle(Constants.getTitleAttributedString("", size: 14, kern: 3.0), forState: .Normal)
    }
}
