//
//  MUserProfileVC.swift
//  RMessaging
//
//  Created by rajkumar.sharma on 4/25/18.
//  Copyright © 2018 Raj Sharma. All rights reserved.
//

import UIKit
import MessageUI
import FirebaseAuth
import Firebase

class MUserProfileVC: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView_UserProfile: UITableView!
    @IBOutlet weak var headerView: UIView!
    
    @IBOutlet weak var button_arrowImage: UIButton!
    @IBOutlet weak var label_UserName: UILabel!
    @IBOutlet weak var imageView_UserProfile: UIImageView!
    
    var modalUser: MAUser?
    
    //MARK:- UIViewController Life CYcle Method
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initialSetUp()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadCurrentUserData()
    }

    //MARK:- Helper Method
    func initialSetUp() {
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(pushMethod(gesture:)))
        headerView.addGestureRecognizer(tapRecognizer)
    }
    
    private func loadCurrentUserData() {
        
        FirebaseUtils.currentUser { (currentUser) in
            currentUser.fetch(completionBlock: { (isSuccess, modalUser, error) in
                if let modalUser = modalUser {
                    self.modalUser = modalUser
                    self.label_UserName.text = modalUser.firstName
                    self.imageView_UserProfile.userLoad(modalUser.avatarUrl)
                    self.tableView_UserProfile.reloadData()
                    APPDELEGATE.appUser = modalUser
                }
            })
        }
    }
    
    @objc func switchChanged(_ sender: UISwitch) {
        RBasicUserServices.updateCurrentUserPushNotificationStatus(value: sender.isOn, completionBlock: nil)
   }
    
    @objc func pushMethod(gesture: UIGestureRecognizer) {
        
        let updateProfileVC = self.storyboard?.instantiateViewController(withIdentifier: "UpdateProfileVC") as! UpdateProfileVC
        updateProfileVC.modalUser = self.modalUser
        self.navigationController?.pushViewController(updateProfileVC, animated: true)
    }

    //MARK:- UITableView Data Source Method
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (section == 0) ? 2 : 4
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 42;
    }
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:MUserProfileTableViewCell = tableView.dequeueReusableCell(withIdentifier: "MUserProfileTableViewCell", for: indexPath) as! MUserProfileTableViewCell

        cell.selectionStyle = .none
        cell.buttonArrow.isUserInteractionEnabled = false
        
        cell.badgeCount = 0
        cell.badgeLabel.isHidden = true
        
        if(indexPath.section == 0){
        switch indexPath.row {
        case 0:
            cell.userProfile_Label.text = "Contacts"
            cell.arrowImage.isHidden = true
          //cell.badgeCount = 112

            cell.swtichBtn.isHidden = true
            cell.shadowLabel.isHidden = false
            break
        case 1:
            cell.userProfile_Label.text = "Blocked Users"
            cell.arrowImage.isHidden = true
            cell.circle_ImageView.isHidden = true
            cell.shadowLabel.isHidden = true
            cell.swtichBtn.isHidden = true
            break
        default :
            break
            }
        }
        else {
        switch indexPath.row{
        case 0:
            cell.userProfile_Label.text = "Message Notifications"
            cell.arrowImage.isHidden = true
            cell.buttonArrow.isHidden = true
            cell.circle_ImageView.isHidden = true
            cell.swtichBtn.isHidden = false
            cell.swtichBtn.isOn = false
            if let modalUser = modalUser {
                cell.swtichBtn.isOn = modalUser.notification
            }
            
            cell.swtichBtn.addTarget(self, action: #selector(self.switchChanged), for: .valueChanged)

            break
        case 1:
            cell.userProfile_Label.text = "Change Password"
            cell.arrowImage.isHidden = true
            cell.circle_ImageView.isHidden = true
            cell.swtichBtn.isHidden = true
            
            break
        case 2:
            cell.userProfile_Label.text = "About Circles"
            cell.arrowImage.isHidden = true
            cell.circle_ImageView.isHidden = true
            cell.swtichBtn.isHidden = true
            break
        case 3:
            cell.userProfile_Label.text = "Ask a Question"
            cell.arrowImage.isHidden = true
            cell.circle_ImageView.isHidden = true
            cell.swtichBtn.isHidden = true
            break
        default:
            break
            } }
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath.section == 0 ) {
            if (indexPath.row == 0) {
                
                let friendBaseVC = friendsSectionStoryboard.instantiateViewController(withIdentifier: "MAFriendBaseVC") as! MAFriendBaseVC
                self.navigationController?.pushViewController(friendBaseVC, animated: true)
            } else {
                let blockUsersVC = self.storyboard?.instantiateViewController(withIdentifier: "MABlockUsersVC") as! MABlockUsersVC
                self.navigationController?.pushViewController(blockUsersVC, animated: true)
            }
        }
        else if(indexPath.section == 1 ){
            if (indexPath.row == 0){

            } else if(indexPath.row == 1) {
                let changePasswordVC = self.storyboard?.instantiateViewController(withIdentifier: "ChangePasswordVC") as! ChangePasswordVC
                self.navigationController?.pushViewController(changePasswordVC, animated: true)
            } else if(indexPath.row == 2) {
                let aboutUs = AboutUsVC(nibName: "AboutUsVC", bundle: nil)
                self.navigationController?.pushViewController(aboutUs, animated: true)
            } else {
                RGeneralActions.action.sendMail(recipients: ["yourmailId@gmail.com"], subject: "New Group", body: "Hey add me on Circles! (Link to download Circles in app store)", block: nil)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView_UserProfile.frame.size.width, height: 23))
        let upperLbl = UILabel(frame: CGRect(x: 0, y: 0, width: tableView_UserProfile.frame.size.width, height: 1))
        let lowerLbl = UILabel(frame: CGRect(x: 0, y: 40, width: tableView_UserProfile.frame.size.width, height: 1))
        upperLbl.backgroundColor = UIColor(red: 184.0 / 255.0, green: 184.0 / 255.0, blue: 184.0 / 255.0, alpha: 1.0)
         lowerLbl.backgroundColor = UIColor(red: 184.0 / 255.0, green: 184.0 / 255.0, blue: 184.0 / 255.0, alpha: 1.0)
        headerView.backgroundColor = UIColor(red: 239.0 / 255.0, green: 239.0 / 255.0, blue: 241.0 / 255.0, alpha: 1.0)
        headerView.addSubview(upperLbl)
       // headerView.addSubview(lowerLbl)
        return headerView
    }

    //MARK:- IBAction Method
    @IBAction func logoutButtonAction(_ sender: UIButton) {
        
        AlertController.alert(title: logOutTitle, message: logOutSubTitle, buttons: ["NO", "YES"], tapBlock: { (_, index) in
            if (index != 0) {
                APPDELEGATE.logOut()
            }
        })
    }
    
    //MARK:-Memory Warning Method
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
