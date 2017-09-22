//
//  CZWebImagePrefetcher.h
//  FlickrDemo
//
//  Created by Cheng Zhang on 12/30/16.
//  Copyright © 2016 Cheng Zhang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CZWebImageUtils.h"

@class CZWebImagePrefetcher;
@protocol CZWebImagePrefetcherDelegate;

/* To be compatible with Swift, OC protocol must start from non-capital letter... */
/* http://stackoverflow.com/questions/28165292/objective-c-protocol-to-swift-class-unrecognized-method */
@protocol czwebImagePrefetcherDelegate<CZWebImagePrefetcherDelegate>
@end

@protocol CZWebImagePrefetcherDelegate<NSObject>

@optional
/**
 * Called when an image was prefetched.
 *
 * @param imagePrefetcher The current image prefetcher
 * @param imageURL        The image url that was prefetched
 * @param finishedCount   The total number of images that were prefetched (successful or not)
 * @param totalCount      The total number of images that were to be prefetched
 */
- (void)imagePrefetcher:(CZWebImagePrefetcher *__nonnull)imagePrefetcher didPrefetchURL:(NSURL *__nonnull)imageURL finishedCount:(NSUInteger)finishedCount totalCount:(NSUInteger)totalCount;

/**
 * Called when all images are prefetched.
 * @param imagePrefetcher The current image prefetcher
 * @param totalCount      The total number of images that were prefetched (whether successful or not)
 * @param skippedCount    The total number of images that were skipped
 */
- (void)imagePrefetcher:(CZWebImagePrefetcher *__nonnull)imagePrefetcher didFinishWithTotalCount:(NSUInteger)totalCount skippedCount:(NSUInteger)skippedCount;

@end

@interface CZWebImagePrefetcher : NSObject

@property(nonatomic, weak)id<czwebImagePrefetcherDelegate> __nullable delegate;

+ (instancetype __nonnull)sharedInstance;
- (void)pretchURLs:(NSArray *__nullable)urls completion:(SDWebImagePrefetcherCompletionBlock __nullable)completion;
- (void)cancelPrefetching;

@end
