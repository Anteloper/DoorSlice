//
//  PaymentController.swift
//  Slice
//
//  Created by Oliver Hill on 6/22/16.
//  Copyright © 2016 Oliver Hill. All rights reserved.
//

import Foundation
import Stripe
import Alamofire
import SwiftyJSON

enum STPBackendChargeResult {
    case Success, Failure
}
typealias STPTokenSubmissionHandler = (STPBackendChargeResult?, NSError?) -> Void


//A bag of functions to do the all of the networking and charge the user. 
//Exactly one of the delegates and the headers property MUST BE SET to use this class
class NetworkingController{
    
    var containerDelegate: Payable?
    var tutorialDelegate: Configurable?
    var headers: [String : String]!
    
    //MARK: Save Order
    // Price is in dollars (6.49 = $6.49)
    func saveOrder(cheese: Int, pepperoni: Int, url: String, cardID: String, price: String, completion: ()->Void){
        let parameters = ["cheese" : String(cheese), "pepperoni" : String(pepperoni), "cardUsed" : cardID, "price" : String(price)]
        Alamofire.request(.POST, url, parameters: parameters, encoding: .URL, headers: headers).responseJSON { _ in completion() }
    }
    

    //Saves a new card regardless of whether it is the user's first card or not. The url passed to it has already taken this into consideration
    func saveNewCard(card: STPCardParams?, url: String, lastFour: String){
        STPAPIClient.sharedClient().createTokenWithCard(card!){ (tokenOpt, error) -> Void in
            if error != nil{
                self.containerDelegate?.cardStoreageFailed(cardDeclined: true)
                self.tutorialDelegate?.cardStoreageFailed(cardDeclined: true)
            }
            else if let token = tokenOpt{
                let parameters = ["stripeToken" : token.tokenId, "lastFour" : lastFour]
                Alamofire.request(.POST, url, parameters: parameters, encoding: .URL, headers: self.headers).responseJSON { response in
                    switch response.result{
                    case .Success:
                        if let value = response.result.value{
                            let json = JSON(value)
                            let cardID = json["card"]["cardID"].stringValue
                            if cardID != ""{
                                self.containerDelegate?.storeCardID(cardID, lastFour: lastFour)
                                self.tutorialDelegate?.storeCardID(cardID, lastFour: lastFour)
                            }
                            else if json["code"].stringValue == "card_declined"{
                                self.containerDelegate?.cardStoreageFailed(cardDeclined: true)
                                self.tutorialDelegate?.cardStoreageFailed(cardDeclined: true)
                            }
                            else{
                                self.containerDelegate?.cardStoreageFailed(cardDeclined: false)
                                self.tutorialDelegate?.cardStoreageFailed(cardDeclined: false)
                            }
                        }
                    case .Failure:
                        if response.response?.statusCode == 401{
                            self.containerDelegate?.unauthenticated()
                            self.tutorialDelegate?.unauthenticated()
                        }
                        else{
                            self.containerDelegate?.cardStoreageFailed(cardDeclined: false)
                            self.tutorialDelegate?.cardStoreageFailed(cardDeclined: false)
                        }
                    }
                }
            }
        }
    }


    func changeCard(cardID: String, userID: String, completion: ()->Void){
        Alamofire.request(.POST, Constants.updateCardURLString+userID, parameters: ["cardID" : cardID], encoding: .URL, headers: headers).responseJSON{ response in
            switch response.result{
            case .Success:
                completion()
            case .Failure:
                if response.response?.statusCode == 401{
                    self.containerDelegate?.unauthenticated()
                }
                else{
                    self.containerDelegate?.cardPaymentFailed(cardDeclined: false)
                }
            }
        }
    }
    
