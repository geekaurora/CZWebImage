//
//  UIImage+Additions.m
//  GrouponUtils
//
//  Created by Jeff Anderson on 11/1/11.
//  Copyright (c) 2011 Groupon Inc. All rights reserved.
//

//#import "GrouponUtils.h"
#import <ImageIO/ImageIO.h>
#import "UIImage+Additions.h"

CGImageRef copyImageAndAddAlphaChannel(CGImageRef sourceImage);

@implementation UIImage (Additions)

+ (UIImage *)imageWithData:(NSData *) data scale:(CGFloat) scale forceCache:(BOOL) forceCache {
    UIImage *ret = nil;

    if (forceCache) {
        // We use ImageIO to load the image. This allows us to tell CGImage that
        // we want it to keep the decompressed pixels around as long as possible.
        // If we don't do this, then iOS may throw away the decoded pixels, and
        // then decode them each time it has to draw. iOS may still decide to throw
        // away the decompressed pixels at some point if we run low on memory,
        // but this should be the exception rather than the rule.
        NSDictionary *loadParamsDict = @{ (NSString *)kCGImageSourceShouldCache:@YES };
        CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, (__bridge CFDictionaryRef)loadParamsDict);
        if (source != nil) {
            CGImageRef cgImage = CGImageSourceCreateImageAtIndex(source, 0, (__bridge CFDictionaryRef)loadParamsDict);
            if (nil != cgImage) {
                ret = [UIImage imageWithCGImage:cgImage];
                CGImageRelease(cgImage);
            }
            CFRelease(source);
        }
    } else {
        ret = [UIImage imageWithData:data scale:scale];
    }

    return ret;
}

+ (UIImage *)scaleIfNeeded:(CGImageRef)cgimg {
    bool isRetina = [[[UIDevice currentDevice] systemVersion] intValue] >= 4 && [[UIScreen mainScreen] scale] >= 2.0;

    if (isRetina) {
        return [UIImage imageWithCGImage:cgimg scale:2.0 orientation:UIImageOrientationUp];
    } else {
        return [UIImage imageWithCGImage:cgimg];
    }
}

CGImageRef copyImageAndAddAlphaChannel(CGImageRef sourceImage) {
    CGImageRef retVal = NULL;

    size_t width = CGImageGetWidth(sourceImage);
    size_t height = CGImageGetHeight(sourceImage);

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef offscreenContext = CGBitmapContextCreate(NULL, width, height, 8, 0, colorSpace, (CGBitmapInfo)kCGImageAlphaPremultipliedFirst);

    if (offscreenContext != NULL) {
        CGContextDrawImage(offscreenContext, CGRectMake(0, 0, width, height), sourceImage);

        retVal = CGBitmapContextCreateImage(offscreenContext);
        CGContextRelease(offscreenContext);
    }

    CGColorSpaceRelease(colorSpace);

    return retVal;
}

/**
 *  Centrally crop the image with the specified rect
 *  @param rect - the specified rect to crop the image
 *  @return the cropped image with the specified rect
 */
- (UIImage *)cropToRect:(CGRect)rect {
    CGImageRef subImageRef = CGImageCreateWithImageInRect(self.CGImage, rect);
    CGRect subBounds = CGRectMake(0, 0, CGImageGetWidth(subImageRef), CGImageGetHeight(subImageRef));

    UIGraphicsBeginImageContext(subBounds.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextDrawImage(context, subBounds, subImageRef);

    UIImage *subImage = [UIImage imageWithCGImage:subImageRef];
    CGImageRelease(subImageRef);
    UIGraphicsEndImageContext();
    return subImage;
}

/**
 *  Centrally crop the image with the specified size
 *  @param size - the specified size to crop the image
 *  @return the cropped image with the specified size
 */
- (UIImage *)cropToSize:(CGSize)size {
    CGFloat ratio = size.height / size.width;

    size.width = self.size.width * self.scale;
    size.height = size.width * ratio;
    CGRect rect = CGRectMake((self.size.width * self.scale - size.width) / 2.f, (self.size.height * self.scale - size.height) / 2.f, size.width, size.height);
    return [self cropToRect:rect];
}

- (UIImage *)scaleAndCropPromoImageToSize:(CGSize)size {
    UIGraphicsBeginImageContextWithOptions(size, NO, 1.0);

    UIImage *scaledImage = nil;

    CGRect rect = CGRectMake(ceilf((self.size.width * self.scale - size.width) / 2), ceilf((self.size.height * self.scale - size.height) / 2), size.width, size.height);

    if ((rect.origin.x < 0) && (rect.origin.y < 0)) {
        // mask image size is larger than source image
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextTranslateCTM(context, 0.0, size.height);
        CGContextScaleCTM(context, 1.0, -1.0);
        CGContextDrawImage(context, CGRectMake(0.0f, 16.0 * [UIScreen mainScreen].scale, size.width, size.height), self.CGImage);

        scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    } else if ((rect.origin.x > 0) && (rect.origin.y < 0)) {
        // mask image size is larger than source image
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextTranslateCTM(context, 0.0, size.height);
        CGContextScaleCTM(context, 1.0, -1.0);
        CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, size.width, size.height), self.CGImage);

        scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    } else {
        // mask image size is smaller than source image
        CGImageRef imageRef = CGImageCreateWithImageInRect([self CGImage], rect);
        scaledImage = [UIImage imageWithCGImage:imageRef];

        CGImageRelease(imageRef);
    }

    UIGraphicsEndImageContext();
    return scaledImage;
}

