//
//  CZCache.m
//
//  Created by Cheng Zhang on 1/15/16.
//  Copyright © 2016 Cheng Zhang. All rights reserved.
//

//#import "CZFacebook-Swift.h"
#import "CZCache.h"
#import "CZWebImageUtils.h"
#import "NSString+md5String.h"
#import "CZWebImageDecoder.h"

// Reverse DNS name convension
static char* const kCZImageCacheIOQueue = "com.FlickrDemo.cacheIOQueue";
static char* const kCZImageCacheDictionary = "com.FlickrDemo.kCZImageCacheDictionary";

static const int kCZMemCacheCountLimit = 1000;
static const int kCZMemCachetotalCostLimit =  1000 * 1024 * 1024;
// 60 days
static const int kCZCacheDefaultMaxAge =  60 * 24 * 60 * 60 ;
// 500M
static const int kCZCacheDefaultMaxSize =  500 * 1024 * 1024;
//static const int kCZCacheDefaultMaxSize =  40 * 1024 * 1024;//1k

static const NSString *kCZCacheCachedItemsInfoFileName = @"cachedItemsInfo.plist";
static const NSString *kCZCachedFileModifiedDate = @"fileModifiedDate"; //NSURLContentModificationDateKey
static const NSString *kCZCachedFileVisitedDate = @"fileVisitedDate";
static const NSString *kCZCachedFileSize = @"fileSize";

@interface CZCache()

// Mapper used to query cachedItem's modifiedDate, visitedDate, diskPath. Faster than enumerate with NSDirectoryEnumerator.
@property(nonatomic, strong) NSMutableDictionary<NSString *, id> *cachedItemsInfo;
@property(nonatomic, strong)dispatch_queue_t cachedItemsInfoQueue;

@property(nonatomic, assign) NSNumber *hasCachedItemsInfoToFlushToDisk;

@property(nonatomic, strong) NSCache *memCache;
@property(nonatomic, strong) NSFileManager *fileManager;
@property(nonatomic, copy) NSString *diskCachePath;
@property(nonatomic, strong) dispatch_queue_t ioQueue;

@end

@implementation CZCache

+ (CZCache*)sharedInsance {
    static CZCache* czCache = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        czCache = [[CZCache alloc] init];
        [czCache initialSetup];
    });
    return czCache;
}

- (instancetype)init {
    if (self = [super init]) {
    }
    return self;
}

- (NSString*)cacheFolder {

    NSString *folder = _diskCachePath;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (![_fileManager fileExistsAtPath:folder]) {
            NSError *error = nil;
            [_fileManager createDirectoryAtPath:folder withIntermediateDirectories:YES attributes:nil error:&error];
            if (error) {
                NSLog(@"Fail to create cache folder: %@", [error localizedDescription]);
            } else {
                NSLog(@"Succeed to create cache folder: %@", folder);
            }
        }
    });
    return folder;
}

- (NSString*)diskPathForUrl:(NSString*)url {
    NSString *path = [NSString stringWithFormat:@"%@%@", [self cacheFolder], [url md5String]];
    return path;
}

/**
 * Initialize the main properties of cache instance.
 */
- (void)initialSetup {
    // Cache settings
    _maxCacheAge = kCZCacheDefaultMaxAge;
    _maxCacheSize = kCZCacheDefaultMaxSize;

    // disk cache folder
    _diskCachePath = [NSString stringWithFormat:@"%@/%@/", [CZWebImageUtils documentFolder], CZ_CACHE_FOLDER];

    // File manager
    _fileManager = [NSFileManager new];

    // Initialize memory cache
    _memCache = [[NSCache alloc] init];
    _memCache.countLimit = kCZMemCacheCountLimit;
    _memCache.totalCostLimit = kCZMemCachetotalCostLimit;

    // IO queue
    _ioQueue = dispatch_queue_create(kCZImageCacheIOQueue, DISPATCH_QUEUE_CONCURRENT);

    //cachedItemsInfoQueue
    _cachedItemsInfoQueue = dispatch_queue_create(kCZImageCacheDictionary, DISPATCH_QUEUE_CONCURRENT);

    // Mapper
#if true// Disable cleanup
    _cachedItemsInfo = nil;
#else
    _cachedItemsInfo = [self loadCachedItemsInfoFromDisk] ? : [NSMutableDictionary new];
#endif

    // Cleanup at initialization
    [self cleanDiskWithCompletionBlock:nil];
}

#pragma mark - CachedItemsInfo

- (NSString *)cachedItemsInfoFilePath {
    NSString *res =  [NSString stringWithFormat:@"%@/%@", [self cacheFolder], kCZCacheCachedItemsInfoFileName];
    return res;
}

