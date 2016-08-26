//
//  ActiveAddresses.swift
//  Slice
//
//  Created by Oliver Hill on 7/7/16.
//  Copyright © 2016 Oliver Hill. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

class ActiveAddresses{
    private var dorms: [String]?
    
    init(user: User){
        Alamofire.request(.GET, Constants.getAddressesURLString + user.userID, parameters: nil).responseJSON{ response in
            debugPrint(response)
            switch response.result{
            
            case .Success:
                if let value = response.result.value{
                    self.dorms = [String]()
                    for dorm in JSON(value)["Dorms"].arrayValue{
                        self.dorms?.append(dorm.stringValue)
                    }
                }
               
            default: break
            }
        }
    }
    
    func getDorms() -> [String]? {
        return dorms
    }
}