//
//  CZCache.swift
//  CZWebImage
//
//  Created by Cheng Zhang on 9/22/17.
//  Copyright © 2017 Cheng Zhang. All rights reserved.
//

import UIKit
import CZNetworking

class CZImageCache: CZCache {
    public static let shared = CZImageCache()
}

class CZCache: NSObject {
    fileprivate var ioQueue: DispatchQueue
    fileprivate var cachedItemsInfoLock: CZMutexLock<[String: Any]>
    fileprivate var hasCachedItemsInfoToFlushToDisk: Bool = false
    fileprivate var memCache: NSCache<NSString, UIImage>
    fileprivate var fileManager: FileManager

    fileprivate(set) var maxCacheAge: UInt
    fileprivate(set) var maxCacheSize: UInt
    
    public init(maxCacheAge: UInt = 0,
                maxCacheSize: UInt = 0) {
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
    
    public func cacheFile(withUrl url: URL, data: Data?) {
        guard let data = data else {return}
        let filePath = cacheFilePath(forUrlStr: url.absoluteString)
        if let image = UIImage(data: data) {
            cacheMem(image: image, forKey: filePath)
        }
    } 
    
    public func getCachedFile(withUrl url: URL, completion: (UIImage?) -> Void)  {
        let filePath = cacheFilePath(forUrlStr: url.absoluteString)
        let image = memCache.object(forKey: NSString(string: filePath))
        completion(image)
    }
    
    public func cacheMem(image: UIImage, forKey key: String) {
        memCache.setObject(image,
                           forKey: NSString(string: key),
                           cost: cacheCost(forImage: image))
    }
}

fileprivate extension CZCache {
    func cacheCost(forImage image: UIImage) -> Int {
        return Int(image.size.height * image.size.width * image.scale * image.scale)
    }
    
    
    func cacheFilePath(forUrlStr urlStr: String) -> String {
        return CZCacheFileManager.cacheFolder + urlStr.MD5
    }
}