- (void)removeCachedItemsInfoWithKey:(NSString *)key {
    dispatch_barrier_sync(self.cachedItemsInfoQueue, ^{// Write lock
        [self.cachedItemsInfo removeObjectForKey:key];
        [self flushCachedItemsInfoToDisk];
    });
}
- (NSMutableDictionary *)loadCachedItemsInfoFromDisk {
    _cachedItemsInfo = [NSMutableDictionary dictionaryWithContentsOfFile:[self cachedItemsInfoFilePath]];

    NSLog(@"cache size: %ld", [self getSize]);
    return _cachedItemsInfo;
}

- (void)setCachedItemsInfoWithKey:(NSString *)key subKey:(NSString *)subKey object:(id)object {
    if (object == nil) {
        return;
    }

    dispatch_barrier_sync(self.cachedItemsInfoQueue, ^{// Write lock
        if (self.cachedItemsInfo) {
            if (!self.cachedItemsInfo[key]) {
                self.cachedItemsInfo[key] = [NSMutableDictionary new];
            }
            self.cachedItemsInfo[key][subKey] = object;
            [self flushCachedItemsInfoToDisk];
        }
    });
}

- (void)flushCachedItemsInfoToDisk_dispatch {
    @synchronized (self.hasCachedItemsInfoToFlushToDisk) {
        // Save cachedItemsInfo in background thread
        // use dispatch_after to merge disk write block
        if ([self.hasCachedItemsInfoToFlushToDisk boolValue]) {
            NSLog(@"flushCachedItemsInfoToDisk");

            // Write lock: Should use barrier queue to wait for/block other blocks on isQueue, to make thread safe.
            dispatch_barrier_async(self.ioQueue, ^{
                dispatch_barrier_sync(self.cachedItemsInfoQueue, ^{// Write lock
                    [self.cachedItemsInfo writeToFile:[self cachedItemsInfoFilePath] atomically:true];
                });
            });
            self.hasCachedItemsInfoToFlushToDisk = @(false);
        }
    }
}

- (void)flushCachedItemsInfoToDisk {
    // Only set flag, cache all flushs inside 2 seconds
    @synchronized (self.hasCachedItemsInfoToFlushToDisk) {
        // Only flush to disk once every 5 seconds
        if (![self.hasCachedItemsInfoToFlushToDisk boolValue]) {
            self.hasCachedItemsInfoToFlushToDisk = @(true);

            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), self.ioQueue, ^{
                [self flushCachedItemsInfoToDisk_dispatch];
            });
        }
    }
}

#pragma mark - Cache data

- (BOOL)isFileCachedForUrl:(NSString*)url {
#if true
    __block bool fileExist = false;
    dispatch_sync(self.ioQueue, ^{
        fileExist = [_fileManager fileExistsAtPath:[self diskPathForUrl:url]];
    });
    return fileExist;
#else
    return _cachedItemsInfo[url] != nil;
#endif
}

#pragma mark - Memory cache
- (void)cacheMemWithImage:(UIImage *)image forKey:(NSString *)key {
    [self.memCache setObject:image forKey:key cost:SDCacheCostForImage(image)];
}

- (void)getCachedImageWithUrl:(NSString*)url completion:(void(^)(UIImage *imageIn))completion {
    /* Use autoReleasePool to force drain imageData, otherwise data is drained by the end of each runloop cycle */
    @autoreleasepool {
        NSString *diskPath = [self diskPathForUrl:url];
        // memCache
        __block UIImage *image = [self.memCache objectForKey:diskPath];
        if (image) {
            completion(image);
            return;
        }

        // diskCache
        /* Now use SYNC: If ASYNC ioQueue to read cached file, screen flickering!! */
        dispatch_sync(self.ioQueue, ^{
            if ([self isFileCachedForUrl: url]) {
                NSData *data =  [NSData dataWithContentsOfFile:diskPath];
                if (data) {
                    image = [UIImage imageWithData:data];
                    [self cacheMemWithImage:image forKey:url];
                }
            }
            completion(image);
        });

    }
}

- (void)cacheFileWithUrl:(NSString*)url withImage:(UIImage *)image {
    if (!image) return;

    //image = [image forceDecodeImage];
    NSString *diskPath = [self diskPathForUrl:url];

    // Memory cache
    [self cacheMemWithImage:image forKey:diskPath];

    // Disk cache
    [UIImagePNGRepresentation(image) writeToFile:diskPath atomically:YES];

    // cachedItemsInfo
    [self setCachedItemsInfoWithKey:url subKey:kCZCachedFileModifiedDate object:[NSDate date]];
    [self setCachedItemsInfoWithKey:url subKey:kCZCachedFileVisitedDate object:[NSDate date]];
    [self setCachedItemsInfoWithKey:url subKey:kCZCachedFileSize object:@([self getFileSizeWithPath:diskPath])];
}

#pragma mark - Clean mem/disck cache

/**
 * Remove all items in memory cache
 */
- (void)clearMemory {
    [self.memCache removeAllObjects];
}

/**
 * Remove all items in disk cache
 */
- (void)clearDisk {
    [self clearDiskOnCompletion:nil];
}

