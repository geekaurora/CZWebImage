//
//  CZCache2.swift
//  CZWebImage
//
//  Created by Cheng Zhang on 9/22/17.
//  Copyright © 2017 Cheng Zhang. All rights reserved.
//

import UIKit
import CZNetworking

@objc class CZCache2: NSObject {
    static let sharedInsance = CZCache2()
    
    fileprivate var ioQueue: DispatchQueue
    
    fileprivate var cachedItemsInfoLock: CZMutexLock<[String: Any]>
    fileprivate var hasCachedItemsInfoToFlushToDisk: Bool = false
    fileprivate var memCache: NSCache<AnyObject, AnyObject>
    fileprivate var fileManager: FileManager
    fileprivate static let cacheFolder: String = {
        let cacheFolder = CZWebImageUtils.documentFolder() + "CZCache/"
        let fileManager = FileManager()
        if !fileManager.fileExists(atPath: cacheFolder) {
            do {
                try fileManager.createDirectory(atPath: cacheFolder, withIntermediateDirectories: true, attributes: nil)
            } catch {
                assertionFailure("Failure of creating folder! Error - \(error.localizedDescription); Folder - \(cacheFolder)")
            }
        }
        return cacheFolder
    }()
    fileprivate(set) var maxCacheAge: UInt
    fileprivate(set) var maxCacheSize: UInt
    
    init(maxCacheAge: UInt = 0, maxCacheSize: UInt = 0) {
        ioQueue = DispatchQueue(label: "com.tony.cache.ioQueue",
                                qos: .userInitiated,
                                attributes: .concurrent)
        
        fileManager = FileManager()
        
        // Memory cache
        memCache = NSCache()
        memCache.countLimit = 1000
        memCache.totalCostLimit = 1000 * 1024 * 1024
        
        cachedItemsInfoLock = CZMutexLock([:])
//        _cachedItemsInfo = [self loadCachedItemsInfoFromDisk] ? : [NSMutableDictionary new];
//        [self cleanDiskWithCompletionBlock:nil];

        self.maxCacheAge = maxCacheAge
        self.maxCacheSize = maxCacheSize
        super.init()
    }
    
    func cacheFilePath(for urlStr: String) -> String {
        return CZCache2.cacheFolder + urlStr.MD5
    }
}

fileprivate extension CZCache2 {
    
}
