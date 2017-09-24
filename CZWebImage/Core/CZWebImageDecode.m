//
//  CZWebImageDecoder.m
//  FlickrDemo
//
//  Created by Cheng Zhang on 12/24/16.
//  Copyright © 2016 Cheng Zhang. All rights reserved.
//

#import "CZWebImageDecoder.h"

@implementation UIImage (CZWebImageDecoder)

/* Main reason causes loading delay!!! */
- (UIImage *)cz_decodedImageWithImage {
    UIImage *image = self;

    // while downloading huge amount of images
    // autorelease the bitmap context
    // and all vars to help system to free memory
    // when there are memory warning.
    // on iOS7, do not forget to call
    // [[SDImageCache sharedImageCache] clearMemory];
    @autoreleasepool{
        // Do not decode animated images
        if (image.images) { return image; }

        CGImageRef imageRef = image.CGImage;

        CGImageAlphaInfo alpha = CGImageGetAlphaInfo(imageRef);
        BOOL anyAlpha = (alpha == kCGImageAlphaFirst ||
                         alpha == kCGImageAlphaLast ||
                         alpha == kCGImageAlphaPremultipliedFirst ||
                         alpha == kCGImageAlphaPremultipliedLast);

        if (anyAlpha) { return image; }

        size_t width = CGImageGetWidth(imageRef);
        size_t height = CGImageGetHeight(imageRef);

        CGColorSpaceModel imageColorSpaceModel = CGColorSpaceGetModel(CGImageGetColorSpace(imageRef));
        CGColorSpaceRef colorspaceRef = CGImageGetColorSpace(imageRef);

        bool unsupportedColorSpace = (imageColorSpaceModel == 0 || imageColorSpaceModel == -1 || imageColorSpaceModel == kCGColorSpaceModelCMYK || imageColorSpaceModel == kCGColorSpaceModelIndexed);
        if (unsupportedColorSpace)
            colorspaceRef = CGColorSpaceCreateDeviceRGB();

        CGContextRef context = CGBitmapContextCreate(NULL, width,
                                                     height,
                                                     CGImageGetBitsPerComponent(imageRef),
                                                     0,
                                                     colorspaceRef,
                                                     kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);

        // Draw the image into the context and retrieve the new image, which will now have an alpha layer
        CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
        CGImageRef imageRefWithAlpha = CGBitmapContextCreateImage(context);
        UIImage *imageWithAlpha = [UIImage imageWithCGImage:imageRefWithAlpha scale:image.scale orientation:image.imageOrientation];

        if (unsupportedColorSpace)
            CGColorSpaceRelease(colorspaceRef);

        CGContextRelease(context);
        CGImageRelease(imageRefWithAlpha);
        
        return imageWithAlpha;
    }
}

@end
