//
//  FeedListViewModel.swift
//  CZWebImageDemo
//
//  Created by Cheng Zhang on 11/22/17.
//  Copyright © 2017 Cheng Zhang. All rights reserved.
//

import UIKit

class FeedListViewModel: NSObject {
    fileprivate(set) lazy var feeds: [Feed] = {
        return FeedsMocker.shared.feeds
    }()    
}
