//
//  MAFriendBaseVC.swift
//  RMessaging
//
//  Created by rajkumar.sharma on 4/25/18.
//  Copyright © 2018 Raj Sharma. All rights reserved.
//

import UIKit

class MAFriendBaseVC: UIViewController, UISearchBarDelegate, CarbonTabSwipeNavigationDelegate {

    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var requestedBadgeLabel: UILabel!
    @IBOutlet weak var requestsBadgeLabel: UILabel!
    @IBOutlet weak var containerView: UIView!
    
    var pageVC: CarbonTabSwipeNavigation!
    var friendListVC: MAFriendListVC!
    var sentRequestListVC: MAFriendListVC!
    var requestReceivedListVC: MARequestListVC!
    var contactListVC: MAContactListVC!

    var requestsReceivedBadgeCount: Int?  {
        didSet {
            requestsBadgeLabel.isHidden = true
            
            guard let badgeCount = requestsReceivedBadgeCount else {
                return
            }
            
            if badgeCount > 0 {
                requestsBadgeLabel.isHidden = false
                if badgeCount > 99 {
                    self.requestsBadgeLabel.text = "99+"
                    return
                }
                self.requestsBadgeLabel.text = "\(badgeCount)"
                self.requestsBadgeLabel.isHidden = false
            } else {
                self.requestsBadgeLabel.isHidden = true
            }
        }
    }
    
    var requestsSentBadgeCount: Int?  {
        didSet {
            requestedBadgeLabel.isHidden = true
            
            guard let badgeCount = requestsSentBadgeCount else {
                return
            }
            
            if badgeCount > 0 {
                requestedBadgeLabel.isHidden = false
                if badgeCount > 99 {
                    self.requestedBadgeLabel.text = "99+"
                    return
                }
                self.requestedBadgeLabel.text = "\(badgeCount)"
                self.requestedBadgeLabel.isHidden = false
            } else {
                self.requestedBadgeLabel.isHidden = true
            }
        }
    }
    
    //MARK:- UIViewController life cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        initialSetup()
    }

    //MARK:- private functions

    private func initialSetup() {
        requestsSentBadgeCount = 0
        requestsReceivedBadgeCount = 0
        searchBar.delegate = self
        
        let friendTabButton = view.viewWithTag(100) as? UIButton
        friendTabButton?.isSelected = true

        friendListVC = friendsSectionStoryboard.instantiateViewController(withIdentifier: "MAFriendListVC") as! MAFriendListVC
        friendListVC.screenType = .friendListScreenType_Friends

        sentRequestListVC = friendsSectionStoryboard.instantiateViewController(withIdentifier: "MAFriendListVC") as! MAFriendListVC
        sentRequestListVC.screenType = .friendListScreenType_RequestsSents
        
        requestReceivedListVC = friendsSectionStoryboard.instantiateViewController(withIdentifier: "MARequestListVC") as! MARequestListVC
        
        contactListVC = friendsSectionStoryboard.instantiateViewController(withIdentifier: "MAContactListVC") as! MAContactListVC

        setUpContainer()
    }
    
    func dismissKeyboard() {
        searchBar.resignFirstResponder()
    }
    
    private func setUpContainer() {
        
        let arrayItems = ["", "", "", ""]
        
        // add more items if you wants to make scrollable segments is self.arrayItems. Also you can add ([UIImage imageNamed:@"hourglass"]) abject i array. If it is image object than segment tab will be image & if it is only string than it is Sgment tab will show text.
        
        pageVC = CarbonTabSwipeNavigation(items: arrayItems, delegate: self)
        self.pageVC.view.frame = containerView.bounds
        containerView.addSubview(self.pageVC.view)
        self.addChildViewController(self.pageVC)
        
        //let color = UIColor.white
        
        //self.pageVC.setNormalColor(RGBA(r: 143, g: 201, b: 247, a: 1))
        self.pageVC.setIndicatorHeight(0)
        self.pageVC.setTabBarHeight(0)
        let tabWidth = CGFloat(view.frame.size.width/CGFloat(arrayItems.count))
        
        self.pageVC.carbonSegmentedControl?.setWidth(tabWidth, forSegmentAt: 0)
        self.pageVC.carbonSegmentedControl?.setWidth(tabWidth, forSegmentAt: 1)
        self.pageVC.carbonSegmentedControl?.setWidth(tabWidth, forSegmentAt: 2)
        self.pageVC.carbonSegmentedControl?.setWidth(tabWidth, forSegmentAt: 3)

//        self.pageVC.carbonSegmentedControl?.backgroundColor = UIColor.red
//        self.pageVC.setSelectedColor(color)
//        self.pageVC.setIndicatorColor(color)
        self.pageVC.pagesScrollView?.isScrollEnabled = false
    }
    
    //MARK:- IBActions

    @IBAction func onBackButtonAction(_ sender: Any) {
        self.view.endEditing(true)
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func onNextButtonAction(_ sender: UIButton) {
        self.view.endEditing(true)
    }
    
    @IBAction func headerButtonAction(_ sender: UIButton) {
        self.view.endEditing(true)
        
        let friendTabButton = view.viewWithTag(100) as? UIButton
        let friendRequestsTabButton = view.viewWithTag(101) as? UIButton
        let friendSentRequestsTabButton = view.viewWithTag(102) as? UIButton
        let inviteesTabButton = view.viewWithTag(103) as? UIButton
        friendTabButton?.isSelected = false
        friendRequestsTabButton?.isSelected = false
        friendSentRequestsTabButton?.isSelected = false
        inviteesTabButton?.isSelected = false

        var indexToMove: UInt = 0
        
        switch sender.tag {
        case 100:
            friendTabButton?.isSelected = true
            indexToMove = 0
            break
        case 101:
            friendRequestsTabButton?.isSelected = true
            indexToMove = 1
            break
        case 102:
            friendSentRequestsTabButton?.isSelected = true
            indexToMove = 2
            break
        case 103:
            inviteesTabButton?.isSelected = true
            indexToMove = 3
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
            return requestReceivedListVC
        case 2:
            return sentRequestListVC
            
        case 3:
            return contactListVC

        default:
            return friendListVC
        }
    }
    
    func carbonTabSwipeNavigation(_ carbonTabSwipeNavigation: CarbonTabSwipeNavigation, willMoveAt index: UInt) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
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
    
    // MARK:- --->UISearchBar Delegate

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        Debug.log("searchBarTextDidBeginEditing \(String(describing: searchBar.text))")
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        Debug.log("searchBarTextDidEndEditing \(String(describing: searchBar.text))")
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        passSearchTextToChildControllers("")
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        Debug.log("textDidChange \(searchText)")
        passSearchTextToChildControllers(searchText)
    }
    
    private func passSearchTextToChildControllers(_ text: String) {
        
        switch pageVC.currentTabIndex {
            
        case 0: friendListVC.searchForText(text)
            break
            
        case 1: requestReceivedListVC.searchForText(text)
            break
            
        case 2: sentRequestListVC.searchForText(text)
            break
            
        case 3: contactListVC.searchForText(text)
            break

        default:
            break
        }
    }
    
    private func passSearchStatusToChildControllers(_ isSearchActive: Bool) {
        
        switch pageVC.currentTabIndex {
            
        case 0: friendListVC.isSearchActive = isSearchActive
            break
            
        case 1: requestReceivedListVC.isSearchActive = isSearchActive
            break
            
        case 2: sentRequestListVC.isSearchActive = isSearchActive
            break
            
        case 3: contactListVC.isSearchActive = isSearchActive
            break
            
        default:
            break
        }
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
