//
//  DownloadItem.m
//  MangaKeeper
//
//  Created by Florian on 31/12/13.
//  Copyright (c) 2013 Florian Morel. All rights reserved.
//

#import "DownloadItem.h"
#import "NotificationManager.h"

@interface DownloadItem ()

@property (strong, nonatomic) NSMutableData *data;
@property (strong, nonatomic) NSURLConnection *connection;
@property (assign, nonatomic) NSInteger expectedBytes;
@property (assign, nonatomic) BOOL executing;
@property (assign, nonatomic) BOOL finished;
@property (strong, nonatomic) NSString *directory;

@end

@implementation DownloadItem

- (id)initWithURL:(NSString *)url andDirectory:(NSString *)directory {
    if(self = [super init]) {
        self.url = [NSURL URLWithString:url];

        NSArray *urlParts = [url componentsSeparatedByString:@"/"];
        self.fileName = [NSString stringWithFormat:@"%@/%@", directory, [urlParts lastObject]];
        self.directory = directory;
    }
    return self;
}

- (void)start {
    if(![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(start) withObject:Nil waitUntilDone:NO];
        return;
    }
    
    if(self.finished || self.isCancelled) {
        [self done];
        return;
    }
    
    [self willChangeValueForKey:@"isExecuting"];
    self.executing = YES;
    [self didChangeValueForKey:@"isExecuting"];

    self.progress = 0;

    NSURLRequest *request = [NSURLRequest requestWithURL:self.url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:60];
    self.data = [[NSMutableData alloc] initWithLength:0];
    self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
}

- (void)done {
    if(self.connection) {
        [self.connection cancel];
        self.connection = nil;
    }
    
    self.delegate = nil;
    
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    self.executing = NO;
    self.finished = YES;
    [self didChangeValueForKey:@"isFinished"];
    [self didChangeValueForKey:@"isExecuting"];
}

#pragma NSOperation overrides

- (void)cancel {
    self.data = nil;
    [self.connection cancel];
    [super cancel];
}

- (BOOL)isConcurrent {
    return YES;
}

- (BOOL)isExecuting {
    return self.executing;
}

- (BOOL)isFinished {
    return self.finished;
}

#pragma NSURLConnection delegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    if(self.isCancelled) {
        [self done];
        return;
    }
    
    self.data.length = 0;
    self.expectedBytes = [response expectedContentLength];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    if(self.isCancelled) {
        [self done];
        return;
    }
    
    [self.data appendData:data];
    self.progress = (CGFloat)[self.data length] / (CGFloat)self.expectedBytes;
    [self.delegate progressDidUpdate:self.progress];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    if(self.isCancelled) {
        [self done];
        return;
    }

    [[NotificationManager sharedInstance] showDownloadFailedNotificationWithDetails:[self.fileName stringByReplacingOccurrencesOfString:self.directory withString:@""]];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
    return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    if(self.isCancelled) {
        [self done];
        return;
    }
    
    NSUserDefaults *userPreferences = [NSUserDefaults standardUserDefaults];
    NSString *downloadDirectory = [userPreferences stringForKey:@"downloadDirectory"];
    NSString *chapterPath = [downloadDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", self.directory]];
    NSString *filePath = [downloadDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", self.fileName]];
    
    BOOL isDir;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if(![fileManager fileExistsAtPath:chapterPath isDirectory:&isDir]) { // Pref download file + chapter title
        if(![fileManager createDirectoryAtPath:chapterPath withIntermediateDirectories:YES attributes:nil error:NULL]) {
            NSLog(@"Error: Create folder failed %@", chapterPath);
        }
    }

    [self.data writeToFile:filePath atomically:YES];
    [self done];
}

@end
