//
//  CZWebImageManager.swift
//  FlickrDemo
//
//  Created by mac on 9/20/17.
//  Copyright © 2017 Cheng Zhang. All rights reserved.
//

import UIKit
import CZNetworking

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
                       downloadType: CZImageDownloadType,
                       completionHandler: CZImageDownloderCompletion!) {
        cache.getCachedFile(withUrl: url) {[weak self] (imageIn) in
            guard let `self` = self else {return}
            if let imageIn = imageIn {
                // Load from local disk
                CZMainQueueScheduler.async {
                    completionHandler?(imageIn, true, url)
                }
                return
            }
            // Load from remote server
            self.downloader.downloadImage(with: url,
                                          cropSize: cropSize,
                                          downloadType: downloadType,
                                          completionHandler: completionHandler)
        }
    }
    
    @objc(cancelDownloadWithURL:)
    public func cancelDownload(with url: URL!) {
        downloader.cancelDownload(with: url)
    }
}
