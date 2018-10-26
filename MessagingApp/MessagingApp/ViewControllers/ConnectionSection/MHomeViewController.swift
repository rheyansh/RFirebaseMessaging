//
//  MHomeViewController.swift
//  RMessaging
//
//  Created by rajkumar.sharma on 4/25/18.
//  Copyright © 2018 Raj Sharma. All rights reserved.
//

import UIKit

class MHomeViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UISearchBarDelegate {

    @IBOutlet weak var heightLayoutConstraintSerachBGView: NSLayoutConstraint!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var collectionView: UICollectionView!
    var connectionList = [MAChatRoom]()
    var filteredList = [MAChatRoom]()

    //MARK:- UIViewController Life Cycle Method
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData()
    }
    
    //MARK: Private functions
    private func loadData() {
        
        FBChatRoomServices.fetchMyGroups { (result) in
            
            if let error = result.error {
                AlertController.alert(title: error.localizedDescription)
            } else {
                self.connectionList = result.groups
                self.filteredList = self.connectionList
                self.collectionView.reloadData()
            }
        }
    }
    
    //MARK:- IBActions
   
    @IBAction func onPlusButtonAction(_ sender: UIButton) {
        self.view.endEditing(true)
        
        let nwCircleVC = circleSectionStoryboard.instantiateViewController(withIdentifier: "MANewCircleVC") as! MANewCircleVC
        self.navigationController?.pushViewController(nwCircleVC, animated: true)
    }
    
    @IBAction func onUserButtonAction(_ sender: UIButton) {
        
        let friendBaseVC = friendsSectionStoryboard.instantiateViewController(withIdentifier: "MAFriendBaseVC") as! MAFriendBaseVC
        self.navigationController?.pushViewController(friendBaseVC, animated: true)
    }
    
    //MARK: UICollectionViewDataSource and Delegate Methods
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int{
        return filteredList.count;
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MHomeCollectionViewCell", for: indexPath) as! MHomeCollectionViewCell

        let group = filteredList[indexPath.row]
        
        cell.badgeCount = UInt(group.participantsIds.count)

        cell.titleLabel.text = group.chatRoomName
        cell.avatar.normalLoad(group.avatarUrl)

        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        self.view.endEditing(true)

        let group = filteredList[indexPath.row]

        let chatVC = chatSectionStoryboard.instantiateViewController(withIdentifier: "ChatVC") as! ChatVC
        chatVC.chatRoom = group
        self.navigationController?.pushViewController(chatVC, animated: true)
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: self.collectionView.frame.size.width/3, height: 166)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
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

    private func searchForText(_ text: String) {
        
        if text.trimWhiteSpace.length != 0 {
            filteredList = connectionList.filter { $0.chatRoomName.contains(text.trimWhiteSpace) }
            self.collectionView.reloadData()
        } else {
            filteredList = connectionList
            self.collectionView.reloadData()
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
