//
//  Feed.swift
//  CZWebImageDemo
//
//  Created by Cheng Zhang on 11/22/17.
//  Copyright © 2017 Cheng Zhang. All rights reserved.
//

import UIKit

struct Feed {
    var imageUrl: String?
    
    init(dictionary: FeedDictionary) {
        imageUrl = dictionary["imageUrl"] as? String
    }
}
