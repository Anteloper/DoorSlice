//
//  MenuController.swift
//  Slice
//
//  Created by Oliver Hill on 6/9/16.
//  Copyright © 2016 Oliver Hill. All rights reserved.
//

import UIKit



class MenuController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate {
    
    var delegate: Slideable?
    var menuWidth: CGFloat?
    
    let tableView = UITableView()
    let cellHeight: CGFloat = 80
    
    //User Info
    var addresses: [String]!
    var cards: [String]!{didSet{print(cards)}}
    
    //The 0th element in cards will always be the string "Pay"
    
    var preferredAddress: Int! { didSet{ tableView.reloadData() } }
    var preferredCard: PaymentPreference = .ApplePay { didSet{ tableView.reloadData()} }
    
    var cardBeingProcessed: String?{didSet{ tableView.reloadData() }}//Will be not nil while a card is being verified by the backend
    
    //MARK: ViewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.blackColor()
        tableViewSetup()
    }
    
    
    //MARK: TableView Setup
    func tableViewSetup(){
        tableView.frame = CGRect(x: 0,
                                 y: 64,
                                 width: menuWidth ?? view.frame.width-Constants.sliceControllerShowing,
                                 height: view.frame.size.height-64)
        tableView.backgroundView?.backgroundColor = UIColor.blackColor()
        tableView.backgroundColor = UIColor.blackColor()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "InfoCell")
        tableView.showsVerticalScrollIndicator = false
        self.view.addSubview(tableView)
    }
    
    
    
    //MARK: TableView Delegate Methods
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return cellHeight
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var cat = 0
        if section == 0{
            cat = addresses.count + 1
        }
        else{
            cat = cardBeingProcessed == nil ? cards.count + 1 : cards.count + 2
        }
        print(cat)
        return cat
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "Deliver To" : "Pay With"
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 80
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: 80))
        headerView.backgroundColor = Constants.tiltColor
        headerView.alpha = 1.0
        
        let title = UILabel(frame: headerView.frame)
        title.font = UIFont(name: "GillSans-Light", size: 20)
        title.text = section == 0 ? "Deliver To" : "Pay With"
        title.textColor = UIColor.whiteColor()
        title.backgroundColor = UIColor.clearColor()
        title.textAlignment = .Center
        
        headerView.addSubview(title)
        return headerView
        
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0{
            if indexPath.row < addresses.count{
                return preferenceCellWithTitle(addresses[indexPath.row], isPreferred: indexPath.row == preferredAddress)
            }
            else{
                return newCell()
            }
        }
        else{
            let str = indexPath.row == 0 ? "" : "Ending in "
        
            if indexPath.row < cards.count{
                
                return preferenceCellWithTitle(str + cards[indexPath.row], isPreferred: isPreferredCard(indexPath.row))
            }
                
            else if indexPath.row == cards.count && cardBeingProcessed != nil {
                return preferenceCellBeingProcessed(cardBeingProcessed!)
            }
            
            else{
                return newCell()
            }
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if indexPath.section == 0{
            if indexPath.row <= addresses.count{
                preferredAddress = indexPath.row
            }
            else{
                /*//TODO: Nicer animation
                for subview in view.subviews{
                    subview.removeFromSuperview()
                }
                delegate!.bringMenuToFullscreen(){ finished in
                    let newView = NewAddressView(frame: self.view.frame)
                    newView.delegate = self.delegate!
                    self.view = newView
                }*/
            }
        }
        else{
            if indexPath.row < (cards == nil ?  0 : cards.count){
                preferredCard = indexPath.row == 0 ? .ApplePay : PaymentPreference.CardIndex(indexPath.row)
            }
            else{
                delegate!.bringMenuToFullscreen()
            }
        }
        
        
    }
    
    
    //MARK: Helper Functions
    func preferenceCellWithTitle(title: String, isPreferred: Bool) -> UITableViewCell{
        
        let cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier("InfoCell")! as UITableViewCell
        for subview in cell.subviews{
            if subview is UIImageView || subview is CustomActivityIndicatorView{
                subview.removeFromSuperview()
            }
        }
        
        cell.backgroundColor = UIColor.blackColor()
        cell.textLabel?.font = UIFont(name: "GillSans-Light", size: 20)
        cell.textLabel?.text = title
        cell.textLabel?.textAlignment = .Left
        cell.textLabel?.textColor = UIColor.whiteColor()
        
        let width = menuWidth ?? view.frame.width-Constants.sliceControllerShowing
     
        if isPreferred{
            let preferenceLight = UIImageView(frame: CGRect(x: width - 20, y: cellHeight/2 - 5, width: 10, height: 10))
            preferenceLight.image = UIImage(imageLiteral: "circle")
            cell.addSubview(preferenceLight)
        }

        return cell
    }
    
    func preferenceCellBeingProcessed(title: String) -> UITableViewCell{
        let cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier("InfoCell")! as UITableViewCell
        for subview in cell.subviews{
            if subview is UIImageView || subview is CustomActivityIndicatorView{
                subview.removeFromSuperview()
            }
        }
        cell.backgroundColor = UIColor.blackColor()
        cell.textLabel?.font = UIFont(name: "GillSans-Light", size: 20)
        cell.textLabel?.text = title
        cell.textLabel?.textAlignment = .Left
        cell.textLabel?.textColor = UIColor.whiteColor()
        
        let width = menuWidth ?? view.frame.width-Constants.sliceControllerShowing
        let spinner = CustomActivityIndicatorView(image: UIImage(imageLiteral: "loading-1"))
        spinner.center = CGPoint(x: width-12, y: cellHeight/2)
        cell.addSubview(spinner)
        spinner.startAnimating()
        
        return cell
    }
    
    
    func newCell() -> UITableViewCell{
        let cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier("InfoCell")! as UITableViewCell
        cell.backgroundColor = UIColor.blackColor()
        cell.textLabel?.textAlignment = .Center
        cell.textLabel?.textColor = Constants.eucalyptus
        cell.textLabel?.font = UIFont(name: "GillSans-Light", size: 20)
        cell.textLabel?.text = "+"
        return cell
    }
    
    
    func isPreferredCard(row: Int)->Bool{
        switch preferredCard{
        case .ApplePay:
            return row == 0
        case .CardIndex(let pref):
            return row == pref
        }
    }
  
    
}

