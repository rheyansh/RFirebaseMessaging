//
//  MABlockUsersVC.swift
//  RMessaging
//
//  Created by rajkumar.sharma on 4/25/18.
//  Copyright © 2018 Raj Sharma. All rights reserved.
//

import UIKit

class MABlockUsersVC: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var dataSourceArray = [MAUser]()
    
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
        
        FBBlockUserServices.fetchBlockedUsers(callback: { (result) in
            
            if let error = result.error {
                AlertController.alert(title: error.localizedDescription)
            } else {
                self.dataSourceArray = result.users
                self.tableView.reloadData()
            }
        })
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
        
        let user = dataSourceArray[indexPath.row]
        cell.titleLabel.text = user.fullName
        cell.avatar.userLoad(user.avatarUrl)
        
        return cell
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteAction = UITableViewRowAction(style: .default, title: "Unblock") { (action, indexPath) in
            let user = self.dataSourceArray[indexPath.row]
            FBBlockUserServices.unblock(user: user, callback: { (isSuccess, error) in
                
                if let error = error {
                    TinyToast.shared.show(message: error.localizedDescription, duration: .veryShort)
                } else {
                    if isSuccess {
                        let message = "\(user.fullName) unblocked"
                        TinyToast.shared.show(message: message, duration: .veryShort)
                    }
                }
            })
        }
        
        return [deleteAction]
    }
    
    //MARK:- Memory handling
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

