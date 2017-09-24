//
//  CZWebImageConstants.swift
//  CZWebImage
//
//  Created by Cheng Zhang on 9/22/17.
//  Copyright © 2017 Cheng Zhang. All rights reserved.
//

import UIKit

enum CZWebImageConstants {
    static let shouldObserveOperations: Bool = false
    static let defaultImageQueueMaxConcurrent: Int = 50
    static let largeImageQueueMaxConcurrent: Int = 20
    static let kOperations = "operations"
    static let errorDomain = "CZWebImage"
    static let kFadeAnimation = "com.tony.webimage.fadeAnimation"
    static let fadeAnimationDuration: TimeInterval = 0.4
}

@objc public enum CZWebImageOption: Int {
    case fadeInAnimation = 0
    case lowPriority
}
