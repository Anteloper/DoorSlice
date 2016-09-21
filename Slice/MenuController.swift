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
    
    func getCircleView(_ origin: CGPoint) -> PreferenceLight{
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
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "InfoCell")
        tableView.showsVerticalScrollIndicator = false
        tableView.allowsSelectionDuringEditing = false
        self.view.addSubview(tableView)
    }
    
    
    
    //MARK: TableView Delegate Methods
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeight
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
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
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return cellHeight*3/4
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: cellHeight*3/4))
        headerView.backgroundColor = Constants.seaFoam
        headerView.alpha = 1.0
        
        let title = UILabel(frame: headerView.frame)
        let message = section == 2 ? "ACCOUNT" : (section == 0 ? "DELIVER TO" : "PAY WITH")
        title.attributedText =  Constants.getTitleAttributedString(message, size: 16, kern: 4.0)
        title.backgroundColor = UIColor.clear
        title.textAlignment = .center
        
        headerView.addSubview(title)
        return headerView
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (indexPath as NSIndexPath).section == 0{
            if (indexPath as NSIndexPath).row < addresses.count{
                return preferenceCellWithTitle((addresses[(indexPath as NSIndexPath).row]).getName(), isPreferred: (indexPath as NSIndexPath).row == preferredAddress)
            }
            else if (indexPath as NSIndexPath).row == addresses.count && addressBeingProcessed != nil{
                return preferenceCellBeingProcessed(addressBeingProcessed!.getName())
            }
            else{
                return newCell()
            }
        }
        else if (indexPath as NSIndexPath).section == 1{
            if (indexPath as NSIndexPath).row < cards.count{
                return preferenceCellWithTitle(cardBeginning + cards[(indexPath as NSIndexPath).row], isPreferred: (indexPath as NSIndexPath).row == preferredCard)
            }
            else if (indexPath as NSIndexPath).row == cards.count && cardBeingProcessed != nil {
                return preferenceCellBeingProcessed(cardBeginning + cardBeingProcessed!)
            }
            else{
                return newCell()
            }
        }
        else{
            return accountCell(accountStrings[(indexPath as NSIndexPath).row], isRed: (indexPath as NSIndexPath).row == accountStrings.count-1)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath as NSIndexPath).section == 0{
            if (indexPath as NSIndexPath).row < addresses.count{
                preferredAddress = (indexPath as NSIndexPath).row
            }
            else{
                delegate!.bringMenuToNewAddress()
            }
        }
        else if (indexPath as NSIndexPath).section == 1{
            if (indexPath as NSIndexPath).row < cards.count{
                preferredCard = (indexPath as NSIndexPath).row
            }
            else{
                delegate!.bringMenuToNewCard()
            }
        }
        else{
            if (indexPath as NSIndexPath).row == 0{
                delegate!.bringMenuToSettings()
            }
            else if (indexPath as NSIndexPath).row == 1{
                delegate!.bringMenuToOrderHistory()
            }
            else if (indexPath as NSIndexPath).row == 2{
                delegate!.logoutConfirmation()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if (indexPath as NSIndexPath).section == 0{
            if (indexPath as NSIndexPath).row < addresses.count || ((indexPath as NSIndexPath).row == addresses.count && addressBeingProcessed != nil){
                return true
            }
        }
        else if (indexPath as NSIndexPath).section == 1{
            if (indexPath as NSIndexPath).row < cards.count || ((indexPath as NSIndexPath).row == cards.count && cardBeingProcessed != nil){
                return true
            }
        }
        return false
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath:IndexPath){}
    
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        UIButton.appearance().setAttributedTitle(Constants.getTitleAttributedString("DELETE", size: 14, kern: 3.0), for: UIControlState())
        
        let deleteAction = UITableViewRowAction(style: .normal, title: "DELETE"){ (action, indexPath) in
            if (indexPath as NSIndexPath).section == 0{
                self.delegate?.addressRemoved((indexPath as NSIndexPath).row)
                self.addresses.remove(at: (indexPath as NSIndexPath).row)
            }
            else{
                self.delegate?.cardRemoved((indexPath as NSIndexPath).row)
                self.cards.remove(at: (indexPath as NSIndexPath).row)
            }
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
        deleteAction.backgroundColor = Constants.lightRed
        return [deleteAction]
    }
    
    //MARK: Helper Functions
    func preferenceCellWithTitle(_ title: String, isPreferred: Bool) -> UITableViewCell{
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "InfoCell")! as UITableViewCell
        for subview in cell.subviews{
            if subview is PreferenceLight || subview is CustomActivityIndicatorView{
                subview.removeFromSuperview()
            }
        }
        
        cell.backgroundColor = Constants.darkBlue
        cell.textLabel?.attributedText = Constants.getTitleAttributedString(title, size: 16, kern: 4.0)
        cell.textLabel?.textAlignment = .left
        cell.selectionStyle = .none
        let width = menuWidth ?? view.frame.width-Constants.sliceControllerShowing
     
        if isPreferred{
            cell.addSubview(getCircleView(CGPoint(x: width - 20, y: cellHeight/2 - 5)))
        }
        return cell
    }
    
    func preferenceCellBeingProcessed(_ title: String) -> UITableViewCell{
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "InfoCell")! as UITableViewCell
        for subview in cell.subviews{
            if subview is PreferenceLight || subview is CustomActivityIndicatorView{
                subview.removeFromSuperview()
            }
        }
        cell.backgroundColor = Constants.darkBlue
        cell.textLabel?.attributedText = Constants.getTitleAttributedString(title, size: 16, kern: 4.0)
        cell.textLabel?.textAlignment = .left
        let width = menuWidth ?? view.frame.width-Constants.sliceControllerShowing
        let spinner = CustomActivityIndicatorView(image: UIImage(imageLiteralResourceName: "loading"))
        spinner.center = CGPoint(x: width-12, y: cellHeight/2)
        cell.addSubview(spinner)
        spinner.startAnimating()
        
        return cell
    }
    
    
    func newCell() -> UITableViewCell{
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "InfoCell")! as UITableViewCell
        for subview in cell.subviews{
            if subview is PreferenceLight || subview is CustomActivityIndicatorView{
                subview.removeFromSuperview()
            }
        }
        cell.backgroundColor = Constants.darkBlue
        cell.textLabel?.textAlignment = .center
        cell.textLabel?.textColor = Constants.seaFoam
        cell.textLabel?.font = UIFont(name: "Myriad Pro", size: 20)
        cell.textLabel?.text = "+"
        cell.selectionStyle = .none
        return cell
    }
    
    func accountCell(_ text: String, isRed: Bool) -> UITableViewCell{
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "InfoCell")! as UITableViewCell
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
        cell.textLabel?.textAlignment = .center
        cell.selectionStyle = .none
        return cell
    }
    
}

class PreferenceLight: UIView{}

class MenuTable: UITableView{
    override func reloadData() {
        super.reloadData()
        UIButton.appearance().setAttributedTitle(Constants.getTitleAttributedString("", size: 14, kern: 3.0), for: UIControlState())
    }
}
