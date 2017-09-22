//
//  UIView+Animation.m
//  FlickrDemo
//
//  Created by Administrator on 31/12/2016.
//  Copyright © 2016 Cheng Zhang. All rights reserved.
//

#import "UIView+Animation.h"

@implementation UIView(Animation)

#define UIVIEW_ANIMATION_DURATION 1.0f
static NSString* const kAnimation_RotateButton = @"com.flickrDemo.kAnimation_Rotation";

#pragma mark - Rotate

-(void)startRotateAnimation{
    CAKeyframeAnimation *rotateAnimation =
    [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation.y"];
    rotateAnimation.values = [NSArray arrayWithObjects:
                              [NSNumber numberWithFloat:-M_PI * 2],
                              [NSNumber numberWithFloat:0.0f],
                              nil];
    rotateAnimation.duration            = UIVIEW_ANIMATION_DURATION;
    rotateAnimation.repeatCount         = HUGE_VALF;
    rotateAnimation.calculationMode     = kCAAnimationLinear;
    rotateAnimation.removedOnCompletion = NO;
    rotateAnimation.delegate            = self;
    [self.layer addAnimation:rotateAnimation forKey:kAnimation_RotateButton];
}

-(void)stopRotateAnimation{
    int64_t delayInSeconds = UIVIEW_ANIMATION_DURATION;
    dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(delayTime, dispatch_get_main_queue(), ^{
        [self.layer removeAnimationForKey:kAnimation_RotateButton];
    });
}

#pragma mark - FadeIn

- (void)fadeInWithAnimationName:(NSString *)animationName interval:(NSTimeInterval)interval {
    CATransition *transition = [CATransition animation];
    transition.duration = interval;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionFade;
    [self.layer addAnimation:transition forKey:animationName];
}



@end