    //Amount should be in cents, url should already have userID appended to it
    //Default card should already be changed in the backend
    //Only called indirectly by NewtorkingController through a completion passed to it by ContainerController
    func chargeUser(url: String, amount: String, description: String, cheese: Int, pepperoni: Int){
        let parameters = ["chargeAmount" : amount, "chargeDescription" : description]
        Alamofire.request(.POST, url, parameters: parameters, encoding: .URL, headers: headers).responseJSON{ response in
            switch response.result{
            case .Success:
                if let value = response.result.value{
                    if JSON(value)["succesful charge"] != JSON("blank"){
                        self.containerDelegate?.cardPaymentSuccesful(cheese, pepperoniSlices: pepperoni)
                    }
                    else{
                        self.containerDelegate?.cardPaymentFailed(cardDeclined: true)
                    }
                }
            case .Failure:
                if response.response?.statusCode == 401{
                    self.containerDelegate?.unauthenticated()
                }
                else{
                    self.containerDelegate?.cardPaymentFailed(cardDeclined: false)
                }
            }
        }
    }
    
    
    //MARK: Non Payment Functions
    func saveAddress(add: Address, userID: String){
        let url = Constants.newAddressURLString+userID
        let parameters = ["School" : add.school, "Dorm" : add.dorm, "Room" : add.room]
        
        Alamofire.request(.POST, url, parameters: parameters, encoding: .URL, headers: headers).responseJSON { response in
            switch response.result{
            case .Success:
                if let value = response.result.value{
                    let id = JSON(value)["Data"]["_id"].stringValue
                    if id != ""{
                        self.containerDelegate?.addressSaveSucceeded(add, orderID: id)
                        self.tutorialDelegate?.addressSaveSucceeded(add, orderID: id)
                    }
                    else{
                        self.containerDelegate?.addressSaveFailed()
                        self.tutorialDelegate?.addressSaveFailed()
                    }
                }
                else{
                    self.containerDelegate?.addressSaveFailed()
                    self.tutorialDelegate?.addressSaveFailed()
                }
            case .Failure:
                if response.response?.statusCode == 401{
                    self.containerDelegate?.unauthenticated()
                    self.tutorialDelegate?.unauthenticated()
                }
                else{
                    self.containerDelegate?.addressSaveFailed()
                    self.tutorialDelegate?.addressSaveFailed()
                }
            }
        }
    }
    
    func deleteAddress(url: String, completion: (Bool)->Void){
        Alamofire.request(.DELETE, url, parameters: nil, encoding: .URL, headers: headers).responseJSON{ response in
            switch response.result{
            case .Success:
                completion(true)
            case .Failure:
                if response.response?.statusCode == 401{
                    self.containerDelegate?.unauthenticated()
                }
                else{
                    completion(false)
                }
            }
        }
    }
    
    func deleteCard(url: String, card: String, completion: (Bool)->Void){
        let parameters = ["cardID" : card]
        Alamofire.request(.POST, url, parameters: parameters, encoding: .URL, headers: headers).responseJSON{ response in
            switch response.result{
            case .Success:
                completion(true)
            case .Failure:
                if response.response?.statusCode == 401{
                    self.containerDelegate?.unauthenticated()
                }
                else{
                    completion(false)
                }
            }
        }
    }
    
    func rateLastOrder(userID: String, stars: Int, comment: String?){
        let parameters = comment != nil ? ["stars" :  String(stars), "review" : comment!] : ["stars" : String(stars)]
        Alamofire.request(.POST, Constants.rateLastOrderURLString + userID, parameters: parameters, encoding: .URL, headers: headers).responseJSON{ response in
            if response.response?.statusCode == 401{
                self.containerDelegate?.unauthenticated()
            }
        }
    }
    
    func addEmail(userID: String, email: String){
        Alamofire.request(.POST, Constants.addEmailURLString + userID, parameters: ["email" : email], encoding: .URL, headers: headers).responseJSON{ response in
            switch response.result{
            case .Success:
                break
            case .Failure:
                if response.response?.statusCode == 401{
                    self.containerDelegate?.unauthenticated()
                }
                else{
                    self.containerDelegate?.emailSaveFailed()
                }
            }
        }
    }
    
    
    func booleanChange(endpoint: String, userID: String, boolean: Bool){
        let url = "\(Constants.booleanChangeURLString)\(endpoint)/\(userID)"
        let parameters = [endpoint : String(boolean)]
        Alamofire.request(.POST, url, parameters: parameters, encoding: .URL, headers: headers).responseJSON{ response in
            if response.response?.statusCode == 401{
                self.containerDelegate?.unauthenticated()
            }
        }
    }
    
    func checkHours(userID: String){
        Alamofire.request(.GET, Constants.isOpenURLString + userID).responseJSON{ response in
            debugPrint(response)
            switch response.result{
            case .Success:
                if let value = response.result.value{
                    if JSON(value)["open"].boolValue{
                      self.containerDelegate?.open()
                    }
                    else{
                        let closedMessage = JSON(value)["closedMessage"].stringValue
                        self.containerDelegate?.closed(closedMessage)
                    }
                }
            case .Failure:
                self.containerDelegate?.closed("Failed to establish a network connection")
            }
        }
    }
}
