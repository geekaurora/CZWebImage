//
//  UIImageView+Extension.swift
//  CZWebImage
//
//  Created by Cheng Zhang on 1/26/16.
//  Copyright © 2016 Cheng Zhang. All rights reserved.
//

import UIKit
import CZUtils
import CZNetworking

public typealias CZWebImageCompletion = (UIImage?, Error?) -> Void

private var kImageUrl: UInt8 = 0

/// Convenience UIImageView extension for asynrhonous image downloading
extension UIImageView {
    public var czImageUrl: URL? {
        get { return objc_getAssociatedObject(self, &kImageUrl) as? URL }
        set { objc_setAssociatedObject(self, &kImageUrl, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
    
    public func cz_setImage(with url: URL?,
                     placeholderImage: UIImage? = nil,
                     cropSize: CGSize? = nil,
                     options: [CZWebImageOption]? = [.fadeInAnimation],
                     completion: CZWebImageCompletion? = nil) {
        image = placeholderImage
        cz_cancelCurrentImageLoad()
        czImageUrl = url

        guard let url = url else {
            CZMainQueueScheduler.async {
                completion?(nil, CZWebImageError("imageURL is nil"))
            }
            return
        }
        
        let priority: Operation.QueuePriority = (options?.contains(.highPriority) ?? false) ? .veryHigh : .normal
        CZWebImageManager.shared.downloadImage(with: url, cropSize: cropSize, priority: priority) {[weak self] (image, isFromCache, url) in
            guard let `self` = self, self.czImageUrl == url else {return}
            CZMainQueueScheduler.sync {
                if let options = options {
                    if !isFromCache &&
                        options.contains(.fadeInAnimation) {
                        self.fadeIn()
                    }
                }

                self.image = image
                self.layoutIfNeeded()
                completion?(image, nil)
            }
        }
    }
    
    public func cz_cancelCurrentImageLoad() {
        if let czImageUrl = czImageUrl {
            CZWebImageManager.shared.cancelDownload(with: czImageUrl)
        }
    }
}

// MARK: - Bridging functions exposed to Objective-C

extension UIImageView {
    @objc(cz_setImageWithURL:placeholderImage:cropSize:options:completion:)
    public func cz_setImage(withURL url: URL?,
                            placeholderImage: UIImage?,
                            cropSize: CGSize,
                            options: [NSNumber]?,
                            completion: CZWebImageCompletion?) {
        let bridgingOptions = options?.flatMap({ CZWebImageOption(rawValue: $0.intValue)})
        cz_setImage(with: url,
                    placeholderImage: placeholderImage,
                    cropSize: cropSize,
                    options: bridgingOptions,
                    completion: completion)
    }
}

