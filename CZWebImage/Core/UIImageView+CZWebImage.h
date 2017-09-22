//
//  UIImageView+CZWebImage.h
//  FlickrDemo
//
//  Created by Cheng Zhang on 12/24/16.
//  Copyright © 2016 Cheng Zhang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CZCache.h"

@interface UIImageView(CZWebImage)

// Use runtime function objc_setAssociatedObject/objc_getAssociatedObject to add property to category.
@property(nonatomic, copy)NSString * __nullable imageUrl;

/**
 *  Load large image after loading default image
 *  @param cropSize - The image will be cropped to the specific size
 */
- (void)fetchImageWithDefaultImageUrl:(NSString* __nullable)defaultImageUrl
                        largeImageUrl:(NSString* __nullable)largeImageUrl
                     placeholderImage:(UIImage * __nullable)placeholderImage
                    completionHandler:(SDWebImageWithErrorBlock __nullable)completionHandler;

- (void)fetchImageWithDefaultImageUrl:(NSString* __nullable)defaultImageUrl
                        largeImageUrl:(NSString* __nullable)largeImageUrl
                     placeholderImage:(UIImage * __nullable)placeholderImage
                             cropSize:(CGSize)cropSize
                               fadeIn:(BOOL)fadeIn
                    completionHandler:(SDWebImageWithErrorBlock __nullable)completionHandler;

- (void)cz_cancelCurrentImageLoad;

@end
