//
//  DownloadItem.m
//  MangaKeeper
//
//  Created by Florian on 31/12/13.
//  Copyright (c) 2013 Florian Morel. All rights reserved.
//

#import "DownloadItem.h"

@interface DownloadItem ()

@property (strong, nonatomic) NSMutableData *data;
@property (strong, nonatomic) NSURLConnection *connection;
@property (assign, nonatomic) NSInteger expectedBytes;

@end

@implementation DownloadItem

- (id)initWithURL:(NSString *)url andDirectory:(NSString *)directory {
    if(self = [super init]) {
        self.url = [NSURL URLWithString:url];

        NSArray *urlParts = [url componentsSeparatedByString:@"/"];
        self.fileName = [NSString stringWithFormat:@"%@/%@", directory, [urlParts lastObject]];
    }
    return self;
}

- (void)start {
    NSLog(@"Starting to download %@", self.url);
    self.progress = 0;

    NSURLRequest *request = [NSURLRequest requestWithURL:self.url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:60];
    self.data = [[NSMutableData alloc] initWithLength:0];
    self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
}

#pragma NSOperation overrides

- (void)cancel {
    self.data = nil;
    [self.connection cancel];
    [super cancel];
}

#pragma NSURLConnection delegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    self.data.length = 0;
    self.expectedBytes = [response expectedContentLength];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.data appendData:data];
    self.progress = (CGFloat)[self.data length] / (CGFloat)self.expectedBytes;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"Download failed with error %@", error);
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
    return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSUserDefaults *userPreferences = [NSUserDefaults standardUserDefaults];
    NSString *downloadDirectory = [userPreferences stringForKey:@"downloadDirectory"];
    NSString *filePath = [downloadDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", self.fileName]];

    [self.data writeToFile:filePath atomically:YES];
    [self.delegate itemDidCompleteDownload:self];
}

@end
