//
//  MASharedMediaBaseVC.swift
//  RMessaging
//
//  Created by rajkumar.sharma on 4/25/18.
//  Copyright © 2018 Raj Sharma. All rights reserved.
//

import UIKit

class MASharedMediaBaseVC: UIViewController, CarbonTabSwipeNavigationDelegate {
    
    @IBOutlet weak var selectButton: UIButton!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var photosButton: UIButton!
    @IBOutlet weak var videosButton: UIButton!
    
    var pageVC: CarbonTabSwipeNavigation!
    var sharedPhotosVC: MASharedMediaVC!
    var sharedVideosVC: MASharedMediaVC!
    
    var participantInfo: MAUser?
    var loadedMessages = [Message]()
    var isHasMessages = false

    //MARK:- UIViewController life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        initialSetup()
    }
    
    //MARK:- private functions
    
    private func initialSetup() {

        let photoMessages = self.loadedMessages.filter({ return $0.type == .photo})
        let videoMessages = self.loadedMessages.filter({ return $0.type == .video})

        sharedPhotosVC = sharedMediaSectionStoryboard.instantiateViewController(withIdentifier: "MASharedMediaVC") as! MASharedMediaVC
        sharedPhotosVC.screenType = .sharedMediaScreenType_Photos
        sharedPhotosVC.participantInfo = participantInfo
        sharedPhotosVC.isHasMessages = isHasMessages
        sharedPhotosVC.mediaMessages = photoMessages

        sharedVideosVC = sharedMediaSectionStoryboard.instantiateViewController(withIdentifier: "MASharedMediaVC") as! MASharedMediaVC
        sharedVideosVC.screenType = .sharedMediaScreenType_Videos
        sharedVideosVC.participantInfo = participantInfo
        sharedVideosVC.isHasMessages = isHasMessages
        sharedVideosVC.mediaMessages = videoMessages

        setUpContainer()
    }
    
    private func setUpContainer() {
        
        let photosTabButton = view.viewWithTag(100) as? UIButton
        photosTabButton?.backgroundColor = kAppColor
        photosTabButton?.setTitleColor(UIColor.white, for: .normal)

        let arrayItems = ["", ""]
        
        // add more items if you wants to make scrollable segments is self.arrayItems. Also you can add ([UIImage imageNamed:@"hourglass"]) abject i array. If it is image object than segment tab will be image & if it is only string than it is Sgment tab will show text.
        
        pageVC = CarbonTabSwipeNavigation(items: arrayItems, delegate: self)
        self.pageVC.view.frame = containerView.bounds
        containerView.addSubview(self.pageVC.view)
        self.addChildViewController(self.pageVC)
        
        self.pageVC.setIndicatorHeight(0)
        self.pageVC.setTabBarHeight(0)
        let tabWidth = CGFloat(view.frame.size.width/CGFloat(arrayItems.count))
        
        self.pageVC.carbonSegmentedControl?.setWidth(tabWidth, forSegmentAt: 0)
        self.pageVC.carbonSegmentedControl?.setWidth(tabWidth, forSegmentAt: 1)
        self.pageVC.pagesScrollView?.isScrollEnabled = false
    }
    
    //MARK:- IBActions
    
    @IBAction func onBackButtonAction(_ sender: Any) {
        self.view.endEditing(true)
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func onSelectButtonAction(_ sender: Any) {
        self.view.endEditing(true)
    }
    
    @IBAction func headerButtonAction(_ sender: UIButton) {
        self.view.endEditing(true)
        
        let photosTabButton = view.viewWithTag(100) as? UIButton
        let videosTabButton = view.viewWithTag(101) as? UIButton
        
        photosTabButton?.backgroundColor = UIColor.white
        videosTabButton?.backgroundColor = UIColor.white
        photosTabButton?.setTitleColor(UIColor.black, for: .normal)
        videosTabButton?.setTitleColor(UIColor.black, for: .normal)

        var indexToMove: UInt = 0
        
        switch sender.tag {
        case 100:
            photosTabButton?.backgroundColor = kAppColor
            photosTabButton?.setTitleColor(UIColor.white, for: .normal)
            indexToMove = 0
            break
        case 101:
            videosTabButton?.backgroundColor = kAppColor
            videosTabButton?.setTitleColor(UIColor.white, for: .normal)
            indexToMove = 1
            break
        default:
            break
        }
        
        if pageVC.currentTabIndex != indexToMove {
            pageVC.setCurrentTabIndex(indexToMove, withAnimation: false)
        }
    }
    
    //MARK:- CarbonTabSwipeNavigation
    func carbonTabSwipeNavigation(_ carbonTabSwipeNavigation: CarbonTabSwipeNavigation, viewControllerAt index: UInt) -> UIViewController {

        switch index {
        case 1:
            return sharedVideosVC
        default:
            return sharedPhotosVC
        }
    }
    
    func carbonTabSwipeNavigation(_ carbonTabSwipeNavigation: CarbonTabSwipeNavigation, willMoveAt index: UInt) {
        //Debug.log(">> \(index)")
    }
    
    func carbonTabSwipeNavigation(_ carbonTabSwipeNavigation: CarbonTabSwipeNavigation, didMoveAt index: UInt) {
        //Debug.log(">> \(index)")
        
    }
    
    func carbonTabSwipeNavigation(_ carbonTabSwipeNavigation: CarbonTabSwipeNavigation, didFinishTransitionTo index: UInt) {
        //Debug.log(">> \(index)")
    }
    
    func barPosition(for carbonTabSwipeNavigation: CarbonTabSwipeNavigation) -> UIBarPosition {
        return .top
    }
    
    // MARK:- --->UIResponder function
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    //MARK:- Memory handling
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
