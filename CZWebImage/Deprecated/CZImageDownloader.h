//
//  CZImageDownloader.h
//
//  Created by Cheng Zhang on 1/15/16.
//  Copyright © 2016 Cheng Zhang. All rights reserved.
//
//  Download images with NSOperationQueue.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define CZWebImage_observe_operations 1

typedef void (^CZImageDownloderCompletion)(UIImage *image, NSNumber *isFromDisk, NSURL *imageUrl);

typedef enum : NSUInteger {
    CZImageDownloadTypeDefault = 0,
    CZImageDownloadTypeLarge,
    CZImageDownloadTypePretech
}CZImageDownloadType;

/**
 Downloader class
 */
@interface CZImageDownloader : NSObject

+ (instancetype)sharedInstance;

/**
 Download image with url, 'NSURL'

 @param url             url description
 @param cropSize        cropSize description
 @param isLargeImage    isLargeImage description
 @param handler         handler description
 @return                nothing
 @see 'CZImageDownloader'
 */
- (void)downloadImageWithURL:(NSURL*)url
                    cropSize:(CGSize)cropSize
                downloadType:(CZImageDownloadType)downloadType
           completionHandler:(CZImageDownloderCompletion)handler;


- (void)cancelDownloadWithURL:(NSURL*)url;

@end
