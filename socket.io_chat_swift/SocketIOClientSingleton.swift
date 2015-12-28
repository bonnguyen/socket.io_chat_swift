//
//  SocketIOClientSingleton.swift
//  socket.io_chat_swift
//
//  Created by Nguyen Bon on 12/24/15.
//  Copyright © 2015 SmartDev LLC. All rights reserved.
//

import Foundation
import Socket_IO_Client_Swift

public class SocketIOClientSingleton {
    
    static let instance = SocketIOClientSingleton()
    
    var socket:SocketIOClient!
    
    private init() {
        self.socket = SocketIOClient(socketURL: Constants.CHAT_SERVER_URL, options: [.Log(false), .ForcePolling(true)])
    }
    
}
