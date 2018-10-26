//
//  MARequestListVC.swift
//  RMessaging
//
//  Created by rajkumar.sharma on 4/25/18.
//  Copyright © 2018 Raj Sharma. All rights reserved.
//

import UIKit

class MARequestListVC: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!

    var sectionIndexTitles = [String]()
    var mainArray = [MAUser]()
    var filteredArray = [MAUser]()

    var alphabetizedDictionary = [String : Array<MAUser>]()
    var refreshControl: UIRefreshControl!
    var isSearchActive = false

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
    
    //MARK:- private functions
    
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
        friendBaseVC.requestsReceivedBadgeCount = value
    }
    
    private func fetchListFromFireBase() {
       
        FBFriendsServices.fetchFriends(friendshipStatus: .friendshipStatusRequestsReceived) { (result) in
            if let error = result.error {
                TinyToast.shared.show(message: error.localizedDescription, duration: .veryShort)
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
    
    private func avatarTapAction(cell: MAFriendRequestCell, itemInfo: MAUser) {
        self.view.endEditing(true)
        if let url = URL(string: itemInfo.avatarUrl) {
            if url.isValid {
                self.zoomImageIn(cell.avatar)
            }
        }
    }
    
    private func rejectFriendRequest(_ user: MAUser, _ cell: MAFriendRequestCell) {
        
        //self.view.endEditing(true)
        cell.startLoader = true
        
        FBFriendsServices.rejectFriendRequest(fromUser: user, callback: { (isSuccess, error) in
            cell.startLoader = false
            if isSuccess {
                let message = "You have rejected request from \(user.fullName)"
                TinyToast.shared.show(message: message, duration: .veryShort)
                
                if let index = self.mainArray.index(where: {$0.userId == user.userId}) {
                    self.mainArray.remove(at: index)
                    self.reArrangeData()
                }
            }
        })
    }
    
    private func acceptFriendRequest(_ user: MAUser, _ cell: MAFriendRequestCell) {
        
        cell.startLoader = true
        
        FBFriendsServices.acceptFriendRequest(fromUser: user, callback: { (isSuccess, error) in
            cell.startLoader = false
            if isSuccess {
                let message = "You have accepted request from \(user.fullName)"
                TinyToast.shared.show(message: message, duration: .veryShort)
                if let index = self.mainArray.index(where: {$0.userId == user.userId}) {
                    self.mainArray.remove(at: index)
                    self.reArrangeData()
                }
            }
        })
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
        
        let cell:MAFriendRequestCell = tableView.dequeueReusableCell(withIdentifier: "MAFriendRequestCell", for: indexPath) as! MAFriendRequestCell

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
            cell.enableAvatarZoomIn = true

            cell.titleLabel.text = user.fullName
            cell.avatar.userLoad(user.avatarUrl)
            
            cell.onRejectButton = {
                () -> Void in
                self.rejectFriendRequest(user, cell)
            }
            
            cell.onAcceptButton = {
                () -> Void in
                self.acceptFriendRequest(user, cell)
            }
            
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
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        if isSearchActive {
            return nil
        } else {
            let cell:MAFriendRequestCell = tableView.dequeueReusableCell(withIdentifier: "MAFriendRequestHeaderCell") as! MAFriendRequestCell
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
