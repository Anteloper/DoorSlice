//
//  Slideable.swift
//  Slice
//
//  Created by Oliver Hill on 6/10/16.
//  Copyright © 2016 Oliver Hill. All rights reserved.
//

import Foundation
import UIKit


//MARK: Slideable Protocol
//A menu can be slid out on top of items that conform to this protocol
protocol Slideable{
    func toggleMenu()
    func userSwipe(recognizer: UIPanGestureRecognizer)
    func userTap()
    func menuCurrentlyShowing()->Bool
    func bringMenuToFullscreen(completion: ((Bool) ->Void))
    func returnFromFullscreen()
}


