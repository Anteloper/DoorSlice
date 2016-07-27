//
//  OrderHistoryController.swift
//  Slice
//
//  Created by Oliver Hill on 7/23/16.
//  Copyright © 2016 Oliver Hill. All rights reserved.
//

import UIKit


class OrderHistoryController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate{
    
    var orderHistory: [PastOrder]!
    var tableView = UITableView()
    var delegate: Slideable!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(view.frame.width)
        view.backgroundColor = Constants.darkBlue
        addTitleLabel()
        let swipe = UIPanGestureRecognizer(target: self, action: #selector(self.didSwipe(_:)))
        swipe.delegate = self
        view.addGestureRecognizer(swipe)
        if orderHistory.count == 0{
            setupTableView()
            orderHistory = orderHistory.reverse()
        }
        else{
            let trueMidY = (view.frame.height - 170)/2
            let origin = CGPoint(x: view.frame.midX - 300, y: trueMidY - 150)
            let size = CGSize(width: 600, height: 600)
            
            
            let emptyDataSetView = UIImageView(frame: CGRect(origin: origin, size: size))
            emptyDataSetView.image = UIImage(imageLiteral: "noOrders")

            view.addSubview(emptyDataSetView)
        }
    }

    func didSwipe(recognizer: UIPanGestureRecognizer){
        if recognizer.state == .Ended{
            let point = recognizer.translationInView(view)
            if(abs(point.x) >= abs(point.y)) && point.x > 40{
                backPressed()
            }
        }
    }

    func addTitleLabel(){
        let label = UILabel(frame: CGRect(x: 0, y: 20, width: view.frame.width, height: 150))
        label.attributedText = Constants.getTitleAttributedString("ORDER HISTORY")
        label.textAlignment = .Center
        view.addSubview(label)
        
        let backButton = Constants.getBackButton()
        backButton.addTarget(self, action: #selector(backPressed), forControlEvents: .TouchUpInside)
        view.addSubview(backButton)
    }
    
    func backPressed(){
        delegate!.returnFromFullscreen(withCard: nil, orAddress: nil)
    }
    func setupTableView(){
        tableView.frame = CGRect(x: 0, y: 150, width: view.frame.width, height: view.frame.height-150)
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
    
    
}
