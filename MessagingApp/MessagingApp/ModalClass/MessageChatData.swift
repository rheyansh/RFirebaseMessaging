//
//  MessageChatData.swift
//  RMessaging
//
//  Created by rajkumar.sharma on 4/25/18.
//  Copyright © 2018 Raj Sharma. All rights reserved.
//

import UIKit

class MessageChatData: NSObject {

    var chatListArray = [MessageChatData]()
     var strUserImage : String = ""
    var strMessageText : String = ""
    var strMessageTime : String = ""
    var isSelfMessage :Bool?

    class func getChatList(dict : Dictionary<String, Any>) -> MessageChatData {
        let obj = MessageChatData()
        let tempChatListArray = dict["chatList"]
        
        (tempChatListArray! as AnyObject).enumerateObjects { (chatDict, index, stop) in
            let chatListInfo = MessageChatData()
            let chatListDict = chatDict as! Dictionary<String, Any>
            chatListInfo.strUserImage = chatListDict.validatedValue("userImage", expected: "" as AnyObject) as! String
            chatListInfo.strMessageText = chatListDict.validatedValue("messageText", expected: "" as AnyObject) as! String
            chatListInfo.strMessageTime = chatListDict.validatedValue("messageTime", expected: "" as AnyObject) as! String
            chatListInfo.isSelfMessage = (chatListDict.validatedValue("isSelfMessage", expected: false as AnyObject) as? Bool)!
            obj.chatListArray.append(chatListInfo)
        }
        return obj
    }
}
