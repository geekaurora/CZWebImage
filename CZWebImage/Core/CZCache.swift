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
    public typealias CleanDiskCacheCompletion = () -> Void
    fileprivate var ioQueue: DispatchQueue
    fileprivate var operationQueue: OperationQueue
    fileprivate var cachedItemsInfoLock: CZMutexLock<CachedItemsInfo>!
    fileprivate var hasCachedItemsInfoToFlushToDisk: Bool = false
    fileprivate var memCache: NSCache<NSString, UIImage>
    fileprivate var fileManager: FileManager
    fileprivate var cachedItemsInfoFileURL: URL = {
        return URL(fileURLWithPath: CZCacheFileManager.cacheFolder + "/" + CZCache.kCachedItemsInfoFile)
    }()
    fileprivate(set) var maxCacheAge: TimeInterval
    fileprivate(set) var maxCacheSize: Int
    
    fileprivate static let kCachedItemsInfoFile = "cachedItemsInfo.plist"
    fileprivate static let kFileModifiedDate = "modifiedDate"
    fileprivate static let kFileVisitedDate = "visitedDate"
    fileprivate static let kFileSize = "size"
    
    // 60 days
    fileprivate static let kMaxFileAge: TimeInterval = 60 * 24 * 60 * 60
    // 500M
    fileprivate static let kMaxCacheSize: Int = 500 * 1024 * 1024
    
    public init(maxCacheAge: TimeInterval = kMaxFileAge,
                maxCacheSize: Int = kMaxCacheSize) {
        print("cacheFolder: " + CZCacheFileManager.cacheFolder)

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
        
        // Clean cache
        cleanDiskCacheIfNeeded()
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
                self.setCachedItemsInfo(key: cacheKey, subkey: CZCache.kFileVisitedDate, value: NSDate())
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
                        self.setCachedItemsInfo(key: cacheKey, subkey: CZCache.kFileVisitedDate, value: NSDate())
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
    
    func cleanDiskCacheIfNeeded(completion: CleanDiskCacheCompletion? = nil){
        let currDate = Date()
        
        // 1. Clean disk by age
        let removeFileURLs = cachedItemsInfoLock.writeLock { (cachedItemsInfo: inout CachedItemsInfo) -> [URL] in
            var removedKeys = [String]()
            
            // Remove key if its fileModifiedDate exceeds maxCacheAge
            cachedItemsInfo.forEach { (keyValue: (key: String, value: [String : Any])) in
                if let modifiedDate = keyValue.value[CZCache.kFileModifiedDate] as? Date,
                    currDate.timeIntervalSince(modifiedDate) > self.maxCacheAge {
                    removedKeys.append(keyValue.key)
                    cachedItemsInfo.removeValue(forKey: keyValue.key)
                }
            }
            self.flushCachedItemsInfoToDisk(cachedItemsInfo)
            let removeFileURLs = removedKeys.flatMap{ self.cacheFileURL(forKey: $0) }
            return removeFileURLs
        }
        // Remove corresponding files from disk
        self.ioQueue.async(flags: .barrier) {[weak self] in
            guard let `self` = self else {return}
            removeFileURLs?.forEach {
                do {
                    try self.fileManager.removeItem(at: $0)
                } catch {
                    assertionFailure("Failed to remove file. Error - \(error.localizedDescription)")
                }
            }
        }
        
        // 2. Clean disk by maxSize setting: based on visited date (simple LRU)
        print("CacheSize: \(self.size)")
        if self.size > self.maxCacheSize {
            let expectedCacheSize = self.maxCacheSize / 2
            let expectedReduceSize = self.size - expectedCacheSize

            let removeFileURLs = cachedItemsInfoLock.writeLock { (cachedItemsInfo: inout CachedItemsInfo) -> [URL] in
                // Sort files with last visted date
                let sortedItemsInfo = cachedItemsInfo.sorted { (keyValue1: (key: String, value: [String : Any]),
                    keyValue2: (key: String, value: [String : Any])) -> Bool in
                    if let modifiedDate1 = keyValue1.value[CZCache.kFileVisitedDate] as? Date,
                        let modifiedDate2 = keyValue2.value[CZCache.kFileVisitedDate] as? Date {
                        return modifiedDate1.timeIntervalSince(modifiedDate2) < 0
                    } else {
                        fatalError()
                    }
                }
                
                var removedFilesSize: Int = 0
                var removedKeys = [String]()
                for (key, value) in sortedItemsInfo {
                    if removedFilesSize >= expectedReduceSize {
                        break
                    }
                    cachedItemsInfo.removeValue(forKey: key)
                    removedKeys.append(key)
                    let oneFileSize = (value[CZCache.kFileSize] as? Int) ?? 0
                    removedFilesSize += oneFileSize
                }
                self.flushCachedItemsInfoToDisk(cachedItemsInfo)
                return removedKeys.flatMap {self.cacheFileURL(forKey: $0)}
            }
            
            // Remove corresponding files from disk
            self.ioQueue.sync(flags: .barrier) {[weak self] in
                guard let `self` = self else {return}
                removeFileURLs?.forEach {
                    do {
                        try self.fileManager.removeItem(at: $0)
                    } catch {
                        assertionFailure("Failed to remove file. Error - \(error.localizedDescription)")
                    }
                }
            }

        }
    }
    
    var size: Int {
        return cachedItemsInfoLock.readLock {[weak self] (cachedItemsInfo: CachedItemsInfo) -> Int in
            guard let `self` = self else {return 0}
            return self.getSizeWithoutLock(cachedItemsInfo: cachedItemsInfo)
        } ?? 0
    }
}

fileprivate extension CZCache {
    func getSizeWithoutLock(cachedItemsInfo: CachedItemsInfo) -> Int {
        var totalCacheSize: Int = 0
        for (_, value) in cachedItemsInfo {
            let oneFileSize = (value[CZCache.kFileSize] as? Int)  ?? 0
            totalCacheSize += oneFileSize
        }
        return totalCacheSize
    }
    
    func loadCachedItemsInfo() -> CachedItemsInfo? {
        return NSDictionary(contentsOf: cachedItemsInfoFileURL) as? CachedItemsInfo
    }
    
    func setCachedItemsInfo(key: String, subkey: String, value: Any) {
        cachedItemsInfoLock.writeLock {[weak self] (cachedItemsInfo) -> Void in
            guard let `self` = self else {return}
            cachedItemsInfo[key] = cachedItemsInfo[key] ?? [String: Any]()
            cachedItemsInfo[key]![subkey] = value
            print(self.cachedItemsInfoFileURL)
            self.flushCachedItemsInfoToDisk(cachedItemsInfo)
        }
    }
    
    func removeCachedItemsInfo(forKey key: String) {
        cachedItemsInfoLock.writeLock {[weak self] (cachedItemsInfo) -> Void in
            guard let `self` = self else {return}
            cachedItemsInfo.removeValue(forKey: key)
            self.flushCachedItemsInfoToDisk(cachedItemsInfo)
        }
    }
    
    func flushCachedItemsInfoToDisk(_ cachedItemsInfo: CachedItemsInfo) {
        (cachedItemsInfo as NSDictionary).write(to: self.cachedItemsInfoFileURL, atomically: true)
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
    
    func cacheFileURL(forKey key: String) -> URL {
        return URL(fileURLWithPath: CZCacheFileManager.cacheFolder + key)
    }
}
