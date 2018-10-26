//
//  MAPagination.swift
//  RMessaging
//
//  Created by rajkumar.sharma on 4/25/18.
//  Copyright © 2018 Raj Sharma. All rights reserved.
//

import UIKit

let maxPageSize: UInt = 6

struct MAPagination {
    
    var currentOffset: String
    var nextOffset: String

    init() {
        currentOffset = ""
        nextOffset = ""
    }
}
