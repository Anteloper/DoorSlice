//
//  TutorialController.swift
//  Slice
//
//  Created by Oliver Hill on 8/11/16.
//  Copyright © 2016 Oliver Hill. All rights reserved.
//

import UIKit

class TutorialController: UIViewController {
    
    var user: User!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.whiteColor()
        let isIphone5 = UIScreen.mainScreen().bounds.height <= 568.0
        let fullView = UIImageView(frame: view.frame)
        fullView.image = UIImage(imageLiteral: isIphone5 ? "" : "tutorial6")
        fullView.layer.minificationFilter = kCAFilterTrilinear
        view.addSubview(fullView)
    }
    
    
}
