//
//  UIImage+Resize.h
//  FlickrDemo
//
//  Created by Cheng Zhang on 1/15/16.
//  Copyright © 2016 Cheng Zhang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CZImageResizer: NSObject

@end

@interface UIImage (Resize)

- (UIImage *)resizeWithSize:(CGSize)size;

@end
