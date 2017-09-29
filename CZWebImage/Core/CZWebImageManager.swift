//
//  CZWebImageManager.swift
//  CZWebImage
//
//  Created by Cheng Zhang on 1/20/16.
//  Copyright © 2016 Cheng Zhang. All rights reserved.
//

import UIKit
import CZUtils
import CZNetworking

/// Interface class managing image cache/downloading 
@objc open class CZWebImageManager: NSObject {
    var imageManager: CZWebImageManager?
    fileprivate var downloader: CZImageDownloader
    fileprivate var cache = CZImageCache.shared
    public static let shared: CZWebImageManager = CZWebImageManager()
    
    public override init() {
        downloader = CZImageDownloader.shared
        super.init()
    }
    
    public func downloadImage(with url: URL!,
                       cropSize: CGSize? = nil,
                       priority: Operation.QueuePriority = .normal,
                       completionHandler: CZImageDownloderCompletion!) {
        cache.getCachedFile(withUrl: url) {[weak self] (imageIn) in
            guard let `self` = self else {return}
            if let imageIn = imageIn {
                // Load from local disk
                CZMainQueueScheduler.sync {
                    completionHandler?(imageIn, true, url)
                }
                return
            }
            // Load from remote server
            self.downloader.downloadImage(with: url,
                                          cropSize: cropSize,
                                          priority: priority,
                                          completionHandler: completionHandler)
        }
    }
    
    @objc(cancelDownloadWithURL:)
    public func cancelDownload(with url: URL!) {
        downloader.cancelDownload(with: url)
    }
}
