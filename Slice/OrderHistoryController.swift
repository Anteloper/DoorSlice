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
        actionForBackButton({self.delegate!.returnFromOrderHistory()})
        
        if orderHistory.count != 0{
   
            setupTableView()
            orderHistory = orderHistory.reversed()
            addTitleLabel()
        }
        else{
            emptyDataSet()
        }
    }
    
    func addTitleLabel(){
        let label = UILabel(frame: CGRect(x: 0, y: 60, width: view.frame.width, height: 100))
        label.attributedText = Constants.getTitleAttributedString("ORDER HISTORY", size: 16, kern: 6.0)
        label.textAlignment = .center
        view.addSubview(label)
    }

    func setupTableView(){
        tableView.frame = CGRect(x: 0, y: 160, width: view.frame.width, height: view.frame.height-160)
        self.automaticallyAdjustsScrollViewInsets = false
        tableView.backgroundColor = Constants.darkBlue
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(OrderCell.self, forCellReuseIdentifier: "OrderCell")
        tableView.showsVerticalScrollIndicator = false
        tableView.allowsSelection = false
        view.addSubview(tableView)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return orderHistory.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "OrderCell")! as! OrderCell
        cell.order = orderHistory[(indexPath as NSIndexPath).row]
        return cell
    }
    
    func emptyDataSet(){
        let width = UIScreen.main.bounds.width
        let imageView = UIImageView(frame: CGRect(x: 0, y: view.frame.midY - width/2, width: width, height: width))
        imageView.image = UIImage(imageLiteralResourceName: "noOrders")
        imageView.layer.minificationFilter = kCAFilterTrilinear
        view.addSubview(imageView)
    }
}
