//
//  CZWebImageUtils.h
//
//  Created by Cheng Zhang on 1/15/16.
//  Copyright © 2016 Cheng Zhang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define weakifySelf __weak __typeof(self) weakSelf = self;

typedef void(^SDWebImageNoParamsBlock)();
typedef void(^SDWebImageWithErrorBlock)(NSError *error);
typedef void(^SDWebImagePrefetcherCompletionBlock)(NSUInteger noOfFinishedUrls, NSUInteger noOfSkippedUrls);

#define dispatch_main_sync_safe(block)\
if ([NSThread isMainThread]) {\
if (block)\
block();\
} else {\
if (block)\
dispatch_sync(dispatch_get_main_queue(), block);\
}

#define dispatch_main_async_safe(block)\
if ([NSThread isMainThread]) {\
if (block)\
block();\
} else {\
if (block)\
dispatch_sync(dispatch_get_main_queue(), block);\
}

@interface CZWebImageUtils : NSObject

+ (NSString*)documentFolder;

@end
