//
//  CZWebImageUtils.m
//
//  Created by Cheng Zhang on 1/15/16.
//  Copyright © 2016 Cheng Zhang. All rights reserved.
//

#import <CommonCrypto/CommonDigest.h>
#import "CZWebImageUtils.h"
//#import "Base64.h"
#include <sys/types.h>
#include <sys/sysctl.h>

@implementation CZWebImageUtils

+ (NSString*)documentFolder {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docFolder = [paths objectAtIndex:0];
    return docFolder;
}

+ (NSString *)deviceModel {
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = (char *)malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithUTF8String:machine];
    free(machine);
    return platform;
}

+ (void)makeRoundCorner:(UIView*)view {
    [CZWebImageUtils makeRoundCorner:view corner:4.0];
}

+ (void)makeRoundCorner:(UIView*)view corner:(float)corner {
    [[view layer]setCornerRadius:corner];
    [view.layer setMasksToBounds:YES];
}

+ (CGSize)screenSize {
    return [UIScreen mainScreen].bounds.size;
}

@end
