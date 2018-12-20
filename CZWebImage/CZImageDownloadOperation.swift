//
//  CZImageDownloadOperation.swift
//  CZWebImage
//
//  Created by Cheng Zhang on 1/22/16.
//  Copyright © 2016 Cheng Zhang. All rights reserved.
//

import Foundation
import CZUtils
import CZNetworking

/// Concurrent operation class for image downloading OperationQueue, supports success/failure/progress callback
class CZImageDownloadOperation: CZConcurrentOperation {
    let url: URL
    var requester: HTTPRequestWorker?
    let progress: HTTPRequestWorker.Progress?
    var success: HTTPRequestWorker.Success
    var failure: HTTPRequestWorker.Failure
    
    required init(url: URL,
                  progress: HTTPRequestWorker.Progress? = nil,
                  success: @escaping HTTPRequestWorker.Success,
                  failure: @escaping HTTPRequestWorker.Failure) {
        self.url = url
        self.progress = progress
        self.success = success
        self.failure = failure
        super.init()
        
        self.success = { [weak self] (data, reponse) in
            // Update Operation's `isFinished` prop
            self?.finish()
            success(data, reponse)
        }
        
        self.failure = { [weak self] (reponse, error) in
            // Update Operation's `isFinished` prop
            self?.finish()
            failure(reponse, error)
        }
    }
    
    override func execute() {
        downloadImage(url: url)
    }
    
    override func cancel() {
        super.cancel()
        requester?.cancel()
        finish()
    }
}

private extension CZImageDownloadOperation {
    func downloadImage(url: URL) {
        requester = HTTPRequestWorker(
            .GET,
            url: url,
            params: nil,
            shouldSerializeJson: false,
            success: success,
            failure: failure,
            progress: progress)
        requester?.start()
    }
}




