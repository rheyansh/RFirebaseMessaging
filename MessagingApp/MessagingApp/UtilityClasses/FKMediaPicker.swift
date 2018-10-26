//
//  FKMediaPicker.swift
//  RMessaging
//
//  Created by rajkumar.sharma on 4/25/18.
//  Copyright © 2018 Raj Sharma. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import MobileCoreServices

class FKMediaPicker: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    static let mediaPicker = FKMediaPicker()
    
    typealias DidFinishPickingMediaBlock = (_ info: [String : Any], _ pickedImage: UIImage?) -> Void
    private var finishedPickingMediaWithInfo: DidFinishPickingMediaBlock?
    
    typealias DidCancelledPickingMediaBlock = () -> Void
    var cancelledPickingMediaBlock: DidCancelledPickingMediaBlock?
    
    func pickImageFromDevice(_ imageBlock: @escaping DidFinishPickingMediaBlock) ->Void {
        
        if let currentController = UIWindow.currentController {
            finishedPickingMediaWithInfo = imageBlock
            
            AlertController.actionSheet(title: "", message: "Please select", sourceView: currentController.view, buttons: ["Take Photo", "Choose from gallery", "Cancel"]) { (action, index) in
                
                if index == 0 {
                    
                    self.pickMediaFromCamera(cameraBlock: { (info: [String : Any], pickedImage: UIImage?) in
                        imageBlock(info, pickedImage)
                    })
                    
                } else if index == 1 {
                    
                    self.pickMediaFromGallery(galleryBlock: { (info: [String : Any], pickedImage: UIImage?) in
                        imageBlock(info, pickedImage)
                    })
                }
            }
        }
    }
    
    func pickMediaFromCamera(_ isVideo: Bool = false,cameraBlock: @escaping DidFinishPickingMediaBlock) ->Void {
        
        finishedPickingMediaWithInfo = cameraBlock
        
        if (UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera)) {
            
            let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
            if (status == .authorized || status == .notDetermined) {
                if let currentController = UIWindow.currentController {
                    let imagePicker = UIImagePickerController()
                    imagePicker.sourceType = .camera
                    imagePicker.delegate = self
                    imagePicker.allowsEditing = true
                    
                    if isVideo {
                        imagePicker.mediaTypes = [kUTTypeMovie as String]
                        imagePicker.videoQuality = .typeLow
                    }
                    
                    currentController.present(imagePicker, animated: true, completion: nil)
                }
            }
        } else {
            pickMediaFromGallery(galleryBlock: { (info: [String : Any], pickedImage: UIImage?) in
                cameraBlock(info, pickedImage)
            })
        }
    }
    
    func pickMediaFromGallery(_ isVideo: Bool = false, galleryBlock: @escaping DidFinishPickingMediaBlock) {
        
        let status = PHPhotoLibrary.authorizationStatus()
        if (status == .authorized || status == .notDetermined) {
            if let currentController = UIWindow.currentController {
                finishedPickingMediaWithInfo = galleryBlock
                let imagePicker = UIImagePickerController()
                imagePicker.sourceType = .savedPhotosAlbum
                imagePicker.delegate = self
                imagePicker.allowsEditing = true
                
                if isVideo {
                    imagePicker.mediaTypes = [kUTTypeMovie as String]
                }
                
                currentController.present(imagePicker, animated: true, completion: nil)
            }
        }
    }
    
    // MARK:- - image picker delegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        let image = info[UIImagePickerControllerOriginalImage] as? UIImage
        
        if let finishedPickingMediaWithInfo = finishedPickingMediaWithInfo {
            finishedPickingMediaWithInfo(info, image)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
        
        if let cancelledPickingMediaBlock = cancelledPickingMediaBlock {
            cancelledPickingMediaBlock()
        }
    }
    
    func pickVideoFromDevice(_ videoBlock: @escaping DidFinishPickingMediaBlock) ->Void {
        
        if let currentController = UIWindow.currentController {
            finishedPickingMediaWithInfo = videoBlock
            
            AlertController.actionSheet(title: "", message: "Please select", sourceView: currentController.view, buttons: ["Record Video", "Choose from gallery", "Cancel"]) { (action, index) in
                
                if index == 0 {
                    
                    self.pickMediaFromCamera(true, cameraBlock: { (info: [String : Any], pickedImage: UIImage?) in
                        videoBlock(info, pickedImage)
                    })
                    
                } else if index == 1 {
                    
                    self.pickMediaFromGallery(true, galleryBlock: { (info: [String : Any], pickedImage: UIImage?) in
                        videoBlock(info, pickedImage)
                    })
                }
            }
        }
    }
}
