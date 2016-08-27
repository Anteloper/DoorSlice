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
    func copyWithZone(zone: NSZone) -> AnyObject {
        return self.dynamicType.init(self)
    }
    
    required convenience init?(coder decoder: NSCoder){
        guard let school = decoder.decodeObjectForKey("school") as? String,
            let dorm = decoder.decodeObjectForKey("dorm") as? String,
            let room = decoder.decodeObjectForKey("room") as? String else{
                return nil
        }
        self.init(school: school, dorm: dorm, room: room)
    }
    
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(self.school, forKey: "school")
        aCoder.encodeObject(self.dorm, forKey: "dorm")
        aCoder.encodeObject(self.room, forKey: "room")
        
    }
    
    func getName()-> String{
        return Constants.dormNicknames[self.dorm] == nil ? self.dorm + " " + self.room : Constants.dormNicknames[self.dorm]! + " " + self.room
    }
}