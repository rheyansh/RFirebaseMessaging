//
//  MASharedMediaVC.swift
//  RMessaging
//
//  Created by rajkumar.sharma on 4/25/18.
//  Copyright © 2018 Raj Sharma. All rights reserved.
//

import UIKit

enum SharedMediaScreenType {
    case sharedMediaScreenType_Photos, sharedMediaScreenType_Videos
}

class MASharedMediaVC: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
        
        @IBOutlet weak var collectionView: UICollectionView!
        var screenType: SharedMediaScreenType = .sharedMediaScreenType_Photos
        var participantInfo: MAUser?
        var isHasMessages = false

        var mediaMessages = [Message]()

        //MARK:- UIViewController Life Cycle Method
        override func viewDidLoad() {
            super.viewDidLoad()
            
            loadData()
        }
        
        //MARK: Private functions
        private func loadData() {
            
            // Do any additional setup after loading the view, typically from a nib.
            
            if isHasMessages {
                // is coming from chat screen and has loaded messages
                // so ignore fetching again
                return
            }
            
            guard let participantInfo = self.participantInfo else {
                return
            }
            
            var mediaType: SharedMediaType = .mediaTypePhoto
            
            if self.screenType == .sharedMediaScreenType_Videos {
                mediaType = .mediaTypeVideo
            }
            
            participantInfo.getSharedMediaWithCurrentUser(mediaType: mediaType) { (sharedMediaResult) in
                
                if let error = sharedMediaResult.error {
                    TinyToast.shared.show(message: error.localizedDescription, duration: .normal)
                } else {
                    self.mediaMessages = sharedMediaResult.mediaMessages
                    self.collectionView.reloadData()
                }
            }
        }
        
        //MARK: UICollectionViewDataSource and Delegate Methods
        
        func numberOfSections(in collectionView: UICollectionView) -> Int {
            return 1
        }
        
        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int{
            return self.mediaMessages.count;
        }
        
        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            
            var cellId = "MASharedMediaVideoCollectionCell"
            
            if self.screenType == .sharedMediaScreenType_Photos {
                cellId = "MASharedMediaPhotoCollectionCell"
            }
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! MASharedMediaCollectionCell
            
            let message = self.mediaMessages[indexPath.row]
            
            if self.screenType == .sharedMediaScreenType_Videos {
                if let imageLink = message.videoThumbnail {
                    cell.photoImageView.normalLoad(imageLink)
                }
                
                cell.onPlayOptionButton = {
                    () -> Void in
                    if let url = URL(string: message.content as! String) {
                        if url.isValid {
                            let playerController = VideoPlayerController(nibName: "VideoPlayerController", bundle: nil)
                            playerController.modalTransitionStyle = .crossDissolve
                            self.navigationController?.pushViewController(playerController, animated: true)
                            playerController.loadUrl(url)
                        }
                    }
                }
                
            } else {
                if let imageLink = message.content as? String {
                    cell.photoImageView.normalLoad(imageLink)
                }
            }
            
            return cell
        }
        
        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            
            if self.screenType == .sharedMediaScreenType_Photos {
                let message = self.mediaMessages[indexPath.row]
                let cell = collectionView.cellForItem(at: indexPath) as? MASharedMediaCollectionCell
                if let imageLink = message.content as? String {
                    if let url = URL(string: imageLink) {
                        if url.isValid {
                            self.zoomImageIn(cell!.photoImageView)
                        }
                    }
                }
            }
        }
        
        func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            
            var width = self.collectionView.frame.size.width/4
            var height = width
            
            if self.screenType == .sharedMediaScreenType_Videos {
                width = self.collectionView.frame.size.width
                height = 110
            }
            
            return CGSize(width: width, height: height)
        }

        
        func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
            
            switch kind {
            case UICollectionElementKindSectionHeader:
                let reusableview = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "MACollectionHeaderView", for: indexPath) as! MACollectionHeaderView
                
                return reusableview
            default:  fatalError("Unexpected element kind")
            }
            
        }
        
        //MARK:- Memory handling
        
        override func didReceiveMemoryWarning() {
            super.didReceiveMemoryWarning()
            // Dispose of any resources that can be recreated.
        }
}


