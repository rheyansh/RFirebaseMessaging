//
//  MANewCircleVC.swift
//  RMessaging
//
//  Created by rajkumar.sharma on 4/25/18.
//  Copyright © 2018 Raj Sharma. All rights reserved.
//

import UIKit

class MANewCircleVC: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var createNewGroupButton: UIButton!
    
    private var mainArray = [MAUser]()
    private var filteredArray = [MAUser]()
    private var sectionIndexTitles = [String]()
    private var alphabetizedDictionary = [String : Array<MAUser>]()
    var isSearchActive = false

    //MARK:- UIViewController life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        initialSetup()
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
        searchBar.delegate = self

        loadPage()
    }
    
    private func loadPage() {
        fetchListFromFireBase()
    }
    
    private func fetchListFromFireBase() {
        
        FBFriendsServices.fetchFriends(friendshipStatus: .friendshipStatusAccepted) { (result) in
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
        let modifiedData = self.getAlphabetical(self.mainArray)
        self.alphabetizedDictionary = modifiedData.alphabetizedDictionary
        self.sectionIndexTitles = modifiedData.sectionIndexTitles
        self.tableView.reloadData()
    }
    
    //MARK:- IBActions
    
    @IBAction func onBackButtonAction(_ sender: UIButton) {
        self.view.endEditing(true)
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func onCreateNewGroupButtonAction(_ sender: UIButton) {
        self.view.endEditing(true)
        
        
        if self.mainArray.count == 0 {
            AlertController.alert(title: "You have no friend to add.")
        } else {
            let selectUsersVC = circleSectionStoryboard.instantiateViewController(withIdentifier: "MASelectUsersVC") as! MASelectUsersVC
            selectUsersVC.friendsArray = self.mainArray
            self.navigationController?.pushViewController(selectUsersVC, animated: true)
        }

//        let groupVC = NewGroupCreateVC(nibName: "NewGroupCreateVC", bundle: nil)
//        self.navigationController?.pushViewController(groupVC, animated: true)
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
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.view.endEditing(true)
        
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
