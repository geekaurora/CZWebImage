//
//  CZImageDownloader.swift
//  CZWebImage
//
//  Created by Cheng Zhang on 1/20/16.
//  Copyright © 2016 Cheng Zhang. All rights reserved.
//

import UIKit
import CZUtils
import CZNetworking

fileprivate var kvoContext: UInt8 = 0

public typealias CZImageDownloderCompletion = (UIImage?, Bool, URL) -> Void

/// Asynchronous image downloading class on top of OperationQueue
public class CZImageDownloader: NSObject {
    fileprivate var imageDownloadQueue: OperationQueue
    fileprivate var imageDecodeQueue: OperationQueue
    public static let shared: CZImageDownloader = CZImageDownloader()
    
    public override init() {
        imageDownloadQueue = OperationQueue()
        imageDownloadQueue.qualityOfService = .userInteractive
        imageDownloadQueue.maxConcurrentOperationCount = CZWebImageConstants.downloadQueueMaxConcurrent
        imageDecodeQueue = OperationQueue()
        imageDecodeQueue.maxConcurrentOperationCount = CZWebImageConstants.decodeQueueMaxConcurrent
        super.init()
        
        if CZWebImageConstants.shouldObserveOperations {
            imageDownloadQueue.addObserver(self, forKeyPath: CZWebImageConstants.kOperations, options: [.new, .old], context: &kvoContext)
        }
    }
    
    deinit {
        if CZWebImageConstants.shouldObserveOperations {
            imageDownloadQueue.removeObserver(self, forKeyPath: CZWebImageConstants.kOperations)
        }
        imageDownloadQueue.cancelAllOperations()
    }
    
    public func downloadImage(with url: URL?,
                       cropSize: CGSize? = nil,
                       priority: Operation.QueuePriority = .normal,
                       completionHandler: CZImageDownloderCompletion!) {
        guard let url = url else {return}
        cancelDownload(with: url)
        
        let queue = imageDownloadQueue
        let operation = CZImageDownloadOperation(url: url,
                                                 progress: nil,
                                                 success: { [weak self] (task, data) in
            guard let `self` = self, let data = data as? Data else {preconditionFailure()}
            // Decode/crop image in decode OperationQueue
            self.imageDecodeQueue.addOperation {
                var internalData: Data? = data
                var image = UIImage(data: data)
                if let cropSize = cropSize, cropSize != .zero {
                    image = image?.crop(toSize: cropSize)
                    internalData =  (image == nil) ? nil : UIImagePNGRepresentation(image!)
                }
                CZImageCache.shared.setCacheFile(withUrl: url, data: internalData)
                
                // Call completionHandler on mainQueue
                CZMainQueueScheduler.async {
                    completionHandler?(image, false, url)
                }
            }
        }, failure: { (task, error) in
            print("DOWNLOAD ERROR: \(error.localizedDescription)")
        })
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
        imageDownloadQueue.operations.forEach(cancelIfNeeded)
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
        if object === imageDownloadQueue {
            print("Default image queue size: \(object.operationCount)")
        }
    }
}
