//
//  UIImageView+Extension.swift
//  CZWebImage
//
//  Created by Cheng Zhang on 9/22/17.
//  Copyright © 2017 Cheng Zhang. All rights reserved.
//

import UIKit
import CZNetworking

public typealias CZWebImageCompletion = (Error?) -> Void

private var kImageUrl: UInt8 = 0
extension UIImageView {
    var czImageUrl: URL? {
        get { return objc_getAssociatedObject(self, &kImageUrl) as? URL }
        set { objc_setAssociatedObject(self, &kImageUrl, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
    
    func cz_setImage(withURL url: URL?,
                     placeholderImage: UIImage? = nil,
                     cropSize: CGSize? = nil,
                     completion: CZWebImageCompletion? = nil) {
        guard let url = url else {
            CZMainQueueScheduler.async {
                completion?(CZWebImageError("imageURL is nil"))
            }
            return
        }
        
        cz_cancelCurrentImageLoad()
        czImageUrl = url
        
        CZWebImageManager.shared.downloadImage(with: url, cropSize: cropSize, downloadType: .default) {[weak self] (image, number, url) in
            guard let `self` = self, self.czImageUrl == url else {return}
        }
    }
    
    func cz_cancelCurrentImageLoad() {
        if let czImageUrl = czImageUrl {
            CZWebImageManager.shared.cancelDownload(with: czImageUrl)
        }
    }
}
