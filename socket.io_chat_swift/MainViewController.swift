//
//  ViewController.swift
//  socket.io_chat_swift
//
//  Created by Nguyen Bon on 12/24/15.
//  Copyright © 2015 SmartDev LLC. All rights reserved.
//

import UIKit
import Socket_IO_Client_Swift

class MainViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    @IBOutlet weak var tblMessage: UITableView!
    @IBOutlet weak var btnSend: UIButton!
    @IBOutlet weak var tfMessage: UITextField!
    
    private var usernameColors:[UIColor] = [
        UIColor(hexString: "#e21400"),
        UIColor(hexString: "#91580f"),
        UIColor(hexString: "#f8a700"),
        UIColor(hexString: "#f78b00"),
        UIColor(hexString: "#58dc00"),
        UIColor(hexString: "#287b00"),
        UIColor(hexString: "#a8f07a"),
        UIColor(hexString: "#4ae8c4"),
        UIColor(hexString: "#3b88eb"),
        UIColor(hexString: "#3824aa"),
        UIColor(hexString: "#a700ff"),
        UIColor(hexString: "#d300e7")]
    
    private var socket:SocketIOClient!
    private var messages:NSMutableArray? = NSMutableArray()
    private var typing:Bool! = false
    private var timer: NSTimer?
    private var delaySeconds:NSTimeInterval! = 0.6
    
    var userName:String!
    var numUsers:NSNumber! = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        tfMessage.delegate = self
        
        tblMessage.dataSource = self
        tblMessage.delegate = self
        
        tblMessage.estimatedRowHeight = 44.0
        tblMessage.rowHeight = UITableViewAutomaticDimension
        
        addLog("Welcome to Socket.IO Chat –")
        addParticipantsLog(numUsers)
        
        // try connect to char server
        socket = SocketIOClientSingleton.instance.socket
        
        socket?.on("new message") {data, ack in
            if let json = data[0] as? NSDictionary {
                let userName = json["username"] as! String
                let message = json["message"] as! String
                
                self.removeTyping(userName)
                self.addMessage(userName, message: message)
            }
        }
        
        socket?.on("user joined") {data, ack in
            if let json = data[0] as? NSDictionary {
                let userName = json["username"] as! String
                let numUsers = json["numUsers"]! as! NSNumber
                
                self.addLog(userName + " joined")
                self.addParticipantsLog(numUsers)
            }
        }
        
        socket?.on("user left") {data, ack in
            if let json = data[0] as? NSDictionary {
                let userName = json["username"] as! String
                let numUsers = json["numUsers"]! as! NSNumber
                
                self.addLog(userName + " left")
                self.addParticipantsLog(numUsers)
                self.removeTyping(userName)
            }
        }
        
        socket?.on("typing") {data, ack in
            if let json = data[0] as? NSDictionary {
                let userName = json["username"] as! String
                
                self.addTyping(userName)
            }
        }
        
        socket?.on("stop typing") {data, ack in
            if let json = data[0] as? NSDictionary {
                let userName = json["username"] as! String
                
                self.removeTyping(userName)
            }
        }
        
        socket?.connect()
    }
    
    @IBAction func sendMessage(sender: AnyObject) {
        attemptSend()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidDisappear(animated: Bool) {
        socket?.disconnect()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows in the section.
        return (messages?.count)!
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let row:Int? = indexPath.row
        if let message = messages?.objectAtIndex(row!) as? Message {
            if message.type == MessageType.Log {
                let cell:ChatItemLog? = tblMessage.dequeueReusableCellWithIdentifier("cellIdentifierChatItemLog", forIndexPath: indexPath) as? ChatItemLog
                cell?.lblLog.text = message.message
                
                return cell!
            } else if message.type == MessageType.TypeAction {
                let cell:ChatItemIsTyping? = tblMessage.dequeueReusableCellWithIdentifier("cellIdentifierChatItemIsTyping", forIndexPath: indexPath) as? ChatItemIsTyping
                cell?.lblTyping.text = message.message
                cell?.lblUserName.text = message.userName
                cell?.lblUserName.textColor = getUsernameColor(message.userName)
                
                return cell!
            } else {
                let cell:ChatItemMessage? = tblMessage.dequeueReusableCellWithIdentifier("cellIdentifierChatItemMessage", forIndexPath: indexPath) as? ChatItemMessage
                cell?.lblMessage.text = message.message
                cell?.lblUserName.text = message.userName
                cell?.lblUserName.textColor = getUsernameColor(message.userName)
                
                return cell!
            }
            
        }
        
        return UITableViewCell()
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let row:Int? = indexPath.row
        if let message = messages?.objectAtIndex(row!) as? Message {
            if message.type == MessageType.Message {
                return  UITableViewAutomaticDimension
            }
        }
        return 26.0
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        tfMessage.resignFirstResponder()
        attemptSend()
        return true
    }
    
    @IBAction func editingChanged(sender: AnyObject) {
        if !typing {
            typing = true
            socket.emit("typing")
        }
        
        self.timer?.invalidate()
        self.timer = nil
        self.timer = NSTimer.scheduledTimerWithTimeInterval(delaySeconds,
            target: self, selector: "typingTimeout", userInfo: nil, repeats: false)
    }
    
    func typingTimeout() {
        if !typing {
            return
        }
        
        self.typing = false;
        socket.emit("stop typing")
    }
    
    private func addLog(message:String?) {
        let msg = Message()
        msg.userName = self.userName
        msg.message = message
        msg.type = MessageType.Log
        
        self.messages?.addObject(msg)
        scrollToBottom()
    }
    
    private func addParticipantsLog(numUsers:NSNumber?) {
        var log:String? = ""
        if numUsers?.intValue == 1 {
            log = "there\'s " + String(numUsers!.intValue) + " participant"
        } else {
            log = "there are " + String(numUsers!.intValue) + " participants"
        }
        
        addLog(log)
    }
    
    private func addMessage(username:String?, message:String?) {
        let msg = Message()
        msg.userName = username
        msg.message = message
        msg.type = MessageType.Message
        
        self.messages?.addObject(msg)
        scrollToBottom()
    }
    
    private func addTyping(username:String?) {
        let msg = Message()
        msg.userName = username
        msg.message = "is typing"
        msg.type = MessageType.TypeAction
        
        self.messages?.addObject(msg)
        scrollToBottom()
    }
    
    private func removeTyping(username:String?) {
        for var index = self.messages!.count - 1; index >= 0; index-- {
            if let message = messages?.objectAtIndex(index) as? Message {
                if ((message.type == MessageType.TypeAction) && (message.userName == username)) {
                    self.messages?.removeObjectAtIndex(index)
                    
                    let indexPath = NSIndexPath(forRow: index, inSection: 0)
                    self.tblMessage.beginUpdates()
                    self.tblMessage.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)
                    self.tblMessage.endUpdates()
                }
            }
        }
    }
    
    private func attemptSend() {
        let message = tfMessage.text
        
        if !message!.isEmpty {
            self.tfMessage.text = ""
            addMessage(userName, message: message!)
            socket.emit("new message", message!)
        }
        
        self.tfMessage.becomeFirstResponder()
    }
    
    private func scrollToBottom() {
        let indexPath = NSIndexPath(forRow: self.messages!.count - 1, inSection: 0)
        tblMessage.beginUpdates()
        tblMessage.insertRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)
        tblMessage.endUpdates()
        tblMessage.scrollToRowAtIndexPath(indexPath, atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
    }
    
    private func getUsernameColor(username:String?) -> UIColor {
        var hash:Int! = 7
        
        for var index = 0, len = username!.length; index < len; index++ {
            let indexOfCharacter = username?.characters.startIndex.advancedBy(index);
            hash = (username?.characters[indexOfCharacter!].unicodeScalarCodePoint())! + (hash << 5) - hash
        }
        
        // Calculate color
        let index = abs(hash % usernameColors.count);
        return usernameColors[index]
    }
    
}

