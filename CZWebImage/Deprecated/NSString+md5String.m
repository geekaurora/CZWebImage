//
//  md5String.m
//  FlickrDemo
//
//  Created by Administrator on 28/12/2016.
//  Copyright © 2016 Cheng Zhang. All rights reserved.
//

#import "NSString+md5String.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSString(md5String)

- (NSString *)md5String {
    const char *str = [self UTF8String];
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, strlen(str), r);
    return [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x", r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10], r[11], r[12], r[13], r[14], r[15]];
}

@end