- (UIImage *)imageScaledToSize:(CGSize)size {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(size.width, size.height), NO, 1.0);
    [self drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (UIImage *)scaleToSize:(CGSize)size {
    UIGraphicsBeginImageContext(size);

    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, 0.0, size.height);
    CGContextScaleCTM(context, 1.0, -1.0);

    CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, size.width, size.height), self.CGImage);

    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();
    return scaledImage;
}

- (UIImage *)imageWithMask:(UIImage *)maskImage {
    // make sure mask and self have the same size
    UIImage *scaledImage = [self scaleToSize:maskImage.size];

    CGImageRef maskRef = maskImage.CGImage;
    CGImageRef mask = CGImageMaskCreate(CGImageGetWidth(maskRef),
                                        CGImageGetHeight(maskRef),
                                        CGImageGetBitsPerComponent(maskRef),
                                        CGImageGetBitsPerPixel(maskRef),
                                        CGImageGetBytesPerRow(maskRef),
                                        CGImageGetDataProvider(maskRef), NULL, false);

    CGImageRef sourceImage = [scaledImage CGImage];

    CGImageRef masked = CGImageCreateWithMask(sourceImage, mask);

    CGImageRelease(mask);
    UIImage *maskedImage = [UIImage imageWithCGImage:masked];
    CGImageRelease(masked);

    return maskedImage;
}

- (UIImage *)imageWithMaskForPromo:(UIImage *)maskImage {
    UIImage *croppedImage = [self scaleAndCropPromoImageToSize:maskImage.size];
    CGImageRef maskRef = maskImage.CGImage;
    CGImageRef mask = CGImageMaskCreate(CGImageGetWidth(maskRef),
                                        CGImageGetHeight(maskRef),
                                        CGImageGetBitsPerComponent(maskRef),
                                        CGImageGetBitsPerPixel(maskRef),
                                        CGImageGetBytesPerRow(maskRef),
                                        CGImageGetDataProvider(maskRef), NULL, false);
    CGImageRef sourceImage = [croppedImage CGImage];
    CGImageRef imageWithAlpha = sourceImage;
    CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(sourceImage);
    BOOL copiedImageWithAlpha = NO;

    if ((alphaInfo == kCGImageAlphaNone) || (alphaInfo == kCGImageAlphaNoneSkipFirst) || (alphaInfo == kCGImageAlphaNoneSkipLast)) {
        // manually add an alpha channel
        imageWithAlpha = copyImageAndAddAlphaChannel(sourceImage);
        copiedImageWithAlpha = YES;
    }

    CGImageRef masked = CGImageCreateWithMask(imageWithAlpha, mask);
    CGImageRelease(mask);
    UIImage *maskedImage = [UIImage imageWithCGImage:masked];
    CGImageRelease(masked);

    //release imageWithAlpha if it was created using copyImageAndAddAlphaChannel
    if (copiedImageWithAlpha) {
        CGImageRelease(imageWithAlpha);
    }

    return maskedImage;
}

