//
//  Character+UnicodeScalar.swift
//  socket.io_chat_swift
//
//  Created by Nguyen Bon on 12/28/15.
//  Copyright © 2015 SmartDev LLC. All rights reserved.
//

import Foundation

extension Character
{
    func unicodeScalarCodePoint() -> Int
    {
        let characterString = String(self)
        let scalars = characterString.unicodeScalars
        
        return Int(scalars[scalars.startIndex].value)
    }
}
