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
    let progress: CZHTTPRequester.Progress?
    var success: CZHTTPRequester.Success
    var failure: CZHTTPRequester.Failure

    var urlRequeser: CZHTTPRequester?
    required init(url: URL,
                  progress: CZHTTPRequester.Progress? = nil,
                  success: @escaping CZHTTPRequester.Success,
                  failure: @escaping CZHTTPRequester.Failure) {
        self.url = url
        self.progress = progress
        self.success = success
        self.failure = failure
        super.init()

        self.success = {[weak self] (data, reponse) in
            // Update Operation's `isFinished` prop
            self?.finish()
            success(data, reponse)
        }

        self.failure = {[weak self] (reponse, error) in
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
        urlRequeser?.cancel()
        finish()
    }
}

fileprivate extension CZImageDownloadOperation {
    func downloadImage(url: URL) {
        urlRequeser = CZHTTPRequester(.GET,
                                      url: url,
                                            parameters: nil,
                                            shouldSerializeJson: false,
                                            success: success,
                                            failure: failure,
                                            progress: progress)
        urlRequeser?.start() 
    }
}