- (UIImage *)imageWithSidesCropped:(CGFloat)width {
    NSAssert(width <= self.size.width, @"Invalid cropping dimensions. Should be smaller than the actual image.");

    CGFloat originX = roundf((self.size.width - width) / 2.0);
    CGRect croppedRect = CGRectMake(originX, 0, width, self.size.height);
    CGImageRef croppedImageRef = CGImageCreateWithImageInRect(self.CGImage, croppedRect);

    UIImage *croppedImage = [UIImage imageWithCGImage:croppedImageRef];
    CGImageRelease(croppedImageRef);

    return croppedImage;
}

#pragma mark - Rounding the corners

// Note: Taken and modified from here: https://gist.github.com/robin/62684 (AvY)
static void addRoundedRectToPath(CGContextRef context, CGRect rect, float ovalWidth, float ovalHeight, BOOL top, BOOL bottom) {
    float fw, fh;

    if (ovalWidth == 0 || ovalHeight == 0) {
        CGContextAddRect(context, rect);
    } else {
        CGContextSaveGState(context);
        CGContextTranslateCTM(context, CGRectGetMinX(rect), CGRectGetMinY(rect));
        CGContextScaleCTM(context, ovalWidth, ovalHeight);
        fw = CGRectGetWidth(rect) / ovalWidth;
        fh = CGRectGetHeight(rect) / ovalHeight;
        CGContextMoveToPoint(context, fw, fh / 2);

        CGContextAddArcToPoint(context, fw, fh, fw / 2, fh, (top ? 1 : 0));
        CGContextAddArcToPoint(context, 0, fh, 0, fh / 2, (top ? 1 : 0));
        CGContextAddArcToPoint(context, 0, 0, fw / 2, 0, (bottom ? 1 : 0));
        CGContextAddArcToPoint(context, fw, 0, fw, fh / 2, (bottom ? 1 : 0));

        CGContextClosePath(context);
        CGContextRestoreGState(context);
    }
}

- (UIImage *)imageWithRoundCornerWidth:(int)cornerWidth height:(int)cornerHeight top:(BOOL)top bottom:(BOOL)bottom {
    int w = self.size.width;
    int h = self.size.height;

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL, w, h, 8, 4 * w, colorSpace, (CGBitmapInfo)kCGImageAlphaPremultipliedFirst);

    CGContextBeginPath(context);
    CGRect rect = CGRectMake(0, 0, self.size.width, self.size.height);
    addRoundedRectToPath(context, rect, cornerWidth, cornerHeight, top, bottom);
    CGContextClosePath(context);
    CGContextClip(context);

    CGContextDrawImage(context, CGRectMake(0, 0, w, h), self.CGImage);

    CGImageRef imageMasked = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);

    UIImage *result = [UIImage imageWithCGImage:imageMasked];
    CGImageRelease(imageMasked);

    return result;
}

- (UIImage *)imageWithGaussianBlurWeight:(NSInteger)blurWeight {
    float weight[5] = { 0.2270270270, 0.1945945946, 0.1216216216, 0.0540540541, 0.0162162162 };

    UIImage *tempBlurredImage = self;

    for (int i = 0; i < blurWeight; i++) { // blur the hell out from that image (8 times the default convolution matrix)
        // Blur horizontally
        UIGraphicsBeginImageContext(tempBlurredImage.size);
        [tempBlurredImage drawInRect:CGRectMake(0, 0, tempBlurredImage.size.width, tempBlurredImage.size.height) blendMode:kCGBlendModePlusLighter alpha:weight[0]];
        for (int x = 1; x < 5; ++x) {
            [tempBlurredImage drawInRect:CGRectMake(x, 0, tempBlurredImage.size.width, tempBlurredImage.size.height) blendMode:kCGBlendModePlusLighter alpha:weight[x]];
            [tempBlurredImage drawInRect:CGRectMake(-x, 0, tempBlurredImage.size.width, tempBlurredImage.size.height) blendMode:kCGBlendModePlusLighter alpha:weight[x]];
        }
        UIImage *horizBlurredImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        // Blur vertically
        UIGraphicsBeginImageContext(tempBlurredImage.size);
        [horizBlurredImage drawInRect:CGRectMake(0, 0, tempBlurredImage.size.width, tempBlurredImage.size.height) blendMode:kCGBlendModePlusLighter alpha:weight[0]];
        for (int y = 1; y < 5; ++y) {
            [horizBlurredImage drawInRect:CGRectMake(0, y, tempBlurredImage.size.width, tempBlurredImage.size.height) blendMode:kCGBlendModePlusLighter alpha:weight[y]];
            [horizBlurredImage drawInRect:CGRectMake(0, -y, tempBlurredImage.size.width, tempBlurredImage.size.height) blendMode:kCGBlendModePlusLighter alpha:weight[y]];
        }

        tempBlurredImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }

    return tempBlurredImage;
}

