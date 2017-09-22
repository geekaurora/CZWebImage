//
//  CZHTTPManager.swift
//  CZNetworking
//
//  Created by Cheng Zhang on 12/9/16.
//  Copyright © 2016 Cheng Zhang. All rights reserved.
//

import UIKit

/// General protocol for CZHTTPAPIClientable class, e.g. CZHTTPManager
public protocol CZHTTPAPIClientable {
    func GET(_ urlStr: String,
             parameters: [AnyHashable: Any]?,
             success: @escaping CZHTTPRequester.Success,
             failure: @escaping CZHTTPRequester.Failure,
             cached: CZHTTPRequester.Cached?,
             progress: CZHTTPRequester.Progress?)
    
    func POST(_ urlStr: String,
              parameters: [AnyHashable: Any]?,
              success: @escaping CZHTTPRequester.Success,
              failure: @escaping CZHTTPRequester.Failure,
              progress: CZHTTPRequester.Progress?)
    
    func DELETE(_ urlStr: String,
                parameters: [AnyHashable: Any]?,
                success: @escaping CZHTTPRequester.Success,
                failure: @escaping CZHTTPRequester.Failure)
}


/**
 Asynchronous HTTP requests manager based on NSOperationQueue
 */
open class CZHTTPManager: NSObject, CZHTTPAPIClientable {
    fileprivate var queue: OperationQueue
    public static var shared = CZHTTPManager()
    fileprivate(set) var httpCache: CZHTTPCache

    public override init() {
        queue = OperationQueue()
        queue.maxConcurrentOperationCount = 5
        httpCache = CZHTTPCache()
        super.init()
    }

    public func GET(_ urlStr: String,
             parameters: [AnyHashable: Any]? = nil,
             success: @escaping CZHTTPRequester.Success,
             failure: @escaping CZHTTPRequester.Failure,
             cached: CZHTTPRequester.Cached? = nil,
             progress: CZHTTPRequester.Progress? = nil) {
        startRequester(.GET,
                       urlStr: urlStr,
                       parameters: parameters,
                       success: success,
                       failure: failure,
                       cached: cached,
                       progress: progress)
    }

    public func POST(_ urlStr: String,
             parameters: [AnyHashable: Any]? = nil,
             success: @escaping CZHTTPRequester.Success,
             failure: @escaping CZHTTPRequester.Failure,
             progress: CZHTTPRequester.Progress? = nil) {
        startRequester(.POST,
                       urlStr: urlStr,
                       parameters: parameters,
                       success: success,
                       failure: failure,
                       progress: progress)
    }

    public func DELETE(_ urlStr: String,
              parameters: [AnyHashable: Any]? = nil,
              success: @escaping CZHTTPRequester.Success,
              failure: @escaping CZHTTPRequester.Failure) {
        startRequester(.DELETE,
                       urlStr: urlStr,
                       parameters: parameters,
                       success: success,
                       failure: failure)
    }
}

fileprivate extension CZHTTPManager {
    func startRequester(_ requestType: CZHTTPRequester.RequestType,
                        urlStr: String,
                        parameters: [AnyHashable: Any]? = nil,
                        success: @escaping CZHTTPRequester.Success,
                        failure: @escaping CZHTTPRequester.Failure,
                        cached: CZHTTPRequester.Cached? = nil,
                        progress: CZHTTPRequester.Progress? = nil) {
        let op = BlockOperation {
            CZHTTPRequester(requestType,
                            url: URL(string: urlStr)!,
                            parameters: parameters,
                            httpCache: self.httpCache,
                            success: success,
                            failure: failure,
                            cached: cached,
                            progress: progress)
                        .start()
        }
        queue.addOperation(op)
    }
}

open class CZNetError: NSObject {
    fileprivate static let domain = "CZHTTP"
    fileprivate  static let kDescription = "description"
    fileprivate static let unknownCode = 99
    public static let `default` = NSError(domain: domain, code: unknownCode, userInfo: [kDescription: "Network Error"])
    public static let returnType = NSError(domain: domain, code: unknownCode, userInfo: [kDescription: "ReturnType Error"])

    public static func error(description: String) -> NSError {
        return NSError(domain: domain,
                       code: unknownCode,
                       userInfo: [kDescription: description])
    }
}
