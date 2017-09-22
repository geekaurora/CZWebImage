//
//  UIImageView+Extension.swift
//  CZWebImage
//
//  Created by Cheng Zhang on 9/22/17.
//  Copyright © 2017 Cheng Zhang. All rights reserved.
//

import UIKit

public typealias CZWebImageCompletion = (Error?) -> Void

private var kImageUrl: UInt8 = 0
extension UIImageView {
    var czImageUrl: String? {
        get { return objc_getAssociatedObject(self, &kImageUrl) as? String }
        set { objc_setAssociatedObject(self, &kImageUrl, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
    
    func cz_setImage(withURL url: URL?,
                     placeholderImage: UIImage? = nil,
                     completion: CZWebImageCompletion? = nil) {
        guard let url = url else {
            completion?(CZWebImageError("imageURL is nil."))
            return
        }
    }
    
    func cz_cancelCurrentImageLoad() {
        if let czImageUrl = czImageUrl {
            CZWebImageManager.sharedInstance.cancelDownload(with: URL(string: czImageUrl)!)
        }
    }
}
