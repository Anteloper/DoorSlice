//
//  Address.swift
//  Slice
//
//  Created by Oliver Hill on 7/8/16.
//  Copyright © 2016 Oliver Hill. All rights reserved.
//

import Foundation

//An instance of this class is an object representing a single address added by a user. Conforms to NSCodign and NSCopying so it can be stored
//With the user
class Address: NSObject, NSCoding, NSCopying{
    var school: String
    var dorm: String
    var room: String
    

    init(school: String, dorm: String, room: String){
        self.school = school
        self.dorm = dorm
        self.room = room
    }
    
    required override init(){
        school = ""
        dorm = ""
        room = ""
    }
    
    required init(_ add: Address){
        school = add.school
        dorm = add.dorm
        room = add.room
    }
    func copy(with zone: NSZone?) -> Any {
        return type(of: self).init(self)
    }
    
    required convenience init?(coder decoder: NSCoder){
        guard let school = decoder.decodeObject(forKey: "school") as? String,
            let dorm = decoder.decodeObject(forKey: "dorm") as? String,
            let room = decoder.decodeObject(forKey: "room") as? String else{
                return nil
        }
        self.init(school: school, dorm: dorm, room: room)
    }
    
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.school, forKey: "school")
        aCoder.encode(self.dorm, forKey: "dorm")
        aCoder.encode(self.room, forKey: "room")
        
    }
    
    func getName()-> String{
        return Constants.dormNicknames[self.dorm] == nil ? self.dorm + " " + self.room : Constants.dormNicknames[self.dorm]! + " " + self.room
    }
}
