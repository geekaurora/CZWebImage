//
//  UIImage+Resize.m
//  FlickrDemo
//
//  Created by Cheng Zhang on 1/15/16.
//  Copyright © 2016 Cheng Zhang. All rights reserved.
//

#import "UIImage+Resize.h"

@implementation CZImageResizer

+ (UIImage *)resizeImage:(UIImage *)image withSize:(CGSize)size {
    return [image resizeWithSize:size];
}

@end

@implementation UIImage (Resize)

- (UIImage *)resizeWithSize:(CGSize)size {
    UIImage* originalImage = self;
    CGSize originalsize = [originalImage size];
    
    if (originalsize.width < size.width && originalsize.height<size.height)
    {
        return originalImage;
    }
    else if(originalsize.width > size.width && originalsize.height>size.height)
    {
        CGFloat rate = 1.0;
        CGFloat widthRate = originalsize.width/size.width;
        CGFloat heightRate = originalsize.height/size.height;
        
        rate = widthRate>heightRate?heightRate:widthRate;
        
        CGImageRef imageRef = nil;
        
        // Get the original imageRef
        if (heightRate>widthRate)
        {
            imageRef = CGImageCreateWithImageInRect([originalImage CGImage], CGRectMake(0, originalsize.height/2-size.height*rate/2, originalsize.width, size.height*rate));
        }
        else
        {
            imageRef = CGImageCreateWithImageInRect([originalImage CGImage], CGRectMake(originalsize.width/2-size.width*rate/2, 0, size.width*rate, originalsize.height));
        }
        
        // Set the target context size
        UIGraphicsBeginImageContext(size);
        CGContextRef con = UIGraphicsGetCurrentContext();
        
        CGContextTranslateCTM(con, 0.0, size.height);
        CGContextScaleCTM(con, 1.0, -1.0);
        
        // Draw the original imageRef to the specified size context
        CGContextDrawImage(con, CGRectMake(0, 0, size.width, size.height), imageRef);
        
        UIImage *standardImage = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
        CGImageRelease(imageRef);
        
        return standardImage;
    }
    // Crop the side exceeding the specified size
    else if(originalsize.height>size.height || originalsize.width>size.width)
    {
        CGImageRef imageRef = nil;
        
        if(originalsize.height>size.height)
        {
            imageRef = CGImageCreateWithImageInRect([originalImage CGImage], CGRectMake(0, originalsize.height/2-size.height/2, originalsize.width, size.height));
        }
        else if (originalsize.width>size.width)
        {
            imageRef = CGImageCreateWithImageInRect([originalImage CGImage], CGRectMake(originalsize.width/2-size.width/2, 0, size.width, originalsize.height));
        }
        
        UIGraphicsBeginImageContext(size);
        CGContextRef con = UIGraphicsGetCurrentContext();
        
        CGContextTranslateCTM(con, 0.0, size.height);
        CGContextScaleCTM(con, 1.0, -1.0);
        
        CGContextDrawImage(con, CGRectMake(0, 0, size.width, size.height), imageRef);
        
        UIImage *standardImage = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
        CGImageRelease(imageRef);
        
        return standardImage;
    } else {// The size of the orginal image is the same as the specified size
        return originalImage;
    }
}

@end
