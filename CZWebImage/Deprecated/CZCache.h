//
//  CZCache.h
//
//  Created by Cheng Zhang on 1/15/16.
//  Copyright © 2016 Cheng Zhang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "CZWebImageUtils.h"

#define CZ_CACHE_FOLDER @"cached"

/**
 Concrete calss for disk/memory cache. 
 `cachedItemsInfo` is used to save cachedInfos:
 One cachedInfo includes url(key): fileModifiedDate/fileSize/fileVisitedDate
 
 e.g.:
     "https://img.grouponcdn.com/deal/v9rxvZ6LnwS21BBUEEtSEDG6F6U/v9-4653x2791/v1/t300x182.jpg" =     {
     fileModifiedDate = "2017-02-13 23:04:58 +0000";
     fileSize = 142805;
     fileVisitedDate = "2017-02-13 23:04:58 +0000";
     };

 1. Image Size: 1.5M for HD picture

 2. Cache Path: _diskCachePath
 app/Documents/cached
 e.g. /Users/czhang/Library/Developer/CoreSimulator/Devices/1FC1A2B8-D207-42D7-BFC0-C6A6DACF09B2/data/Containers/Data/Application/EBC12655-8BEF-4929-A98C-90FDE93CA235/Documents/cached/

 3. Clean cache: 
 Clean till the left size <= 0.5 * kCZCacheDefaultMaxSize

 */

@interface CZCache : NSObject

//@name basic properties
/// Max time to keep an item in cache, in second
@property(nonatomic, assign) NSUInteger maxCacheAge;
/// Max size of the cache, in bytes
@property(nonatomic, assign) NSUInteger maxCacheSize;

+ (CZCache*)sharedInsance;
- (NSString*)diskPathForUrl:(NSString*)url;
- (void)getCachedImageWithUrl:(NSString*)url completion:(void(^)(UIImage *imageIn))completion;
- (void)cacheFileWithUrl:(NSString*)url withImage:(UIImage *)image;

#pragma mark - Clean mem/disck cache
/**
 @abstract 2Remove all items in memory cache
 @see CZCache
 @warning should not be used in multiple-thread
 */
- (void)clearMemory;

/*
 * Remove all items in disk cache
 */
- (void)clearDisk;

- (void)clearDiskOnCompletion:(SDWebImageNoParamsBlock)completion;

/**
 *  Partially remove items to satisfy cacheSize setting
 */
- (void)cleanDisk;

@end
