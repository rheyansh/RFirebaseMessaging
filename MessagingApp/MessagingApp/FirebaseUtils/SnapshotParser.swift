//
//  SnapshotParser.swift
//  RMessaging
//
//  Created by rajkumar.sharma on 4/25/18.
//  Copyright © 2018 Raj Sharma. All rights reserved.
//

import Foundation
import Firebase

protocol SnapshotParser {
    
    init(with snapshot: DataSnapshot, exception: String...)
}