+ (UIImage *)imageWithColor:(UIColor *)color {
    return [UIImage imageWithColor:color size:CGSizeMake(1.0, 1.0)];
}

+ (UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size {
    CGRect rect = CGRectMake(0.0, 0.0, size.width, size.height);

    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return image;
}

+ (UIImage *)blurImage:(UIImage *)image {
    // create our blurred image
    CIContext *context = [CIContext contextWithOptions:nil];
    CIImage *inputImage = [CIImage imageWithCGImage:image.CGImage];

    // setting up Gaussian Blur (we could use one of many filters offered by Core Image)
    CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur"];

    [filter setValue:inputImage forKey:kCIInputImageKey];
    [filter setValue:[NSNumber numberWithFloat:10.0f] forKey:@"inputRadius"];
    CIImage *result = [filter valueForKey:kCIOutputImageKey];

    // CIGaussianBlur has a tendency to shrink the image a little,
    // this ensures it matches up exactly to the bounds of our original image
    CGImageRef cgImage = [context createCGImage:result fromRect:[inputImage extent]];

    // if you need scaling
    UIImage *resultImage = [[self class] scaleIfNeeded:cgImage];
    CFRelease(cgImage);
    return resultImage;
}

- (NSUInteger)approximateByteSize {
    return self.size.width * self.size.height * 4;
}

- (UIImage *)imageWithColor:(UIColor *)fromColor replacedByColor:(UIColor *)toColor {
    CGImageRef selfImage = [self CGImage];
    // Make a copy of ourself
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef bitmapContext = CGBitmapContextCreate(NULL,
                                                       CGImageGetWidth(selfImage),
                                                       CGImageGetHeight(selfImage),
                                                       8,
                                                       CGImageGetWidth(selfImage) * 4,
                                                       colorSpace,
                                                       kCGImageAlphaPremultipliedLast);

    CGColorSpaceRelease(colorSpace);
    CGContextDrawImage(bitmapContext,
                       CGRectMake(0.0, 0.0, CGBitmapContextGetWidth(bitmapContext), CGBitmapContextGetHeight(bitmapContext)),
                       selfImage);

    // Get RGB values of fromColor
    UInt8 fromR = 0;
    UInt8 fromG = 0;
    UInt8 fromB = 0;
    size_t fromCountComponents = CGColorGetNumberOfComponents([fromColor CGColor]);
    if (fromCountComponents == 4) {
        const CGFloat *fromComponents = CGColorGetComponents([fromColor CGColor]);
        fromR = (UInt8)floorf(fromComponents[0] * 255.0);
        fromG = (UInt8)floorf(fromComponents[1] * 255.0);
        fromB = (UInt8)floorf(fromComponents[2] * 255.0);
    }

    // Get RGB values for toColor
    UInt8 toR = 0;
    UInt8 toG = 0;
    UInt8 toB = 0;
    size_t toCountComponents = CGColorGetNumberOfComponents([toColor CGColor]);
    if (toCountComponents == 4) {
        const CGFloat *toComponents = CGColorGetComponents([toColor CGColor]);
        toR = (UInt8)floorf(toComponents[0] * 255.0);
        toG = (UInt8)floorf(toComponents[1] * 255.0);
        toB = (UInt8)floorf(toComponents[2] * 255.0);
    }

    // Now iterate through each pixel in the image, and if
    // we find the from color, replace it with the to color.
    // Note that we don't touch the alpha.
    // However, don't replace any pixels that are completely
    // transparent (alpha == 0).
    UInt8 *data = CGBitmapContextGetData(bitmapContext);
    NSUInteger bytesInContext = CGBitmapContextGetHeight(bitmapContext) * CGBitmapContextGetBytesPerRow(bitmapContext);
    for (NSUInteger i = 0; i < bytesInContext; i++) {
        if (data[i] == fromR && data[i + 1] == fromG && data[i + 2] == fromB && data[i + 3] > 0) {
            data[i] = toR;
            data[i + 1] = toG;
            data[i + 2] = toB;
        }
    }

    // Create the output image
    CGImageRef outImage = CGBitmapContextCreateImage(bitmapContext);
    UIImage *outUIImage = [UIImage imageWithCGImage:outImage scale:[self scale] orientation:[self imageOrientation]];
    CGImageRelease(outImage);
    CGContextRelease(bitmapContext);

    return outUIImage;
}

- (UIImage *)imageByStretchingHorizontalCornersWithEdgeInset:(UIEdgeInsets)edgeInset destinationWidth:(CGFloat)destinationWidth {
    /* *INDENT-OFF* */

    /*

       Image stretched horizontally as depicted below.
       -------------------------------------------------------------------------
    |          |                |              |                |           |
    | left cap | 1 px stretched | un-stretched | 1 px stretched | right cap |
    |          |                |              |                |           |
       -------------------------------------------------------------------------

       image is then stretched vertically as depicted below.
       --------------------
    |     top cap      |
    ||||||||||||||||||||||||||------------------|
    |  1 px stretched  |
    ||||||||||||||||||||||||||------------------|
    |    bottom cap    |
       --------------------

    */

    /* *INDENT-ON* */

    NSAssert(self.size.width < destinationWidth, @"Cannot scale. destinationWidth %f > self.size.width %f", destinationWidth, self.size.width);

    CGFloat originalWidth = self.size.width;
    CGFloat halfWidthOfStretchableArea = roundf((destinationWidth - originalWidth) / 2);

    UIGraphicsBeginImageContextWithOptions(CGSizeMake(originalWidth + halfWidthOfStretchableArea, self.size.height), NO, self.scale);

    // Stretch the left side.
    UIImage *leftResizableImage = [self resizableImageWithCapInsets:UIEdgeInsetsMake(0.0, edgeInset.left, 0.0, (originalWidth - edgeInset.left + 1)) resizingMode:UIImageResizingModeStretch];
    [leftResizableImage drawInRect:CGRectMake(0.0, 0.0, originalWidth + halfWidthOfStretchableArea, self.size.height)];

    // Image drawn with half stretchable area
    UIImage *leftResizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    UIGraphicsBeginImageContextWithOptions(CGSizeMake(destinationWidth, self.size.height), NO, self.scale);

    UIImage *rightResizableImage = [leftResizedImage resizableImageWithCapInsets:UIEdgeInsetsMake(0.0, (originalWidth - edgeInset.right + 1) + halfWidthOfStretchableArea, 0.0, edgeInset.right) resizingMode:UIImageResizingModeStretch];
    [rightResizableImage drawInRect:CGRectMake(0.0, 0.0, destinationWidth, self.size.height)];

    UIImage *horizontalResizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    UIImage *fullImage = [horizontalResizedImage resizableImageWithCapInsets:UIEdgeInsetsMake(edgeInset.top, 0.0, edgeInset.bottom, 0.0) resizingMode:UIImageResizingModeStretch];
    return fullImage;
}

// Mirror an image for RTL languages
- (UIImage *)imageRTL {
    if ([self respondsToSelector:@selector(imageFlippedForRightToLeftLayoutDirection)]) {
        return self.imageFlippedForRightToLeftLayoutDirection;
    }

    // support for IOS < 9
    return [UIImage imageWithCGImage:self.CGImage scale:self.scale orientation:UIImageOrientationUpMirrored];
}

+ (UIImage *)imageGradientFromColor:(UIColor *)fromColor toColor:(UIColor *)toColor size:(CGSize)size {
    CAGradientLayer *layer = [CAGradientLayer layer];

    layer.frame = CGRectMake(0, 0, size.width, size.height);
    layer.colors = @[(__bridge id)fromColor.CGColor,
                     (__bridge id)toColor.CGColor];

    UIGraphicsBeginImageContext(size);
    [layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

+ (UIImage *)imageGradientFromColor:(UIColor *)fromColor toColor:(UIColor *)toColor height:(CGFloat)height {
    return [UIImage imageGradientFromColor:fromColor toColor:toColor size:CGSizeMake(1.0, height)];
}

+ (UIImage *)imageGradientFromColor:(UIColor *)fromColor toColor:(UIColor *)toColor width:(CGFloat)width {
    return [UIImage imageGradientFromColor:fromColor toColor:toColor size:CGSizeMake(width, 1.0)];
}

+ (UIImage *)imageGradientFromColor:(UIColor *)fromColor toColor:(UIColor *)toColor forNavigationBar:(UINavigationBar *)navigationBar {
    return [UIImage imageGradientFromColor:fromColor toColor:toColor height:navigationBar.frame.size.height];
}

@end
