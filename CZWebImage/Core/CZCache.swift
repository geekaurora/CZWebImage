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
    fileprivate typealias CachedItemsInfo = [String: [String: Any]]
    fileprivate var ioQueue: DispatchQueue
    fileprivate var operationQueue: OperationQueue
    fileprivate var cachedItemsInfoLock: CZMutexLock<CachedItemsInfo>!
    fileprivate var hasCachedItemsInfoToFlushToDisk: Bool = false
    fileprivate var memCache: NSCache<NSString, UIImage>
    fileprivate var fileManager: FileManager
    fileprivate var cachedItemsInfoFileURL: URL = {
        return URL(fileURLWithPath: CZCacheFileManager.cacheFolder + "/" + CZCache.kCachedItemsInfoFile)
    }()
    fileprivate(set) var maxCacheAge: UInt
    fileprivate(set) var maxCacheSize: UInt
    
    fileprivate static let kCachedItemsInfoFile = "cachedItemsInfo.plist"
    fileprivate static let kFileModifiedDate = "modifiedDate"
    fileprivate static let kFileLastVisitedDate = "visitedDate"
    fileprivate static let kFileSize = "size"
    
    // 60 days
    fileprivate static let kCZCacheDefaultMaxAge: UInt =  60 * 24 * 60 * 60
    // 500M
    fileprivate static let kCZCacheDefaultMaxSize: UInt =  500 * 1024 * 1024
    
    public init(maxCacheAge: UInt = kCZCacheDefaultMaxAge,
                maxCacheSize: UInt = kCZCacheDefaultMaxSize) {
        operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 60
        
        ioQueue = DispatchQueue(label: "com.tony.cache.ioQueue",
                                qos: .userInitiated,
                                attributes: .concurrent)
        
        fileManager = FileManager()
        
        // Memory cache
        memCache = NSCache()
        memCache.countLimit = 1000
        memCache.totalCostLimit = 1000 * 1024 * 1024
        
        self.maxCacheAge = maxCacheAge
        self.maxCacheSize = maxCacheSize
        super.init()
        
        let cachedItemsInfo: CachedItemsInfo = loadCachedItemsInfo() ?? [:]
        cachedItemsInfoLock = CZMutexLock(cachedItemsInfo)
        //        [self cleanDiskWithCompletionBlock:nil];
    }
    
    public func setCacheFile(withUrl url: URL, data: Data?) {
        guard let data = data else {return}
        let (fileURL, cacheKey) = cacheFileInfo(forURL: url)
        // Mem cache
        if let image = UIImage(data: data) {
            setMemCache(image: image, forKey: cacheKey)
        }
        
        // Disk cache
        ioQueue.async(flags: .barrier) {[weak self] in
            guard let `self` = self else {return}
            do {
                try data.write(to: fileURL)
                self.setCachedItemsInfo(key: cacheKey, subkey: CZCache.kFileModifiedDate, value: NSDate())
                self.setCachedItemsInfo(key: cacheKey, subkey: CZCache.kFileLastVisitedDate, value: NSDate())
                self.setCachedItemsInfo(key: cacheKey, subkey: CZCache.kFileSize, value: data.count)
            } catch {
                assertionFailure("Failed to write file. Error - \(error.localizedDescription)")
            }
        }
    }    
    
    public func getCachedFile(withUrl url: URL, completion: @escaping (UIImage?) -> Void)  {
        operationQueue.addOperation {[weak self] in
            guard let `self` = self else {return}
            let (fileURL, cacheKey) = self.cacheFileInfo(forURL: url)
            // Read data from mem cache
            var image: UIImage? = self.getMemCache(forKey: cacheKey)
            // Read data from disk cache
            if image == nil {
                image = self.ioQueue.sync {
                    if let data = try? Data(contentsOf: fileURL),
                       let image = UIImage(data: data) {
                        // update lastVisited date
                        self.setCachedItemsInfo(key: cacheKey, subkey: CZCache.kFileLastVisitedDate, value: NSDate())
                        // Set mem cache after loading data from local drive
                        self.setMemCache(image: image, forKey: cacheKey)
                        return image
                    }
                    return nil
                }
            }
            // Completion callback
            CZMainQueueScheduler.async {
                completion(image)
            }
        }
    }
    
    public typealias CleanDiskCacheCompletion = () -> Void
    func cleanDiskCacheIfNeeded(completion: CleanDiskCacheCompletion? = nil){
        
    }
}

fileprivate extension CZCache {
    func loadCachedItemsInfo() -> CachedItemsInfo? {
        return NSDictionary(contentsOf: cachedItemsInfoFileURL) as? CachedItemsInfo
    }
    
    func setCachedItemsInfo(key: String, subkey: String, value: Any) {
        cachedItemsInfoLock.writeLock {[weak self] (cachedItemsInfo) -> Void in
            guard let `self` = self else {return}
            cachedItemsInfo[key] = cachedItemsInfo[key] ?? [String: Any]()
            cachedItemsInfo[key]![subkey] = value
            print(self.cachedItemsInfoFileURL)
            (cachedItemsInfo as NSDictionary).write(to: self.cachedItemsInfoFileURL, atomically: true)
        }
    }
    
    func removeCachedItemsInfo(forKey key: String) {
        cachedItemsInfoLock.writeLock {[weak self] (cachedItemsInfo) -> Void in
            guard let `self` = self else {return}
            cachedItemsInfo.removeValue(forKey: key)
            (cachedItemsInfo as NSDictionary).write(to: self.cachedItemsInfoFileURL, atomically: true)
        }
    }
    
    func getMemCache(forKey key: String) -> UIImage? {
        return memCache.object(forKey: NSString(string: key))
    }
    
    func setMemCache(image: UIImage, forKey key: String) {
        memCache.setObject(image,
                           forKey: NSString(string: key),
                           cost: cacheCost(forImage: image))
    }

    func cacheCost(forImage image: UIImage) -> Int {
        return Int(image.size.height * image.size.width * image.scale * image.scale)
    }
    
    
    typealias CacheFileInfo = (fileURL: URL, cacheKey: String)
    func cacheFileInfo(forURL url: URL) -> CacheFileInfo {
        let cacheKey = url.absoluteString.MD5
        let fileURL = URL(fileURLWithPath: CZCacheFileManager.cacheFolder + url.absoluteString.MD5)
        return (fileURL: fileURL, cacheKey: cacheKey)
    }
}
