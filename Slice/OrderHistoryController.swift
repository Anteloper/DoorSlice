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
        view.backgroundColor = Constants.darkBlue
        let swipe = UIPanGestureRecognizer(target: self, action: #selector(self.didSwipe(_:)))
        swipe.delegate = self
        
        navBarSetup()
        
        view.addGestureRecognizer(swipe)
        if orderHistory.count == 0{
            setupTableView()
            orderHistory = orderHistory.reverse()
            addTitleLabel()
        }
        else{
            emptyDataSet()
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
        label.attributedText = Constants.getTitleAttributedString("ORDER HISTORY", size: 16, kern: 6.0)
        label.textAlignment = .Center
        view.addSubview(label)
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
    
    func navBarSetup(){
        navigationController?.navigationBar.barTintColor = Constants.darkBlue
        let titleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 44))
        titleLabel.attributedText = Constants.getTitleAttributedString("SLICE", size: 16, kern: 6.0)
        titleLabel.textAlignment = .Center
        navigationItem.titleView = titleLabel
        
        let backButton = UIButton(type: .Custom)
        backButton.setImage(UIImage(imageLiteral: "back"), forState: .Normal)
        backButton.addTarget(self, action: #selector(backPressed), forControlEvents: .TouchUpInside)
        backButton.frame = CGRect(x: 0, y: -4, width: 20, height: 20)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
    }
    
    func emptyDataSet(){
        
        let emptyDataSetView = UIImageView(frame:CGRect(x: view.frame.midX-100, y:150, width: 200, height: 200))
        emptyDataSetView.image = UIImage(imageLiteral: "noOrders")
        emptyDataSetView.layer.minificationFilter = kCAFilterTrilinear
        view.addSubview(emptyDataSetView)
        view.sendSubviewToBack(emptyDataSetView)
        
        let label = UILabel(frame: CGRect(x:0, y: emptyDataSetView.frame.maxY+20, width: view.frame.width, height: 20))
        label.attributedText = Constants.getTitleAttributedString("THIS IS YOUR ORDER HISTORY", size: 17, kern: 4.0)
        label.textAlignment = .Center
        print(view.frame.width)
        
        let separation = (view.frame.width - 320)/2
    
        view.addSubview(label)
        
        
        let secondLabel = UILabel(frame: CGRect(x: separation, y: label.frame.maxY+15, width: 320, height: 40))
        secondLabel.numberOfLines = 0
        let text = "WHEN YOU ORDER SOME PIZZA IT WILL SHOW UP HERE"
        let cat = Constants.getTitleAttributedString(text, size: 17, kern: 4.0)
        cat.addAttribute(NSForegroundColorAttributeName, value: UIColor.lightGrayColor(), range: (cat.string as NSString).rangeOfString(text))
        secondLabel.attributedText = cat
        secondLabel.lineBreakMode = .ByWordWrapping
        secondLabel.textAlignment = .Center
        view.addSubview(secondLabel)
        
    }
    
}
