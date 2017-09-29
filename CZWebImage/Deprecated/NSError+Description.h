//
//  NSError+Description.h
//  FlickrDemo
//
//  Created by Cheng Zhang on 12/26/16.
//  Copyright © 2016 Cheng Zhang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSError(Description)

+ (NSError *)errorWithDescription:(NSString *)description;

@end