- (void)clearDiskOnCompletion:(SDWebImageNoParamsBlock)completion {
    // Write lock: Should use barrier queue to wait for/block other blocks on isQueue, to make thread safe.
    dispatch_barrier_async(self.ioQueue, ^{
        [_fileManager removeItemAtPath:self.diskCachePath error:nil];
        [_fileManager createDirectoryAtPath:self.diskCachePath
                withIntermediateDirectories:YES
                                 attributes:nil
                                      error:NULL];

        if (completion) {
            dispatch_main_async_safe(completion);
        }
    });
}

/**
 *  Partially remove items to satisfy cacheSize setting
 */
- (void)cleanDisk {
    [self cleanDiskWithCompletionBlock:nil];
}

- (void)removeFileWithUrl:(NSString *)url completion:(SDWebImageWithErrorBlock)completion {
    // memCache
    [self.memCache removeObjectForKey:url];

    // diskCache
    NSString *filePath = [self diskPathForUrl:url];
    // Write lock: Should use barrier queue to wait for/block other blocks on isQueue, to make thread safe.
    dispatch_barrier_async(self.ioQueue, ^{
        NSError *error = nil;
        BOOL success = [_fileManager removeItemAtPath:filePath error:&error];
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(error);
            });
        }
    });

    // cachedItemInfo
    [self removeCachedItemsInfoWithKey:url];
}

- (void)cleanDiskWithCompletionBlock:(SDWebImageNoParamsBlock)completionBlock {
    weakifySelf;
    // 1. Clean disk by age
    __block NSArray *sortedUrls;
    dispatch_barrier_sync(self.cachedItemsInfoQueue, ^{// Write lock
            sortedUrls = [self.cachedItemsInfo keysSortedByValueWithOptions:NSSortConcurrent usingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            NSDate *date1 = obj1[kCZCachedFileModifiedDate];
            NSDate *date2 = obj2[kCZCachedFileModifiedDate];
            return ([date1 timeIntervalSinceDate:date2] > 0) ? NSOrderedDescending : NSOrderedAscending;
        }];
        // Should remove serially, instead of concorrent to remove files from earlier to later
        [sortedUrls enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSDate *modifiedDate = weakSelf.cachedItemsInfo[obj][kCZCachedFileModifiedDate];
            NSDate *currentDate = [NSDate date];
            if ([currentDate timeIntervalSinceDate:modifiedDate] > weakSelf.maxCacheAge) {
                [weakSelf removeFileWithUrl:obj completion:^(NSError *error) {
                }];
            } else {
                *stop = true;
            }
        }];
    });


    // 2. Clean disk by maxSize setting: based on visited date (simple LRU)
    if ([self getSize] > self.maxCacheSize) {
        dispatch_sync(self.cachedItemsInfoQueue, ^{// Read lock
            sortedUrls = [self.cachedItemsInfo keysSortedByValueUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
                NSDate *date1 = obj1[kCZCachedFileVisitedDate];
                NSDate *date2 = obj2[kCZCachedFileVisitedDate];
                return ([date1 timeIntervalSinceDate:date2] > 0) ? NSOrderedDescending : NSOrderedAscending;
            }];
        });

        [sortedUrls enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSLog(@"cache size: %ld", [weakSelf getSize]);
            if ([weakSelf getSize] > weakSelf.maxCacheSize / 2) {
                [weakSelf removeFileWithUrl:obj completion:nil];
            } else {
                *stop = true;
            } 
        }];
    }

    // completion
    if (completionBlock) {
        completionBlock();
    }
}

- (void)dealloc {
    [self flushCachedItemsInfoToDisk];
}

#pragma mark - Cache size

- (NSUInteger)getSize {
    __block NSUInteger size = 0;
    // use SYNC to ioQueue to avoid thread condition race for same resources
    dispatch_sync(self.ioQueue, ^{
        [self.cachedItemsInfo enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            NSString *filePath = [self diskPathForUrl:key];
            size += [self getFileSizeWithPath:filePath];
        }];
        //NSDirectoryEnumerator *fileEnumerator = [_fileManager enumeratorAtPath:self.diskCachePath];
    });
    return size;
} 

- (NSUInteger)getDiskCount {
    __block NSUInteger count = 0;
    dispatch_sync(self.ioQueue, ^{
        NSDirectoryEnumerator *fileEnumerator = [_fileManager enumeratorAtPath:self.diskCachePath];
        count = [[fileEnumerator allObjects] count];
    });
    return count;
}

- (NSUInteger)getFileSizeWithPath:(NSString *)filePath {
    if (!filePath) {
        return 0;
    }
    NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
    NSUInteger size = [attrs fileSize];
    return size;
}

#pragma mark - Inline methods
    FOUNDATION_STATIC_INLINE NSUInteger SDCacheCostForImage(UIImage *image) {
        return image.size.height * image.size.width * image.scale * image.scale;
    }

@end



