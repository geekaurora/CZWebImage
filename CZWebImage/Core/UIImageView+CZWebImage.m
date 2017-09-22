//
//  UIImageView+CZWebImage.m
//  FlickrDemo
//
//  Created by Cheng Zhang on 12/24/16.
//  Copyright © 2016 Cheng Zhang. All rights reserved.
//

#import "UIImageView+CZWebImage.h"
//#import "FlickrDemo-Swift.h"
//#import "UIImageView+WebCache.h"
#import "CZCache.h"
#import "objc/runtime.h"
#import "UIView+Animation.h"
#import <CZWebImage/CZWebImage-Swift.h>

static char imageURLKey;
const NSTimeInterval _CZWebImageFadeTime = 0.4;
const NSString *_CZWebImageFadeAnimationKey = @"com.jason.CZWebImageFadeAnimationKey";

@implementation UIImageView(CZWebImage)

/**
 Load large image after loading default image
 @param cropSize - The image will be cropped to the specific size
 */
- (void)fetchImageWithDefaultImageUrl:(NSString* __nullable)defaultImageUrl
                        largeImageUrl:(NSString* __nullable)largeImageUrl
                     placeholderImage:(UIImage * __nullable)placeholderImage
                    completionHandler:(SDWebImageWithErrorBlock __nullable)completionHandler {
    [self fetchImageWithDefaultImageUrl:defaultImageUrl
                          largeImageUrl:largeImageUrl
                       placeholderImage:placeholderImage
                               cropSize:CGSizeZero
                                 fadeIn:true
                      completionHandler:completionHandler];
}

- (void)fetchImageWithDefaultImageUrl:(NSString*)defaultImageUrl
                        largeImageUrl:(NSString*)largeImageUrl
                     placeholderImage:(UIImage * __nullable)placeholderImage
                             cropSize:(CGSize)cropSize
                               fadeIn:(BOOL)fadeIn
                    completionHandler:(SDWebImageWithErrorBlock)completionHandler {
    dispatch_block_t loadFromRemoteServerBlock = ^{
        [self fetchImageWithUrl:defaultImageUrl
               placeholderImage:placeholderImage
                       cropSize:CGSizeZero
                         fadeIn:fadeIn
                   isLargeImage:NO
              completionHandler:^(NSError *error) {
            if (largeImageUrl)
                [self fetchImageWithUrl:largeImageUrl
                       placeholderImage:placeholderImage
                               cropSize:cropSize
                                 fadeIn:false
                           isLargeImage:YES
                      completionHandler:completionHandler];
        }];
    };

    // 1. load largeImage from local cache
    if (largeImageUrl) {
        [[CZCache sharedInsance] getCachedImageWithUrl:largeImageUrl completion:^(UIImage *image) {
            if (image) {
                [self setWebImage:image completionHandler:completionHandler];
                return;
            }
            loadFromRemoteServerBlock();
        }];
    } else {
        // 2. load from remote server
        loadFromRemoteServerBlock();
    }
}

- (void)fetchImageWithUrl:(NSString*)imageUrl
         placeholderImage:(UIImage *)placeholderImage
                 cropSize:(CGSize)cropSize
                   fadeIn:(BOOL)fadeIn
             isLargeImage:(BOOL)isLargeImage
        completionHandler:(SDWebImageWithErrorBlock)completionHandler
{
    if (!isLargeImage) {
        dispatch_main_async_safe(^{
            self.image = placeholderImage ? : nil;
        })
    }

    if (imageUrl == nil) {
        dispatch_main_async_safe(^{
            NSError *error = [NSError new];
            completionHandler(error);
        });
        return;
    }

    // Cancel the previous downloading operation
    [self cz_cancelCurrentImageLoad];
    
    self.imageUrl = imageUrl;

    __weak __typeof(self) weakView = self;
    // Use __block to update values inside the block, otherwise once enter the block whose scope is on the stack instead of heap, the value will not change correspoindingly
    __block CGSize size = cropSize;
    if (CGSizeEqualToSize(cropSize, CGSizeZero)) {
        //size = CGSizeMake(weakView.bounds.size.width * 2, weakView.bounds.size.height * 2);
    }

    [[CZWebImageManager sharedInstance] downloadImageWithURL: [NSURL URLWithString:self.imageUrl]
                                              cropSize:size
                                            downloadType:isLargeImage ? CZImageDownloadTypeLarge : CZImageDownloadTypeDefault
                                          completionHandler:^(UIImage *image, NSNumber *isFromDisk, NSURL *imageUrlIn) {
                                              if (weakView && [weakView.imageUrl isEqualToString:[imageUrlIn absoluteString]]) {
                                                  if (fadeIn) {
                                                      [self fadeInWithAnimationName:_CZWebImageFadeAnimationKey
                                                                           interval:_CZWebImageFadeTime];
                                                  }
                                                  [weakView setWebImage:image completionHandler:completionHandler];
                                              }
                                          }];
}

- (void)cz_cancelCurrentImageLoad {
    if (self.imageUrl) {
        [[CZWebImageManager sharedInstance] cancelDownloadWithURL: [NSURL URLWithString:self.imageUrl]];
    }
}

- (void)dealloc {
    [self cz_cancelCurrentImageLoad];
}

#pragma mark - Private method
- (void)setImageUrl:(NSString *)imageUrl {
    // @selector(setImageUrl) is address of the function = baseAddressOfInstance + functionOffsetInFunctionTable: it's unique for each instance
    objc_setAssociatedObject(self, @selector(setImageUrl), imageUrl, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)imageUrl {
    return objc_getAssociatedObject(self, @selector(setImageUrl));
}

- (void)setWebImage:(UIImage *)image completionHandler:(SDWebImageWithErrorBlock)completionHandler {
    dispatch_main_sync_safe(^{
        self.image = image;
        [self layoutIfNeeded];
        [self setNeedsLayout];

        if (completionHandler)
            completionHandler(nil);
    });
    
}
@end
