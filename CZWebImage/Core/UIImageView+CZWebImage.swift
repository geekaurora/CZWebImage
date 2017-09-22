//
//  UIImageView+Extension.swift
//  CZWebImage
//
//  Created by Cheng Zhang on 9/22/17.
//  Copyright © 2017 Cheng Zhang. All rights reserved.
//

import UIKit

private var kImageUrl: UInt8 = 0

extension UIImageView {
    var imageUrl: String? {
        get { return objc_getAssociatedObject(self, &kImageUrl) as? String }
        set { objc_setAssociatedObject(self, &kImageUrl, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
}
