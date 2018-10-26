//  AppDelegate.swift
//  RMessaging
//
//  Created by rajkumar.sharma on 4/25/18.
//  Copyright © 2018 Raj Sharma. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import UserNotifications
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    var window: UIWindow?
    var isReachable = false
    var appUser: MAUser?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // Firebase setup call
        FirebaseApp.configure()
        Database.database().isPersistenceEnabled = true
        setupReachability()
        
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in })
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        application.registerForRemoteNotifications()
        
        // Firebase messaging
        Messaging.messaging().delegate = self
        
        // Register to receive notification
        NotificationCenter.default.addObserver(self, selector: #selector(self.tokenRefreshNotification), name: NSNotification.Name("firInstanceIDTokenRefresh"), object: nil)
        // check if user is already logged in. If logged in go inside the app directly
        
        if let _ = Auth.auth().currentUser {
            
            if let _ = defaults.object(forKey: pCurrentUserId) {
                // User is signed in. Show home screen
                self.moveToHomeDashBoard()
            } else {
                // Firebase session is available but user is either logged out or deleted the app from device
            }
        } else {
            // No User is signed in. Show user the login screen
        }
        
        return true
    }
    
    //MARK:- Private functions
    
    fileprivate func setupReachability() {
        // Allocate a reachability object
        let reach = Reachability.forInternetConnection()
        self.isReachable = reach!.isReachable()
        
        // Set the blocks
        reach?.reachableBlock = { (reachability) in
            
            DispatchQueue.main.async(execute: {
                self.isReachable = true
            })
        }
        reach?.unreachableBlock = { (reachability) in
            DispatchQueue.main.async(execute: {
                self.isReachable = false
            })
        }
        reach?.startNotifier()
    }
    
    //@@@@@@@@@@@@@@@@@@@@@@@@@@
    
    func logOut() {
        RBasicUserServices.signOut(true) { (success, error) in
            if let error = error {
                AlertController.alert(title: "Error", message: (error.localizedDescription))
            } else {
                APPDELEGATE.appUser = nil
                defaults.removeObject(forKey: pCurrentUserId)
                self.moveToLogin()
            }
        }
    }
    
    func moveToHomeDashBoard() {
        let tabBarC = tabBarControllerStoryboard.instantiateViewController(withIdentifier: "TabBarController") as! TabBarController
        self.window!.rootViewController = tabBarC
    }
    
    func moveToLogin() {
        
        let authNavigationController = authStoryboard.instantiateViewController(withIdentifier: "AuthNavigationController") as! UINavigationController
        self.window!.rootViewController = authNavigationController
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        
        if RemoteNotificationHandler.isPushNotificationEnabled == true {
            self.registerForRemoteNotification()
        }
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        FCMNotificationHandler.connectToFCM()
    }
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        //Messaging.messaging().apnsToken = deviceToken
        Messaging.messaging().setAPNSToken(deviceToken, type: .prod)
    }
    
    //@@@>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    
    // [START ios_10_message_handling]
    // Receive displayed notifications for iOS 10 devices.
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        
        FCMNotificationHandler.receivedRemoteNotification(userInfo: userInfo)
        // Change this to your preferred presentation option
        completionHandler([])
    }
    
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        FCMNotificationHandler.receivedRemoteNotification(userInfo: userInfo)
        
        completionHandler()
    }
    //MARK:- MessagingDelegate
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        Debug.log("Firebase registration token: \(fcmToken)")
        
        // TODO: If necessary send token to application server.
        // Note: This callback is fired at each app startup and whenever a new token is generated.
        
        if let user = Auth.auth().currentUser {
            if let _ = defaults.object(forKey: pCurrentUserId) {
                // User is signed in. Show home screen
                user.updateForRemoteNotification()
            }
        }
    }
    
    func application(received remoteMessage: MessagingRemoteMessage) {
        Debug.log("remoteMessage received: \(remoteMessage)")
    }
    
    //Message Delegate Method
    public func messaging(_ messaging: Messaging, didRefreshRegistrationToken fcmToken: String) {
        
    }
    
    func registerForRemoteNotification() {
        
        let application = UIApplication.shared
        
        if #available(iOS 10.0, *) {
            
            /*for devices running iOS 10 and above, you must assign your delegate object to the UNUserNotificationCenter object to receive display notifications, and the FIRMessaging object to receive data messages, before your app finishes launching. For example, in an iOS app, you must assign it in the applicationWillFinishLaunching: or applicationDidFinishLaunching: method.*/
            
            UNUserNotificationCenter.current().delegate = self
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
                guard error == nil else {
                    return
                }
                if granted {
                    DispatchQueue.main.async(execute: {
                        application.registerForRemoteNotifications()
                    })
                }
                else {
                    //Handle user denying permissions..
                }
            }
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        application.registerForRemoteNotifications()
    }
    
    @objc func tokenRefreshNotification(notification:NotificationCenter) {
        if let token = InstanceID.instanceID().token() {
            defaults.setValue(token, forKey: pDeviceToken)
            Debug.log(token)
        }
        FCMNotificationHandler.connectToFCM()
    }
    
    ///***********
    
    // [START receive_message]
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        // Print message ID.
        // Print full message.
        FCMNotificationHandler.receivedRemoteNotification(userInfo: userInfo)
        // self.fireLocallNotifcation(userInformation: userInfo as! Dictionary<String, Any>)
        
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        // Print message ID.
        
        
        // Print full message.
        FCMNotificationHandler.receivedRemoteNotification(userInfo: userInfo)
        // self.fireLocallNotifcation(userInformation: userInfo as! Dictionary<String, Any>)
        
        completionHandler(UIBackgroundFetchResult.newData)
    }
    // [END receive_message]
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        Debug.log("Unable to register for remote notifications: \(error.localizedDescription)")
    }
}

