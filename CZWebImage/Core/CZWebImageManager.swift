//
//  CZWebImageManager.swift
//  FlickrDemo
//
//  Created by mac on 9/20/17.
//  Copyright © 2017 Cheng Zhang. All rights reserved.
//

import UIKit
import CZNetworking

enum CZWebImageConstants {
    static let shouldObserveOperations: Bool = false
    static let defaultImageQueueMaxConcurrent: Int = 50
    static let largeImageQueueMaxConcurrent: Int = 20
    static let kOperations: String = "operations"
}

@objc open class CZWebImageManager: NSObject {
    var imageManager: CZWebImageManager?
    fileprivate var downloader: CZImageDownloader
    fileprivate var cache: CZCache
    public static let sharedInstance: CZWebImageManager = CZWebImageManager()
    
    public override init() {
        downloader = CZImageDownloader.shared
        cache = CZCache.shared
        super.init()
    }
    
    @objc(downloadImageWithURL:cropSize:downloadType:completionHandler:)
    public func downloadImage(with url: URL!,
                       cropSize: CGSize,
                       downloadType: CZImageDownloadType,
                       completionHandler: CZImageDownloderCompletion!) {
        self.cache.getCachedFile(withUrl: url) {[weak self] (imageIn) in
            guard let `self` = self else {return}
            if let imageIn = imageIn {
                // Load from local disk
                CZMainQueueScheduler.async {
                    completionHandler?(imageIn, NSNumber(value: true), url)
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
