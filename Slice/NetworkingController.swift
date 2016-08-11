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


//A bag of functions to do the all of the networking and charge the user. Delegate is used soley to pass back the amount
//Being charged when paying with apple pay because it is calculated in the createPaymentRequest function


class NetworkingController{
    
    var delegate: Payable!
    var headers: [String : String]!
    
    //MARK: Save Order
    //Used for both Apple Pay and card payment. Price is in dollars (6.49 = $6.49)
    func saveOrder(cheese: Int, pepperoni: Int, url: String, cardID: String, price: String, completion: ()->Void){
        let parameters = ["cheese" : String(cheese), "pepperoni" : String(pepperoni), "cardUsed" : cardID, "price" : String(price)]
        Alamofire.request(.POST, url, parameters: parameters, encoding: .URL, headers: headers).responseJSON { response in
            completion()
            switch response.result{
            case .Success:
                self.delegate!.addLoyalty(cheese+pepperoni)
            case .Failure:
                self.delegate!.removeLoyalty(cheese+pepperoni)
                if response.response?.statusCode == 401{ self.delegate.unauthenticated() }
            }
        }
    }
    
    
    //MARK: Card Specific Functions
    func saveNewCard(card: STPCardParams?, url: String, lastFour: String){
        STPAPIClient.sharedClient().createTokenWithCard(card!){ (tokenOpt, error) -> Void in
            if error != nil{
                self.delegate.cardStoreageFailed(trueFailure: true)
            }
            else if let token = tokenOpt{
                let parameters = ["stripeToken" : token.tokenId, "lastFour" : lastFour]
                Alamofire.request(.POST, url, parameters: parameters, encoding: .URL, headers: self.headers).responseJSON { response in
                    switch response.result{
                    case .Success:
                        if let value = response.result.value{
                            let cardID = JSON(value)["card"]["cardID"].stringValue
                            if cardID != ""{
                                self.delegate.storeCardID(cardID, lastFour: lastFour)
                            }
                            else{
                                self.delegate.cardStoreageFailed(trueFailure: false)
                            }
                        }
                    case .Failure:
                        if response.response?.statusCode == 401{
                            self.delegate.unauthenticated()
                        }
                        else{
                            self.delegate.cardStoreageFailed(trueFailure: true)
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
                    self.delegate.unauthenticated()
                }
                else{
                    self.delegate.cardPaymentFailed()
                }
            }
        }
    }
    
    //Amount should be in cents, url should already have userID appended to it
    //Default card should already be changed in the backend
    //Amount is in cents (649 = $6.49)
    func chargeUser(url: String, amount: String, description: String){
        let parameters = ["chargeAmount" : amount, "chargeDescription" : description]
        Alamofire.request(.POST, url, parameters: parameters, encoding: .URL, headers: headers).responseJSON{ response in
            switch response.result{
            case .Success:
                self.delegate.cardPaymentSuccesful()
            
            case .Failure:
                if response.response?.statusCode == 401{
                    self.delegate.unauthenticated()
                }
                else{
                    self.delegate.cardPaymentFailed()
                }
            }
        }
    }
    
    
    
    //MARK: Apple Pay Functions
    static func canApplePay() -> Bool{
        if let paymentRequest = Stripe.paymentRequestWithMerchantIdentifier(Constants.appleMerchantId){
            if Stripe.canSubmitPaymentRequest(paymentRequest){
                return true
            }
        }
        return false
    }
    
    
    func createPaymentRequest(cheese cheese: Double, pepperoni: Double) -> PKPaymentRequest{
        let paymentRequest = Stripe.paymentRequestWithMerchantIdentifier(Constants.appleMerchantId)!
        if cheese != 0 {
            paymentRequest.paymentSummaryItems.append(PKPaymentSummaryItem(label: "Cheese slices",
                amount:NSDecimalNumber(double: cheese*3.00)))
        }
        if pepperoni != 0 {
            paymentRequest.paymentSummaryItems.append(PKPaymentSummaryItem(label: "Pepperoni slices",
                amount:NSDecimalNumber(double: pepperoni*3.59)))
        }
        let total = cheese*3 + pepperoni*3.59
        paymentRequest.paymentSummaryItems.append(PKPaymentSummaryItem(label: "DoorSlice Order", amount: NSDecimalNumber(double: total)))
        
        return paymentRequest
    }
    
    
    func applePayAuthorized(payment: PKPayment, userID: String, amount: Int, description: String, completion: ((PKPaymentAuthorizationStatus) -> Void)){
        let apiClient = STPAPIClient(publishableKey: Constants.stripePublishableKey)
        apiClient.createTokenWithPayment(payment, completion: { (token, error) -> Void in
            if error == nil {
                if let token = token {
                    self.createBackendChargeWithToken(token, userID: userID, amount: amount, description: description, completion: { (result, error) -> Void in
                        if result == STPBackendChargeResult.Success {
                            completion(PKPaymentAuthorizationStatus.Success)
                            self.delegate.applePayFailed = false
                        }
                        else {
                            completion(PKPaymentAuthorizationStatus.Failure)
                            self.delegate.applePayFailed = true
                        }
                    })
                }
            }
            else {
                completion(PKPaymentAuthorizationStatus.Failure)
                self.delegate.applePayFailed = true
            }
        })
    }
    
    
    //MARK: Charge Backend
    func createBackendChargeWithToken(token: STPToken, userID: String, amount: Int, description: String, completion: STPTokenSubmissionHandler) {
        
        let parameters = ["stripeToken" : token, "chargeAmount" : amount, "chargeDescription" : description]
        Alamofire.request(.POST, Constants.chargeUserURLString+userID, parameters: parameters, encoding: .URL, headers: headers).responseJSON { response in
            switch response.result{
            case .Success:
                completion(.Success, nil)
            case .Failure:
                if response.response?.statusCode == 401{
                    self.delegate.unauthenticated()
                }
                completion(.Failure, NSError(domain: StripeDomain, code: 50, userInfo: [NSLocalizedDescriptionKey: "There was an error communication with your payment backend."]))
            }
        }
    }
    
    //MARK: Addresses
    func saveAddress(add: Address, userID: String){
        let url = Constants.newAddressURLString+userID
        let parameters = ["School" : add.school, "Dorm" : add.dorm, "Room" : add.room]

        Alamofire.request(.POST, url, parameters: parameters, encoding: .URL, headers: headers).responseJSON { response in
            print(response.response?.statusCode)
            switch response.result{
            case .Success:
                if let value = response.result.value{
                    let id = JSON(value)["Data"]["_id"].stringValue
                    if id != ""{
                        self.delegate.addressSaveSucceeded(add, orderID: id)
                    }
                    else{
                       self.delegate.addressSaveFailed()
                    }
                }
                else{
                    self.delegate.addressSaveFailed()
                }
            case .Failure:
                if response.response?.statusCode == 401{
                    self.delegate.unauthenticated()
                }
                else{
                    self.delegate.addressSaveFailed()
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
                    self.delegate.unauthenticated()
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
                    self.delegate.unauthenticated()
                }
                else{
                    completion(false)
                }
            }
        }
    }
    
    func rateLastOrder(userID: String, stars: Int, comment: String?){
        let parameters = comment != nil ? ["stars" :  String(stars), "review" : comment!] : ["stars" : String(stars)]
        Alamofire.request(.POST, Constants.rateLastOrderURLString + userID, parameters: parameters, encoding: .URL, headers: headers)
    }
    
    //TODO: error handle
    func addEmail(userID: String, email: String){
        Alamofire.request(.POST, Constants.addEmailURLString + userID, parameters: ["email" : email], encoding: .URL, headers: headers).responseJSON{ response in
            debugPrint(response)
        }
    }
    
    
    func booleanChange(endpoint: String, userID: String, boolean: Bool){
        let url = "\(Constants.booleanChangeURLString)\(endpoint)/\(userID)"
        let parameters = [endpoint : String(boolean)]
        Alamofire.request(.POST, url, parameters: parameters, encoding: .URL, headers: headers).responseJSON{ response in
            debugPrint(response)
        }
    }
    
    
    static func checkHours()->Bool{
        var isOpen = false
        Alamofire.request(.GET, Constants.isOpenURLString).responseJSON{ response in
            switch response.result{
            case .Success:
                if let value = response.result.value{
                    if JSON(value)["open"].boolValue{
                        isOpen = true
                    }
                    else{
                        isOpen = false
                    }
                }
            case .Failure:
                isOpen = false
            }
        }
        return isOpen
    }
}



