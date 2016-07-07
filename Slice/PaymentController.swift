//
//  File.swift
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


//A bag of functions to actually charge the user. Delegate is used soley to pass back the amount
//Being charged when paying with apple pay because it is calculated in the createPaymentRequest function


class PaymentController{
    
    var delegate: Payable!
    
    
    //MARK: Card Specific Functions
    
    func saveNewCard(card: STPCardParams?, url: String, lastFour: String){
        STPAPIClient.sharedClient().createTokenWithCard(card!){ (tokenOpt, error) -> Void in
            if error != nil{
                print("Something went wrong")
            }
            else if let token = tokenOpt{
                Alamofire.request(.POST, url, parameters: ["stripeToken" : token.tokenId]).responseJSON { response in
                    switch response.result{
                    case .Success:
                        if let value = response.result.value{
                            print(JSON(value))
                            
                            let cardID = JSON(value)["card"].stringValue
                            if cardID != ""{
                                self.delegate.storeCardID(cardID, lastFour: lastFour)
                            }
                            else{
                                self.delegate.cardStoreageFailed()
                            }
                        }
                    case .Failure:
                        print(response.result.error)
                    }
                }
            }
        }
    }

    
    func changeCard(cardID: String, userID: String, completion: ()->Void){
        print(cardID)
        
        Alamofire.request(.POST, Constants.updateCardURLString+userID, parameters: ["cardID" : cardID]).responseJSON{ response in
            switch response.result{
            case .Success:
                completion()
            case .Failure:
                self.delegate.cardPaymentFailed()
            }
        }
    }
    
    
    //Amount should be in cents, url should already have userID appended to it
    //Default card should already be changed in the backend
    func chargeUser(url: String, amount: String, description: String){
        print(amount)
        print(description)
        let parameters = ["chargeAmount" : amount, "chargeDescription" : description]
        Alamofire.request(.POST, url, parameters: parameters).responseJSON{ response in
            switch response.result{
            case .Success:
                self.delegate.cardPaymentSuccesful()
            
            case .Failure:
                self.delegate.cardPaymentFailed()
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
                amount:NSDecimalNumber(double: cheese*4.00)))
        }
        if pepperoni != 0 {
            paymentRequest.paymentSummaryItems.append(PKPaymentSummaryItem(label: "Pepperoni slices",
                amount:NSDecimalNumber(double: pepperoni*4.00)))
        }
        let total = cheese*4 + pepperoni*4
        paymentRequest.paymentSummaryItems.append(PKPaymentSummaryItem(label: "DoorSlice Order", amount: NSDecimalNumber(double: total)))
        delegate.amountPaid(total)
        
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
        Alamofire.request(.POST, Constants.chargeUserURLString+userID, parameters: parameters).responseJSON { response in
            switch response.result{
            case .Success:
                print(JSON(response.result.value!))
                completion(.Success, nil)
            case .Failure(let error):
                print(error)
                completion(.Failure, NSError(domain: StripeDomain, code: 50, userInfo: [NSLocalizedDescriptionKey: "There was an error communication with your payment backend."]))
            }
        }
    }
}