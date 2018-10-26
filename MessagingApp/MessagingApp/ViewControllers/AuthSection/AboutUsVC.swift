//
//  AboutUsVC.swift
//  RMessaging
//
//  Created by rajkumar.sharma on 4/25/18.
//  Copyright © 2018 Raj Sharma. All rights reserved.
//

import UIKit

class AboutUsVC: UIViewController,UITableViewDelegate,UITableViewDataSource {

    @IBOutlet weak var tableView_AboutUs: UITableView!
    
    var cellIdentifier : String = "AboutUsTableViewCellID"
    
    //MARK:- UIViewConrtoller Life Cycle Method
    override func viewDidLoad() {
        super.viewDidLoad()
        customMethod()
    }

    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    //MARK:- Helper Method
    func customMethod() {
        tableView_AboutUs.register(UINib(nibName: "AboutUsTableViewCell", bundle: nil), forCellReuseIdentifier: cellIdentifier)

    }
    
    //MARK:- IBAction Method
    @IBAction func backButtonAction(_ sender: UIButton) {
        self.view.endEditing(true)
        self.navigationController?.popViewController(animated: true)
    }
    
    //MARK:- UITableView DataSource Method
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
     return 2
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return  65
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? AboutUsTableViewCell
        cell?.selectionStyle = .none
        switch indexPath.row {
        case 0:
            cell?.label_AboutUsContent.text = "Terms and Conditions"
        case 1:
            cell?.label_AboutUsContent.text = "Privacy Policy"
        default:
            break
        }
        let paintView = UIView(frame: CGRect(x: 0, y: 0, width:view.frame.size.width , height: 25))
        paintView.backgroundColor = UIColor(red: 243.0 / 255.0, green: 243.0 / 255.0, blue: 243.0 / 255.0, alpha: 1.0)
        view.addSubview(paintView)
        cell?.contentView.addSubview(paintView)
        cell?.contentView.sendSubview(toBack: paintView)
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let genericContentVC = mainStoryboard.instantiateViewController(withIdentifier: "GenericContentVC") as! GenericContentVC
        genericContentVC.contentType = indexPath.row == 0 ? .ContentType_TOS : .ContentType_PrivacyPolicy
        self.navigationController?.pushViewController(genericContentVC, animated: true)
    }
    
    //MArk:- Memory Warning Method
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
