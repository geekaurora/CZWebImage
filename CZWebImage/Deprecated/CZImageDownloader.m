//
//  CZImageDownloader.m
//
//  Created by Cheng Zhang on 1/15/16.
//  Copyright © 2016 Cheng Zhang. All rights reserved.
//

#import "CZImageDownloader.h"
#import "UIImage+Resize.h"
#import "UIImage+Additions.h"
#import "CZCache.h"
#import "CZOperationQueue.h"
#import "CZWebImage.h"
#import "Project-Swift-Header.h"
//#import "CZFacebook-Swift.h"
//#import "FlickrDemo-Swift.h"

#define _MAX_CONCURRENT_OPERATION_COUNT_DEFAULT 50
#define _MAX_CONCURRENT_OPERATION_COUNT_LARGE   20

@interface CZImageDownloader()

@property(nonatomic, strong)CZWebImageOperationQueueClass* defaultImageQueue;
@property(nonatomic, strong)CZWebImageOperationQueueClass* largeImageQueue;

@end

@implementation CZImageDownloader

+ (instancetype)sharedInstance {
    static dispatch_once_t token;
    static CZImageDownloader* imageDownloader;
    dispatch_once(&token, ^{
        imageDownloader = [CZImageDownloader new];
    });
    return imageDownloader;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.defaultImageQueue = [[CZWebImageOperationQueueClass alloc] init];
        self.largeImageQueue = [[CZWebImageOperationQueueClass alloc] init];

        // To execute operations serially, just set maxConcurrentOperationCount = 1
        self.defaultImageQueue.maxConcurrentOperationCount = _MAX_CONCURRENT_OPERATION_COUNT_DEFAULT;
        self.largeImageQueue.maxConcurrentOperationCount = _MAX_CONCURRENT_OPERATION_COUNT_LARGE;

#if CZWebImage_observe_operations
        [self.defaultImageQueue addObserver:self forKeyPath:@"operations" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
        [self.largeImageQueue addObserver:self forKeyPath:@"operations" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
#endif
    }
    return self;
}

#if CZWebImage_observe_operations
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if([keyPath isEqualToString:@"operations"]) {
        if (object == self.defaultImageQueue)
            NSLog(@"Default image queue size: %d", (int)[self.defaultImageQueue.operations count]);
        else if (object == self.largeImageQueue)
            NSLog(@"Large image queue size: %d", (int)[self.largeImageQueue.operations count]);
    }
}
#endif


- (void)downloadImageWithURL:(NSURL*)url
                    cropSize:(CGSize)cropSize
                downloadType:(CZImageDownloadType)downloadType
           completionHandler:(CZImageDownloderCompletion)completionHandler {
    NSString* urlString = [url absoluteString];

    /* Load from the remote server */
    [self cancelDownloadWithURL:url];

    /* Use 2 queues to avoid full occupation when loading large images */
    NSOperationQueue *queue = (downloadType ==  CZImageDownloadTypeDefault) ? self.defaultImageQueue : self.largeImageQueue;

    /* *INDENT-OFF* */
    CZImageDownloadOperation* operation = [[CZImageDownloadOperation alloc] initWithUrl:[NSURL URLWithString:urlString]
                                                                                progress:nil
                                                                                 success:^(NSURLSessionDataTask* _Nullable task, id _Nullable data) {
                                         UIImage *image = [UIImage imageWithData:data];
                                         // Resize the image if the size is specified
                                         if (!CGSizeEqualToSize(cropSize, CGSizeZero)) {
                                             image = [image resizeWithSize:cropSize];
                                         }
                                         // Save data to the local cache
                                         [[CZCache sharedInsance] cacheFileWithUrl:urlString withImage:image];
                                         
                                         // Invoke completion handler on the main thread
                                         dispatch_async(dispatch_get_main_queue(), ^{
                                             if (completionHandler)
                                                 completionHandler(image, @(false), url);
                                         });
    } failure:^(id _Nullable task, NSError * _Nullable error) {
        NSLog(@"DOWNLOAD ERROR: %@", [error localizedDescription]);
    }];
    /* *INDENT-ON* */

    switch (downloadType) {
        case CZImageDownloadTypePretech:
            operation.queuePriority = NSOperationQueuePriorityLow;
            break;
        default:
            operation.queuePriority = NSOperationQueuePriorityNormal;
            break;
    }
    [queue addOperation:operation];
}

- (void)cancelDownloadWithURL:(NSURL*)url {
    if (url == nil) return;
    NSString* urlString = [url absoluteString];
    
    NSMutableArray* toCancel = [NSMutableArray new];
    for (CZImageDownloadOperation* operation in self.defaultImageQueue.operations) {
        if ([operation isKindOfClass:[CZImageDownloadOperation class]] && [operation.url.absoluteString isEqualToString:urlString])
            [toCancel addObject:operation];
    }
    for (CZImageDownloadOperation* operation in self.largeImageQueue.operations) {
        if ([operation isKindOfClass:[CZImageDownloadOperation class]] && [operation.url.absoluteString isEqualToString:urlString])
            [toCancel addObject:operation];
    }
    for (CZImageDownloadOperation* operation in toCancel)
        [operation cancel];
}

- (void)dealloc {
    [self.defaultImageQueue cancelAllOperations];
    [self.largeImageQueue cancelAllOperations];

#if CZWebImage_observe_operations
    [self.defaultImageQueue removeObserver:self forKeyPath:@"operations"];
#endif

    self.defaultImageQueue = nil;
    self.largeImageQueue = nil;
}

@end


