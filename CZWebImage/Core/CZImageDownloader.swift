//
//  CZImageDownloader.swift
//  FlickrDemo
//
//  Created by mac on 9/20/17.
//  Copyright © 2017 Cheng Zhang. All rights reserved.
//

import UIKit
import CZNetworking

fileprivate var kvoContext: UInt8 = 0

// Bool - isFromCache
public typealias CZImageDownloderCompletion = (UIImage?, Bool, URL) -> Void

//@objc public enum CZImagePriority: Int {
//    case `default` = 0, thumbnail, prefetch
//}

public class CZImageDownloader: NSObject {
    fileprivate var defaultImageQueue: OperationQueue
    public static let shared: CZImageDownloader = CZImageDownloader()
    
    public override init() {
        defaultImageQueue = OperationQueue()
        defaultImageQueue.qualityOfService = .userInteractive
        super.init()
        
        defaultImageQueue.maxConcurrentOperationCount = CZWebImageConstants.defaultImageQueueMaxConcurrent
        if CZWebImageConstants.shouldObserveOperations {
            defaultImageQueue.addObserver(self, forKeyPath: CZWebImageConstants.kOperations, options: [.new, .old], context: &kvoContext)
        }
    }
    
    deinit {
        if CZWebImageConstants.shouldObserveOperations {
            defaultImageQueue.removeObserver(self, forKeyPath: CZWebImageConstants.kOperations)
        }
        defaultImageQueue.cancelAllOperations()
    }
    
    public func downloadImage(with url: URL?,
                       cropSize: CGSize? = nil,
                       priority: Operation.QueuePriority = .normal,
                       completionHandler: CZImageDownloderCompletion!) {
        guard let url = url else {return}
        cancelDownload(with: url)
        
        let queue = defaultImageQueue
        let operation = CZImageDownloadOperation(url: url,
                                                 progress: nil,
                                                 success: { (task, data) in
            guard let data = data as? Data else {preconditionFailure()}
            var internalData: Data? = data
            var image = UIImage(data: data)
            if let cropSize = cropSize, cropSize != .zero {
                image = image?.crop(toSize: cropSize)
                internalData =  image == nil ? nil : UIImagePNGRepresentation(image!)
            }
            CZImageCache.shared.setCacheFile(withUrl: url, data: internalData)
                                                    
            CZMainQueueScheduler.async {
                completionHandler?(image, false, url)
            }
        }) { (task, error) in
            print("DOWNLOAD ERROR: \(error.localizedDescription)")
        }
        operation.queuePriority = priority
        queue.addOperation(operation)
    }
    
    @objc(cancelDownloadWithURL:)
    public func cancelDownload(with url: URL?) {
        guard let url = url else {return}
        
        let cancelIfNeeded = { (operation: Operation) in
            if let operation = operation as? CZImageDownloadOperation,
                operation.url == url {
                operation.cancel()
            }
        }
        defaultImageQueue.operations.forEach(cancelIfNeeded)
    }
}

// MARK: - KVO Delegation
extension CZImageDownloader {
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard context == &kvoContext,
            let object = object as? OperationQueue,
            let keyPath = keyPath,
            keyPath == CZWebImageConstants.kOperations else {
                return
        }
        if object === defaultImageQueue {
            print("Default image queue size: \(object.operationCount)")
        }
    }
}
