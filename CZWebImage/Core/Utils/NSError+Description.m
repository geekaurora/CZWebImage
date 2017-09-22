//
//  NSError+Description.m
//  FlickrDemo
//
//  Created by Cheng Zhang on 12/26/16.
//  Copyright © 2016 Cheng Zhang. All rights reserved.
//

#import "NSError+Description.h"

@implementation NSError(Description)

+ (NSError *)errorWithDescription:(NSString *)description {
    // @"Connection can't be initialized"@
    return [NSError errorWithDomain:NSURLErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey: description ? : @""}];
}

@end
