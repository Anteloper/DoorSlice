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
    case success, failure
}
typealias STPTokenSubmissionHandler = (STPBackendChargeResult?, NSError?) -> Void


//A bag of functions to do the vast majority of the networking and charge the user.
//Exactly one of the delegates and the headers property MUST BE SET to use this class
class NetworkingController{
    
    var containerDelegate: Payable?
    var tutorialDelegate: Configurable?
    var headers: [String : String]!
    
    //MARK: Save Order
    // Price is in dollars (6.49 = $6.49)
    func saveOrder(_ cheese: Int, pepperoni: Int, url: String, cardID: String, price: String, completion: @escaping ()->Void){
        let parameters = ["cheese" : String(cheese), "pepperoni" : String(pepperoni), "cardUsed" : cardID, "price" : String(price)]
        Alamofire.request(url, method: .post, parameters: parameters, encoding: .URL, headers: headers).responseJSON { _ in completion() }
    }
    

    //Saves a new card regardless of whether it is the user's first card or not. The url passed to it has already taken this into consideration
    func saveNewCard(_ card: STPCardParams?, url: String, lastFour: String){
        STPAPIClient.shared().createToken(withCard: card!){ (tokenOpt, error) -> Void in
            if error != nil{
                self.containerDelegate?.cardStoreageFailed(cardDeclined: true)
                self.tutorialDelegate?.cardStoreageFailed(cardDeclined: true)
            }
            else if let token = tokenOpt{
                let parameters = ["stripeToken" : token.tokenId, "lastFour" : lastFour]
                Alamofire.request(url, method: .post, parameters: parameters, encoding: .URL, headers: self.headers).responseJSON { response in
                    switch response.result{
                    case .success:
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
                    case .failure:
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


    func changeCard(_ cardID: String, userID: String, completion: @escaping ()->Void){
        Alamofire.request(Constants.updateCardURLString+userID, method: .post, parameters: ["cardID" : cardID], encoding: .URL, headers: headers).responseJSON{ response in
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
    func chargeUser(_ url: String, amount: String, description: String, cheese: Int, pepperoni: Int){
        let parameters = ["chargeAmount" : amount, "chargeDescription" : description]
        Alamofire.request(url, method: .post, parameters: parameters, encoding: .URL, headers: headers).responseJSON{ response in
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
    func saveAddress(_ add: Address, userID: String){
        let url = Constants.newAddressURLString+userID
        let parameters = ["School" : add.school, "Dorm" : add.dorm, "Room" : add.room]
        
        Alamofire.request(url, method: .post, parameters: parameters, encoding: .URL, headers: headers).responseJSON { response in
            switch response.result{
            case .success:
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
            case .failure:
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
    
    func deleteAddress(_ url: String, completion: @escaping (Bool)->Void){
        Alamofire.request(url, method: .delete, parameters: nil, encoding: .URL, headers: headers).responseJSON{ response in
            switch response.result{
            case .success:
                completion(true)
            case .failure:
                if response.response?.statusCode == 401{
                    self.containerDelegate?.unauthenticated()
                }
                else{
                    completion(false)
                }
            }
        }
    }
    
    func deleteCard(_ url: String, card: String, completion: @escaping (Bool)->Void){
        let parameters = ["cardID" : card]
        Alamofire.request(url, method: .post, parameters: parameters, encoding: .URL, headers: headers).responseJSON{ response in
            switch response.result{
            case .success:
                completion(true)
            case .failure:
                if response.response?.statusCode == 401{
                    self.containerDelegate?.unauthenticated()
                }
                else{
                    completion(false)
                }
            }
        }
    }
    
    func rateLastOrder(_ userID: String, stars: Int, comment: String?){
        let parameters = comment != nil ? ["stars" :  String(stars), "review" : comment!] : ["stars" : String(stars)]
        Alamofire.request(Constants.rateLastOrderURLString + userID, method: .post, parameters: parameters, encoding: .URL, headers: headers).responseJSON{ response in
            if response.response?.statusCode == 401{
                self.containerDelegate?.unauthenticated()
            }
        }
    }
    
    func addEmail(_ userID: String, email: String){
        Alamofire.request(Constants.addEmailURLString + userID, method: .post, parameters: ["email" : email], encoding: .URL, headers: headers).responseJSON{ response in
            switch response.result{
            case .success:
                break
            case .failure:
                if response.response?.statusCode == 401{
                    self.containerDelegate?.unauthenticated()
                }
                else{
                    self.containerDelegate?.emailSaveFailed()
                }
            }
        }
    }
    
    
    func booleanChange(_ endpoint: String, userID: String, boolean: Bool){
        let url = "\(Constants.booleanChangeURLString)\(endpoint)/\(userID)"
        let parameters = [endpoint : String(boolean)]
        Alamofire.request(url, method: .post, parameters: parameters, encoding: .url  , headers: headers).responseJSON{ response in
            if response.response?.statusCode == 401{
                self.containerDelegate?.unauthenticated()
            }
        }
    }
    
    func checkHours(_ userID: String){
        Alamofire.request(Constants.isOpenURLString + userID).responseJSON{ response in
            switch response.result{
            case .success:
                if let value = response.result.value{
                    if JSON(value)["open"].boolValue{
                        self.containerDelegate?.open()
                    }
                    else{
                        let closedString = JSON(value)["closedMessage"].stringValue
                        self.containerDelegate?.closed(closedString)
                    }
                }
            case .failure:
                self.containerDelegate?.closed("Couldn't establish a network connection")

            }
        }
    }
}
