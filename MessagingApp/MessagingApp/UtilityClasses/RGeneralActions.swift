//
//  RGeneralActions.swift
//  RMessaging
//
//  Created by rajkumar.sharma on 4/25/18.
//  Copyright © 2018 Raj Sharma. All rights reserved.
//

import UIKit
import MessageUI

class RGeneralActions: NSObject, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate {

    static let action = RGeneralActions()
    
    typealias MailControllerDismissBlock = (()->())?
    private var mailControllerDismissBlock: MailControllerDismissBlock?
    
    typealias SMSControllerDismissBlock = (()->())?
    private var smsControllerDismissBlock: SMSControllerDismissBlock?

    func sendMail(recipients : [String] = [], subject :
        String = "", body : String = "", isHtml : Bool = false,
                     images : [UIImage]? = nil, block: MailControllerDismissBlock) ->Void {
        
        if recipients.count != 0 {
            if MFMailComposeViewController.canSendMail() {
                if let currentController = UIWindow.currentController {
                    mailControllerDismissBlock = block
                    
                    let mailComposerVC = MFMailComposeViewController()
                    mailComposerVC.mailComposeDelegate = self // IMPORTANT
                    
                    mailComposerVC.setToRecipients(recipients)
                    mailComposerVC.setSubject(subject)
                    mailComposerVC.setMessageBody(body, isHTML: isHtml)
                    
                    for img in images ?? [] {
                        if let jpegData = UIImageJPEGRepresentation(img, 1.0) {
                            mailComposerVC.addAttachmentData(jpegData,
                                                             mimeType: "image/jpg",
                                                             fileName: "Image")
                        }
                    }
                    currentController.present(mailComposerVC, animated: true, completion: nil)
                }
            } else {
                AlertController.alert(title: "Error!", message: "Your device could not send e-mail. Please check e-mail configuration and try again.")
            }
        } else {
            AlertController.alert(title: "Error!", message: "No recipient found.")
        }
    }
    
    // MARK:- - MFMailComposeViewControllerDelegate

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        
        switch (result) {
        case .cancelled:
            AlertController.alert(title: "Failed!", message: "You cancelled sending this email.")
        case .saved:
            AlertController.alert(title: "You saved a draft of this email.")
        case .sent:
            AlertController.alert(title: "Email sent.")
        case .failed:
            AlertController.alert(title: "Failed!", message: "Unable to send email. Please check your email settings and try again.")
        }
        
        if let dismissBlock = mailControllerDismissBlock {
            if let dismissBlock = dismissBlock {
                dismissBlock()
            }
        }
        
        controller.dismiss(animated: true, completion: nil)
    }

    func sendSMS(recipients : [String] = [], subject :
        String = "", body : String = "", block: SMSControllerDismissBlock) ->Void {
        
        if recipients.count != 0 {
            if MFMessageComposeViewController.canSendText() {
                if let currentController = UIWindow.currentController {
                    smsControllerDismissBlock = block
                    
                    let messageComposeVC = MFMessageComposeViewController()
                    messageComposeVC.messageComposeDelegate = self  //  Make sure to set this property to self, so that the controller can be dismissed!
                    messageComposeVC.recipients = recipients
                    messageComposeVC.subject = subject
                    messageComposeVC.body = body
                   
                    currentController.present(messageComposeVC, animated: true, completion: nil)
                }
            } else {
                AlertController.alert(title: "Cannot Send Text Message", message: "Your device is not able to send text messages.")
            }
        } else {
            AlertController.alert(title: "Cannot Send Text Message", message: "No recipient found.")
        }
    }
    
    // MARK:- MFMessageComposeViewControllerDelegate
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        
        switch (result) {
        case .cancelled:
            AlertController.alert(title: "Failed!", message: "You cancelled sending this message.")
        case .failed:
            AlertController.alert(title: "Message failed")
        case .sent:
            AlertController.alert(title: "Message sent")
        }
        
        if let dismissBlock = smsControllerDismissBlock {
            if let dismissBlock = dismissBlock {
                dismissBlock()
            }
        }
        controller.dismiss(animated: true, completion: nil)
    }
}

