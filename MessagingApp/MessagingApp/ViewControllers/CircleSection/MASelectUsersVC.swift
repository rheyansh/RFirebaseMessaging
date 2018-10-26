//
//  MASelectUsersVC.swift
//  RMessaging
//
//  Created by rajkumar.sharma on 4/25/18.
//  Copyright © 2018 Raj Sharma. All rights reserved.
//

import UIKit

enum SelectUsersScreenType {
    case SelectUsersScreenType_CreateGroup, SelectUsersScreenType_AddMemberInGroup
}

class MASelectUsersVC: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var nextButton: UIButton!
    
    var screenType: SelectUsersScreenType = .SelectUsersScreenType_CreateGroup
    var groupInfo: MAChatRoom?
    var friendsArray = [MAUser]()
    private var filteredArray = [MAUser]()
    private var sectionIndexTitles = [String]()
    private var alphabetizedDictionary = [String : Array<MAUser>]()
    private var isSearchActive = false

    typealias DidAddedNewParticipants = (_ arrayParticipants: Array<MAUser>) -> Void
    var onAddedNewParticipants: DidAddedNewParticipants?
    
    //MARK:- UIViewController life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        initialSetup()
    }
    
    //MARK:- Private functions
    
    private func initialSetup() {
        
        tableView.estimatedRowHeight = 68
        tableView.rowHeight = UITableViewAutomaticDimension
        searchBar.delegate = self
        
        if screenType == .SelectUsersScreenType_AddMemberInGroup {
            nextButton.setTitle("Add", for: .normal)
            
            guard let group = self.groupInfo else { return }
            
            FBFriendsServices.fetchMyFriends(callback: { (result) in
                
                if let error = result.error {
                    TinyToast.shared.show(message: error.localizedDescription, duration: .veryShort)
                } else {
                    self.isSearchActive = false
                    
                    var allFriends = [MAUser]()
                    
                    for user in result.users {
                        if group.participantsIds.contains(user.userId) {
                            // do nothing
                        } else {
                            allFriends.append(user)
                        }
                    }
                    
                    self.friendsArray = allFriends
                    self.reArrangeData()
                }
            })
            
        } else {
            reArrangeData()
        }
    }
    
    private func searchForText(_ text: String) {
        
        if text.trimWhiteSpace.length != 0 {
            isSearchActive = true
            filteredArray = friendsArray.filter { $0.fullName.contains(text.trimWhiteSpace) }
            self.tableView.reloadData()
        } else {
            isSearchActive = false
            self.tableView.reloadData()
        }
    }
    
    private func reArrangeData() {
        self.filteredArray = self.friendsArray
        reArrangeAlphabetizedDictionary(self.friendsArray)
        self.tableView.reloadData()
    }
    
    private func reArrangeAlphabetizedDictionary(_ array: Array<MAUser>) {
        let modifiedData = self.getAlphabetical(array)
        self.alphabetizedDictionary = modifiedData.alphabetizedDictionary
        self.sectionIndexTitles = modifiedData.sectionIndexTitles
    }
    
    //MARK:- IBActions
    
    @IBAction func onBackButtonAction(_ sender: UIButton) {
        self.view.endEditing(true)
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func onNextButtonAction(_ sender: UIButton) {
        self.view.endEditing(true)
        
        let selectedUsers = friendsArray.filter{ $0.selectionStatus == true }
        
        if selectedUsers.count == 0 {
            AlertController.alert(title: "At least one friend must be selected")
        } else {
            
            if screenType == .SelectUsersScreenType_AddMemberInGroup {
                guard let group = self.groupInfo else { return }
                
                group.addParticipants(nwParticipants: selectedUsers, callback: { (isSuccess, error) in
                    
                    if let error = error {
                        TinyToast.shared.show(message: error.localizedDescription, duration: .veryShort)
                    } else {
                        if isSuccess {
                            TinyToast.shared.show(message: "Added successfully", duration: .veryShort)
                            
                            if let onAddedNewParticipants = self.onAddedNewParticipants {
                                onAddedNewParticipants(selectedUsers)
                            }
                            self.navigationController?.popViewController(animated: true)
                        }
                    }
                })
                
            } else {
                let createGroupVC = circleSectionStoryboard.instantiateViewController(withIdentifier: "MACreateGroupVC") as! MACreateGroupVC
                createGroupVC.selectedUsers = selectedUsers
                self.navigationController?.pushViewController(createGroupVC, animated: true)
            }
            
//            let createGroupVc = NewGroupVc(nibName: "NewGroupVc", bundle: nil)
//            createGroupVc.groupCount = self.mainArray.count
//            self.navigationController?.pushViewController(createGroupVc, animated: true)
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
            cell.statusButton.isSelected = user.selectionStatus
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if isSearchActive {
            
            let user = filteredArray[indexPath.row]
            let updatedStatus = !user.selectionStatus
            filteredArray[indexPath.row].selectionStatus = updatedStatus
            // now update the main array and alphabetizedDictionary
            
            if let index = self.friendsArray.index(where: {$0.userId == user.userId}) {
                self.friendsArray[index].selectionStatus = updatedStatus
                reArrangeAlphabetizedDictionary(self.friendsArray)
            }
            
            tableView.reloadData()
        } else {
            let sectionIndexTitle = sectionIndexTitles[indexPath.section]
            if var arraySubData = alphabetizedDictionary[sectionIndexTitle] {
                let user = arraySubData[indexPath.row]
                let updatedStatus = !user.selectionStatus
                arraySubData[indexPath.row].selectionStatus = updatedStatus
                
                // now update the main array and filteredArray
                if let index = self.filteredArray.index(where: {$0.userId == user.userId}) {
                    self.filteredArray[index].selectionStatus = updatedStatus
                }
                
                // now update the main array and filteredArray
                if let index = self.friendsArray.index(where: {$0.userId == user.userId}) {
                    self.friendsArray[index].selectionStatus = updatedStatus
                    reArrangeAlphabetizedDictionary(self.friendsArray)
                }
                tableView.reloadData()
            }
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
        searchForText("")
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        Debug.log("textDidChange \(searchText)")
        searchForText(searchText)
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

