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

    fileprivate(set) var maxCacheAge: UInt
    fileprivate(set) var maxCacheSize: UInt
    
    fileprivate static let kCZCacheCachedItemsInfoFileName = "cachedItemsInfo.plist"
    fileprivate static let kCZCachedFileModifiedDate = "modifiedDate"
    fileprivate static let kCZCachedFileVisitedDate = "visitedDate"
    fileprivate static let kCZCachedFileSize = "size"
    
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
        // Mem Cache
        if let image = UIImage(data: data) {
            cacheMem(image: image, forKey: filePath)
        }
        
        // Disk Cache
        ioQueue.async(flags: .barrier) {[weak self] in
            guard let `self` = self else {return}
            do {
                try data.write(to: URL(fileURLWithPath: filePath))
                self.setCachedItemsInfo(key: filePath, subkey: CZCache.kCZCachedFileModifiedDate, value: NSDate())
                self.setCachedItemsInfo(key: filePath, subkey: CZCache.kCZCachedFileVisitedDate, value: NSDate())
                self.setCachedItemsInfo(key: filePath, subkey: CZCache.kCZCachedFileSize, value: data.count)
            } catch {
                assertionFailure("Failed to write file. Error - \(error.localizedDescription)")
            }
        }
    }    
    
    public func getCachedFile(withUrl url: URL, completion: @escaping (UIImage?) -> Void)  {
        operationQueue.addOperation {[weak self] in
            guard let `self` = self else {return}
            let filePath = self.cacheFilePath(forUrlStr: url.absoluteString)
            var image: UIImage? = self.memCache.object(forKey: NSString(string: filePath))
            if image == nil {
                image = self.ioQueue.sync {
                    do {
                        let url = URL(fileURLWithPath: filePath)
                        print(url)
                        let data = try Data(contentsOf: url)
                        let image = UIImage(data: data)
                        return image
                    } catch {
                        //assertionFailure("Failed to read file. Error - \(error.localizedDescription)")
                    }
                    return nil
                }
            }
            CZMainQueueScheduler.async {
                completion(image)
            }
        }
    }
    
    func setCachedItemsInfo(key: String, subkey: String, value: Any) {
        cachedItemsInfoLock.writeLock { (cachedItemsInfo) -> Void in
            cachedItemsInfo[key] = cachedItemsInfo[key] ?? [String: Any]()
            cachedItemsInfo[key]![subkey] = value
        }
    }
}

fileprivate extension CZCache {
    func cacheMem(image: UIImage, forKey key: String) {
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
