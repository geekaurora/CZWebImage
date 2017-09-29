//
//  UIView+Animation.h
//  FlickrDemo
//
//  Created by Administrator on 31/12/2016.
//  Copyright © 2016 Cheng Zhang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView(Animation)

// Rotate
-(void)startRotateAnimation;
-(void)stopRotateAnimation;

// FadeIn
- (void)fadeInWithAnimationName:(NSString *)animationName interval:(NSTimeInterval)interval;

@end
