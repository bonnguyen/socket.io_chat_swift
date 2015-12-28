//
//  Message.swift
//  socket.io_chat_swift
//
//  Created by Nguyen Bon on 12/25/15.
//  Copyright © 2015 SmartDev LLC. All rights reserved.
//

import Foundation

class Message : NSObject {
    var message:String!
    var userName:String!
    var type:MessageType!
    
    override init() {
        super.init()
    }
}
