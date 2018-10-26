//
//  MACommonGroupsVC.swift
//  RMessaging
//
//  Created by rajkumar.sharma on 4/25/18.
//  Copyright © 2018 Raj Sharma. All rights reserved.
//

import UIKit

class MACommonGroupsVC: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var dataSourceArray = [MAChatRoom]()
    var participantInfo: MAUser?

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
        
        fetchAllBlockedUser()
    }
    
    private func fetchAllBlockedUser() {
        
        guard let participantInfo = self.participantInfo else {
            self.navigationController?.popViewController(animated: true)
            return
        }
        
        FBChatRoomServices.fetchCommonGroupsWithUser(user: participantInfo) { (result) in
            if let error = result.error {
                AlertController.alert(title: error.localizedDescription)
            } else {
                self.dataSourceArray = result.groups
                self.tableView.reloadData()
            }
        }
    }
    
    //MARK:- IBActions
    
    @IBAction func onBackButtonAction(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    //MARK:- UITableView
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return max(68, UITableViewAutomaticDimension)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return dataSourceArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell:MASubTitleAvtarCell = tableView.dequeueReusableCell(withIdentifier: "MASubTitleAvtarCell", for: indexPath) as! MASubTitleAvtarCell
        
        let group = dataSourceArray[indexPath.row]
        cell.titleLabel.text = group.chatRoomName
        cell.avatar.normalLoad(group.avatarUrl)
        
        return cell
    }
    
    //MARK:- Memory handling
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

