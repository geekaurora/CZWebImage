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
    fileprivate var operationQueue: OperationQueue
    fileprivate var cachedItemsInfoLock: CZMutexLock<[String: [String: Any]]>
    fileprivate var hasCachedItemsInfoToFlushToDisk: Bool = false
    fileprivate var memCache: NSCache<NSString, UIImage>
    fileprivate var fileManager: FileManager
    fileprivate var cachedItemsInfoFilePath: String
    fileprivate(set) var maxCacheAge: UInt
    fileprivate(set) var maxCacheSize: UInt
    
    fileprivate static let kCachedItemsInfoFile = "cachedItemsInfo.plist"
    fileprivate static let kFileModifiedDate = "modifiedDate"
    fileprivate static let kFileVisitedDate = "visitedDate"
    fileprivate static let kFileSize = "size"
    
    public init(maxCacheAge: UInt = 0,
                maxCacheSize: UInt = 0) {
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
        
        cachedItemsInfoFilePath = CZCacheFileManager.cacheFolder + "/" + CZCache.kCachedItemsInfoFile
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
        // Mem cache
        if let image = UIImage(data: data) {
            setMemCache(image: image, forKey: filePath)
        }
        
        // Disk cache
        ioQueue.async(flags: .barrier) {[weak self] in
            guard let `self` = self else {return}
            do {
                try data.write(to: URL(fileURLWithPath: filePath))
                self.setCachedItemsInfo(key: filePath, subkey: CZCache.kFileModifiedDate, value: NSDate())
                self.setCachedItemsInfo(key: filePath, subkey: CZCache.kFileVisitedDate, value: NSDate())
                self.setCachedItemsInfo(key: filePath, subkey: CZCache.kFileSize, value: data.count)
            } catch {
                assertionFailure("Failed to write file. Error - \(error.localizedDescription)")
            }
        }
    }    
    
    public func getCachedFile(withUrl url: URL, completion: @escaping (UIImage?) -> Void)  {
        operationQueue.addOperation {[weak self] in
            guard let `self` = self else {return}
            let filePath = self.cacheFilePath(forUrlStr: url.absoluteString)
            // Read data from mem cache
            var image: UIImage? = self.getMemCache(forKey: filePath)
            // Read data from disk cache
            if image == nil {
                image = self.ioQueue.sync {
                    if let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)),
                       let image = UIImage(data: data) {
                        // Set mem cache after loading data from local drive
                        self.setMemCache(image: image, forKey: filePath)
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
    
    func setCachedItemsInfo(key: String, subkey: String, value: Any) {
        cachedItemsInfoLock.writeLock {[weak self] (cachedItemsInfo) -> Void in
            guard let `self` = self else {return}
            cachedItemsInfo[key] = cachedItemsInfo[key] ?? [String: Any]()
            cachedItemsInfo[key]![subkey] = value
            print(self.cachedItemsInfoFilePath)
            (cachedItemsInfo as NSDictionary).write(to: URL(fileURLWithPath: self.cachedItemsInfoFilePath), atomically: true)
        }
    }
}

fileprivate extension CZCache {
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
    
    
    func cacheFilePath(forUrlStr urlStr: String) -> String {
        return CZCacheFileManager.cacheFolder + urlStr.MD5
    }
}
