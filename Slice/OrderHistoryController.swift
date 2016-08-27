//
//  OrderHistoryController.swift
//  Slice
//
//  Created by Oliver Hill on 7/23/16.
//  Copyright © 2016 Oliver Hill. All rights reserved.
//

import UIKit

//View Controller for displaying a non-selectable, non-editable Table View of the users orders. Each cell represents a PastOrder object
class OrderHistoryController: NavBarred, UITableViewDelegate, UITableViewDataSource{
    
    var orderHistory: [PastOrder]!
    var tableView = UITableView()
    var delegate: Slideable!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        actionForBackButton({self.delegate!.returnFromFullscreen(withCard: nil, orAddress: nil, fromSettings: false)})
        
        if orderHistory.count != 0{
   
            setupTableView()
            orderHistory = orderHistory.reverse()
            addTitleLabel()
        }
        else{
            emptyDataSet()
        }
    }
    
    func addTitleLabel(){
        let label = UILabel(frame: CGRect(x: 0, y: 60, width: view.frame.width, height: 100))
        label.attributedText = Constants.getTitleAttributedString("ORDER HISTORY", size: 16, kern: 6.0)
        label.textAlignment = .Center
        view.addSubview(label)
    }

    func setupTableView(){
        tableView.frame = CGRect(x: 0, y: 160, width: view.frame.width, height: view.frame.height-160)
        self.automaticallyAdjustsScrollViewInsets = false
        tableView.backgroundColor = Constants.darkBlue
        tableView.delegate = self
        tableView.dataSource = self
        tableView.registerClass(OrderCell.self, forCellReuseIdentifier: "OrderCell")
        tableView.showsVerticalScrollIndicator = false
        tableView.allowsSelection = false
        view.addSubview(tableView)
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 100
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return orderHistory.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("OrderCell")! as! OrderCell
        cell.order = orderHistory[indexPath.row]
        return cell
    }
    
    func emptyDataSet(){
        let width = UIScreen.mainScreen().bounds.width
        let imageView = UIImageView(frame: CGRect(x: 0, y: view.frame.midY - width/2, width: width, height: width))
        imageView.image = UIImage(imageLiteral: "noOrders")
        imageView.layer.minificationFilter = kCAFilterTrilinear
        view.addSubview(imageView)
    }
}
