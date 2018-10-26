//
//  Debug.swift
//  RMessaging
//
//  Created by rajkumar.sharma on 4/25/18.
//  Copyright © 2018 Raj Sharma. All rights reserved.
//

import UIKit

// Logger for debug

final class Debug {
    
    static var isEnabled = false
    
    static func log(_ msg: @autoclosure () -> String = "", _ file: @autoclosure () -> String = #file, _ line: @autoclosure () -> Int = #line, _ function: @autoclosure () -> String = #function) {
        if isEnabled {
            let fileName = file().components(separatedBy: "/").last ?? ""
            print("[Debug] [\(fileName):\(line())]🍀🍀🍀: \(function()) \(msg())")
        }
    }
}
