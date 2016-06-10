//
//  MenuController.swift
//  Slice
//
//  Created by Oliver Hill on 6/9/16.
//  Copyright © 2016 Oliver Hill. All rights reserved.
//

import UIKit

enum CellType{
    case HeaderCell
    case PreferenceCell
    case NewCell
}

enum CellCategory{
    case Slice
    case Address
    case Card
}

class MenuController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate {
    
    var delegate: Slideable?
    var menuWidth: CGFloat?
    
    let tableView = UITableView()
    let cellHeight: CGFloat = 80
    
    //User Info
    var addresses: [String]?
    var cards: [String]?
    
    var prefersPlain = true { didSet{ updateTableView() } }
    var preferredAddress = 1 { didSet{ updateTableView() } }
    var preferredCard = 0 { didSet{ updateTableView() } }
    
    
    //MARK: ViewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.blackColor()
        garbage()
        tableViewSetup()
    }
    
    
    func tableViewSetup(){
        tableView.frame = CGRect(x: 0,
                                 y: 64,
                                 width: menuWidth ?? view.frame.width-Properties.sliceControllerShowing,
                                 height: view.frame.size.height-64)
        tableView.backgroundView?.backgroundColor = UIColor.blackColor()
        tableView.backgroundColor = UIColor.blackColor()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "InfoCell")
        tableView.showsVerticalScrollIndicator = false
        self.view.addSubview(tableView)
    }
    
    
    
    
    //MARK: TableView Delegate Methodss
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch cellTypeForPath(indexPath) {
            
        case .HeaderCell:
            return cellHeight
        case .PreferenceCell:
            return cellHeight
        default:
            return cellHeight
            
        }
    }
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 7+addresses!.count + cards!.count
    }
    
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cellNum = indexPath.row
        
        if cellNum == 0{
            return headerCellWithTitle("Slice Preference")
        }
            
        else if cellNum == 1{
            return preferenceCellWithTitle("Cheese", isPreferred: prefersPlain)
        }
            
        else if cellNum == 2{
            return preferenceCellWithTitle("Pepperoni", isPreferred: !prefersPlain)
        }
            
        else if cellNum == 3{
            return headerCellWithTitle("Deliver To")
        }
            //TODO: DON'T FORCE UNWRAP
        else if cellNum > 3 && cellNum < 4+addresses!.count{
            return preferenceCellWithTitle(addresses![cellNum-4], isPreferred: (preferredAddress==cellNum-4))
        }
        else if cellNum == 4+addresses!.count{
            return newCell()
        }
        else if cellNum == 5+addresses!.count{
            return headerCellWithTitle("Card Preference")
        }
        else if cellNum > 5+addresses!.count && cellNum < 6 + addresses!.count + cards!.count{
            return preferenceCellWithTitle("Ending in \(cards![cellNum-(6+addresses!.count)])", isPreferred: (preferredCard==cellNum-6+addresses!.count))
        }
        else{
            return newCell()
        }
        
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if(cellTypeForPath(indexPath) == .PreferenceCell){
            switch cellCategoryForPath(indexPath){
            case .Slice:
                prefersPlain = (indexPath.row == 1)
            case .Address:
                preferredAddress = indexPath.row-4
            case .Card:
                preferredCard = indexPath.row-(6+addresses!.count)
            }
        }
        else if(cellTypeForPath(indexPath) == .NewCell){
            //TODO: Nicer animation
            for subview in view.subviews{
                subview.removeFromSuperview()
            }
            delegate!.bringMenuToFullscreen(){ finished in
                let newView = NewAddressView(frame: self.view.frame)
                newView.delegate = self.delegate!
                self.view = newView
            }
        }
    }
    
    
    
    
    //MARK: Cell-returning Functions
    func headerCellWithTitle(title: String)->UITableViewCell{
        let cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier("InfoCell")! as UITableViewCell
        cell.backgroundColor = UIColor.blackColor()
        cell.textLabel?.font = UIFont(name: "GillSans-Light", size: 20)
        cell.textLabel?.text = title
        cell.textLabel?.textAlignment = .Center
        cell.textLabel?.textColor = Properties.tiltColor
        return cell
    }
    
    func preferenceCellWithTitle(title: String, isPreferred: Bool) -> UITableViewCell{
        
        let cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier("InfoCell")! as UITableViewCell
        
        for subview in cell.subviews{
            if subview is UIImageView{
                subview.removeFromSuperview()
            }
        }
        
        cell.backgroundColor = UIColor.blackColor()
        cell.textLabel?.font = UIFont(name: "GillSans-Light", size: 20)
        cell.textLabel?.text = title
        cell.textLabel?.textAlignment = .Left
        cell.textLabel?.textColor = UIColor.whiteColor()
        
        let width = menuWidth ?? view.frame.width-Properties.sliceControllerShowing
        if isPreferred{
            let preferenceLight = UIImageView(frame: CGRect(x: width - 20, y: cellHeight/2 - 5, width: 10, height: 10))
            preferenceLight.image = UIImage(imageLiteral: "circle")
            cell.addSubview(preferenceLight)
        }
        else{
            
        }
        return cell
    }
    
    func newCell() -> UITableViewCell{
        let cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier("InfoCell")! as UITableViewCell
        cell.backgroundColor = UIColor.blackColor()
        cell.textLabel?.textAlignment = .Center
        cell.textLabel?.textColor = Properties.eucalyptus
        cell.textLabel?.font = UIFont(name: "GillSans-Light", size: 20)
        cell.textLabel?.text = "+"
        return cell
    }
    
    
    
    
    func cellTypeForPath(path: NSIndexPath) ->CellType{
        let cellNum = path.row
        
        if cellNum == 0 || cellNum == 3{
            return .HeaderCell
        }
        else if cellNum == 1 || cellNum == 2 {
            return .PreferenceCell
        }
            //TODO: DON'T FORCE UNWRAP
        else if cellNum > 3 && cellNum < 4+addresses!.count{
            return .PreferenceCell
        }
        else if cellNum == 4+addresses!.count{
            return .NewCell
        }
        else if cellNum == 5+addresses!.count{
            return .HeaderCell
        }
            
        else if cellNum > 5+addresses!.count && cellNum < 6 + addresses!.count + cards!.count{
            return .PreferenceCell
        }
        else{
            return .NewCell
        }
    }
    
    
    func cellCategoryForPath(path: NSIndexPath) ->CellCategory{
        let cellNum = path.row
        if(cellNum <= 3){
            return .Slice
        }
            //TODO: Don't force unwrap
        else if(cellNum > 3 && cellNum <= 4+addresses!.count){
            return .Address
        }
        
        return .Card
    }
    
    
    func updateTableView(){
        tableView.reloadData()
    }
    
    func garbage(){
        addresses = ["56 Montgomery Place", "333 E 53rd St", "40 Cedar St"]
        cards = ["6947", "8452"]
        
    }
}
