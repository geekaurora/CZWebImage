//
//  CZWebImageConstants.swift
//  CZWebImage
//
//  Created by Cheng Zhang on 1/18/16.
//  Copyright © 2016 Cheng Zhang. All rights reserved.
//

import UIKit

/**
 Constants of CZWebImage
 */
public enum CZWebImageConstants {
    public static var shouldObserveOperations = false
    public static var downloadQueueMaxConcurrent = 5
    public static var decodeQueueMaxConcurrent = downloadQueueMaxConcurrent
    public static var kOperations = "operations"
    public static var errorDomain = "CZWebImage"
    public static var kFadeAnimation = "com.tony.webimage.fadeAnimation"
}
