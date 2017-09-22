//
//  CZCache.swift
//  CZWebImage
//
//  Created by Cheng Zhang on 9/22/17.
//  Copyright © 2017 Cheng Zhang. All rights reserved.
//

import UIKit
import CZNetworking

@objc class CZCache: NSObject {
    static let sharedInsance = CZCache()
    
    fileprivate var ioQueue: DispatchQueue
    
    fileprivate var cachedItemsInfoLock: CZMutexLock<[String: Any]>
    fileprivate var hasCachedItemsInfoToFlushToDisk: Bool = false
    fileprivate var memCache: NSCache<NSString, UIImage>
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
    
    @objc init(maxCacheAge: UInt = 0, maxCacheSize: UInt = 0) {
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
    
    func cacheFilePath(forUrlStr urlStr: String) -> String {
        return CZCache.cacheFolder + urlStr.MD5
    }
    
    @objc(cacheFileWithUrl:withImage:)
    func cacheFile(with urlStr: String, image: UIImage?) {
        guard let image = image else {return}
        let filePath = cacheFilePath(forUrlStr: urlStr)
        
        cacheMem(image: image, forKey: filePath)
    }
    
    //- (void)getCachedImageWithUrl:(NSString*)url completion:(void(^)(UIImage *imageIn))completion
    @objc(getCachedImageWithUrl:completion:)
    func getFile(with urlStr: String, completion: (UIImage?) -> Void)  {
        let image = memCache.object(forKey: NSString(string: urlStr))
        completion(image)
    }
    
    func cacheMem(image: UIImage, forKey key: String) {
        memCache.setObject(image,
                           forKey: NSString(string: key),
                           cost: cacheCost(forImage: image))
    }
}

fileprivate extension CZCache {
    func cacheCost(forImage image: UIImage) -> Int {
        return Int(image.size.height * image.size.width * image.scale * image.scale)
    }
}
