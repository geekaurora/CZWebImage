//
//  CZWebImage.h
//  FlickrDemo
//
//  Created by Cheng Zhang on 12/25/16.
//  Copyright © 2016 Cheng Zhang. All rights reserved.
//

#ifndef CZWebImage_h
#define CZWebImage_h

#import "UIImageView+CZWebImage.h"
#import "CZWebImagePrefetcher.h"

#pragma mark - Major settings

/* Use CZOperationQueue or NSOperationQueue */
#define CZWEBIMAGE_USE_CZOPERATIONQUEUE 0

#pragma mark - Utils

/* DEBUG: Whether print the items in CZDispatchQueue */
#define CZWEBIMAGE_PRINT_QUEUE_ITEMS false


/* Max thread count of threadPool for CZDispatchQueue */
#define CZ_DISPATCHQUEUE_MAX_THREAD_COUNT 50

#if CZWEBIMAGE_USE_CZOPERATIONQUEUE
    //#define CZWebImageOperationQueueClass CZOperationQueue
    #define CZWebImageOperationQueueClass GPOperationQueue
#else
    #define CZWebImageOperationQueueClass NSOperationQueue
#endif

#endif
