//
//  UIImage+Additions.h
//  GrouponUtils
//
//  Created by Jeff Anderson on 11/1/11.
//  Copyright (c) 2011 Groupon Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface UIImage (Additions)

+ (UIImage *)imageWithData:(NSData *)data scale:(CGFloat)scale forceCache:(BOOL)forceCache;
+ (UIImage *)scaleIfNeeded:(CGImageRef)cgimg;
+ (UIImage *)blurImage:(UIImage *)image;
- (UIImage *)imageWithMask:(UIImage *)maskImage;
- (UIImage *)imageWithMaskForPromo:(UIImage *)maskImage;
- (UIImage *)scaleToSize:(CGSize)size;
- (UIImage *)scaleAndCropPromoImageToSize:(CGSize)size;
- (UIImage *)imageScaledToSize:(CGSize)size;
- (UIImage *)imageWithRoundCornerWidth:(int)cornerWidth height:(int)cornerHeight top:(BOOL)top bottom:(BOOL)bottom;
- (UIImage *)imageWithGaussianBlurWeight:(NSInteger)blurWeight;
- (UIImage *)imageWithSidesCropped:(CGFloat)width;
+ (UIImage *)imageWithColor:(UIColor *)color;
+ (UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size;
- (NSUInteger)approximateByteSize;

/**
 *  returns an image with 1px stretched on the left and right after the cap value and the center unstretched.
 *  top and bottom stretched at the cap values provided as usual.
 *  @param edgeInset - edge inset to stretch.
 *  @param destinationWidth - width to stretch to.
 *  @return image stretched in the left and right
 */
- (UIImage *)imageByStretchingHorizontalCornersWithEdgeInset:(UIEdgeInsets)edgeInset destinationWidth:(CGFloat)destinationWidth;

// replace the existing color in image with a new color
- (UIImage *)imageWithColor:(UIColor *)fromColor replacedByColor:(UIColor *)toColor;

// Mirror an image for RTL languages
- (UIImage *)imageRTL;

/**
 *  Centrally crop the image with the specified size
 *  @param size - the specified size to crop the image
 *  @return the cropped image with the specified size
 */
- (UIImage *)cropToSize:(CGSize)size;

/**
 *  Centrally crop the image with the specified rect
 *  @param rect - the specified rect to crop the image
 *  @return the cropped image with the specified rect
 */
- (UIImage *)cropToRect:(CGRect)rect;

/**
 * Returns a UIImage of a gradient with the specified to / from colors and size
 * @param fromColor - The starting color of the gradient
 * @param toColor - The ending color of the gradient
 * @param height - The desired height of the image, the width will be 1 pixel wide
 */
+ (UIImage *)imageGradientFromColor:(UIColor *)fromColor toColor:(UIColor *)toColor height:(CGFloat)height;

/**
 * Returns a UIImage of a gradient with the specified to / from colors and size
 * @param fromColor - The starting color of the gradient
 * @param toColor - The ending color of the gradient
 * @param width - The desired width of the image, the height will be 1 pixel tall
 */
+ (UIImage *)imageGradientFromColor:(UIColor *)fromColor toColor:(UIColor *)toColor width:(CGFloat)width;

/**
 * Returns a UIImage of a gradient with the specified to / from colors and size
 * @param fromColor - The starting color of the gradient
 * @param toColor - The ending color of the gradient
 * @param navigationBar - Uses the nav bar height as the desired height of the image, the width will be 1 pixel wide
 */
+ (UIImage *)imageGradientFromColor:(UIColor *)fromColor toColor:(UIColor *)toColor forNavigationBar:(UINavigationBar *)navigationBar;

@end
