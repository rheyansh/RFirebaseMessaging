//
//  MAFriendListVC.swift
//  RMessaging
//
//  Created by rajkumar.sharma on 4/25/18.
//  Copyright © 2018 Raj Sharma. All rights reserved.
//

import UIKit

enum FriendListScreenType {
    case friendListScreenType_Friends, friendListScreenType_RequestsSents
}

class MAFriendListVC: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!

    var screenType: FriendListScreenType = .friendListScreenType_Friends
    var mainArray = [MAUser]()
    var filteredArray = [MAUser]()
    var isSearchActive = false
    var sectionIndexTitles = [String]()
    var alphabetizedDictionary = [String : Array<MAUser>]()
    var refreshControl: UIRefreshControl!
    
    //MARK:- UIViewController life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        initialSetup()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isSearchActive = false
        self.tableView.reloadData()
    }
    
    //MARK:- Public functions
    
    func searchForText(_ text: String) {
        
        if text.trimWhiteSpace.length != 0 {
            isSearchActive = true
            filteredArray = mainArray.filter { $0.fullName.contains(text.trimWhiteSpace) }
            self.tableView.reloadData()
        } else {
            isSearchActive = false
            self.tableView.reloadData()
        }
    }

    //MARK:- Private functions
    
    private func initialSetup() {
        
        tableView.estimatedRowHeight = 68
        tableView.rowHeight = UITableViewAutomaticDimension
        
        addFreshControl()
        loadPage()
    }
    
    private func addFreshControl() {
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(onRefresh), for: .valueChanged)
        tableView.addSubview(refreshControl) // not required when using UITableViewController
    }
    
    @objc func onRefresh(_ sender: Any) {
        loadPage()
        delay(delay: 0.1) {
            self.refreshControl.endRefreshing()
        }
    }
    
    private func loadPage() {
        fetchListFromFireBase()
    }
    
    private func updateBadgeCount(value: Int?) {
        guard let friendBaseVC = self.parent?.parent?.parent as? MAFriendBaseVC else {
            return
        }
        if screenType == .friendListScreenType_RequestsSents {
            friendBaseVC.requestsSentBadgeCount = value
        }
    }
    
    private func fetchListFromFireBase() {
        
        var friendshipStatus: FriendshipStatus = .friendshipStatusRequestsSent
        
        if screenType == .friendListScreenType_RequestsSents {
            friendshipStatus = .friendshipStatusRequestsSent
        } else if screenType == .friendListScreenType_Friends {
            friendshipStatus = .friendshipStatusAccepted
        } else {
            return
        }
        
        FBFriendsServices.fetchFriends(friendshipStatus: friendshipStatus) { (result) in
            if let error = result.error {
                TinyToast.shared.show(message: error.localizedDescription, duration: .normal)
            } else {
                self.isSearchActive = false
                self.mainArray = result.users
                self.reArrangeData()
            }
        }
        
        guard let friendBaseVC = self.parent?.parent?.parent as? MAFriendBaseVC else {
            return
        }
        friendBaseVC.searchBar.text = ""
        friendBaseVC.dismissKeyboard()
    }
    
    private func reArrangeData() {
        self.filteredArray = self.mainArray
        self.updateBadgeCount(value: self.mainArray.count)
        let modifiedData = self.getAlphabetical(self.mainArray)
        self.alphabetizedDictionary = modifiedData.alphabetizedDictionary
        self.sectionIndexTitles = modifiedData.sectionIndexTitles
        self.tableView.reloadData()
    }
    
    private func avatarTapAction(cell: MASubTitleAvtarCell, itemInfo: MAUser) {
        self.view.endEditing(true)
        if let url = URL(string: itemInfo.avatarUrl) {
            if url.isValid {
                self.zoomImageIn(cell.avatar)
            }
        }
    }
    
    //MARK:- UITableView
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        if isSearchActive {
            return 1
        } else {
            return sectionIndexTitles.count
        }
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return max(68, UITableViewAutomaticDimension)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if isSearchActive {
            return filteredArray.count
        } else {
            let sectionIndexTitle = sectionIndexTitles[section]
            return alphabetizedDictionary[sectionIndexTitle]!.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell:MASubTitleAvtarCell = tableView.dequeueReusableCell(withIdentifier: "MASubTitleAvtarCell", for: indexPath) as! MASubTitleAvtarCell
        
        var userToLoad: MAUser?
        
        if isSearchActive {
            userToLoad = filteredArray[indexPath.row]
        } else {
            let sectionIndexTitle = sectionIndexTitles[indexPath.section]
            if let arraySubData = alphabetizedDictionary[sectionIndexTitle] {
                userToLoad = arraySubData[indexPath.row]
            }
        }

        if let user = userToLoad {
            cell.titleLabel.text = user.fullName
            cell.avatar.userLoad(user.avatarUrl)
            cell.enableAvatarZoomIn = true
            
            cell.onTapAvatar = {
                (tappedImageView) -> Void in
                self.avatarTapAction(cell: cell, itemInfo: user)
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard let friendBaseVC = self.parent?.parent?.parent as? MAFriendBaseVC else {
            return
        }
        friendBaseVC.dismissKeyboard()
        
        var userToLoad: MAUser?
        
        if isSearchActive {
            userToLoad = filteredArray[indexPath.row]
        } else {
            let sectionIndexTitle = sectionIndexTitles[indexPath.section]
            if let arraySubData = alphabetizedDictionary[sectionIndexTitle] {
                userToLoad = arraySubData[indexPath.row]
            }
        }
        
        if let user = userToLoad {
            let chatVC = chatSectionStoryboard.instantiateViewController(withIdentifier: "ChatVC") as! ChatVC
            chatVC.participant = user
            self.navigationController?.pushViewController(chatVC, animated: true)
        }
    }
  
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        if isSearchActive {
            return nil
        } else {
            let cell:MASubTitleAvtarCell = tableView.dequeueReusableCell(withIdentifier: "MASubTitleAvtarHeaderCell") as! MASubTitleAvtarCell
            cell.titleLabel.text = sectionIndexTitles[section]

            return cell.contentView
        }
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        
        if isSearchActive {
            return nil
        } else {
            return sectionIndexTitles
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if isSearchActive {
            return 0
        } else {
            return 28
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        var userToRespond: MAUser?
        
        if isSearchActive {
            userToRespond = filteredArray[indexPath.row]
        } else {
            let sectionIndexTitle = sectionIndexTitles[indexPath.section]
            if let arraySubData = alphabetizedDictionary[sectionIndexTitle] {
                userToRespond = arraySubData[indexPath.row]
            }
        }
        
        if let user = userToRespond {
            
            var buttonTitle = "Unfriend"
            var completionMessage = "\(user.fullName) is no longer in your friend list"

            if screenType == .friendListScreenType_RequestsSents {
                buttonTitle = "Cancel"
                completionMessage = "You have cancelled friend request from \(user.fullName)"
            } else if screenType == .friendListScreenType_Friends {
                // message will remain same
            } else {
                return []
            }
            
            let deleteAction = UITableViewRowAction(style: .default, title: buttonTitle) { (action, indexPath) in
                
                FBFriendsServices.deleteFriendNode(nodeKey: user.parentKey, callback: { (isSuccess, error) in
                    
                    if let error = error {
                        TinyToast.shared.show(message: error.localizedDescription, duration: .veryShort)
                    } else {
                        if isSuccess {
                            TinyToast.shared.show(message: completionMessage, duration: .veryShort)
                            if let index = self.mainArray.index(where: {$0.userId == user.userId}) {
                                self.mainArray.remove(at: index)
                                self.reArrangeData()
                            }
                        }
                    }
                })
            }
            
            return [deleteAction]
        }
        
        return []
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
