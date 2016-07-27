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
    private var data: [String : [String]]?
    
    init(){
        Alamofire.request(.GET, Constants.getAddressesURLString, parameters: nil).responseJSON{
            response in
            switch response.result{
            
            case .Success:
                self.data = [String : [String]]()
                if let value = response.result.value{
                    let dict = JSON(value)["Schools"].dictionaryValue
                    for(school, _) in dict{
                        self.data![school] = dict[school]?.arrayObject as? [String]
                    }
                }
            default: break
            }
        }
    }
    
    func getData() -> [String : [String]] {
        return data ?? ["Columbia University" : Constants.columbiaDorms, "Georgetown University" : Constants.georgetownDorms]
    }
}