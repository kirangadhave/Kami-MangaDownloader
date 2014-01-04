//
//  ChapterDowloadQueue.h
//  MangaKeeper
//
//  Created by Florian on 02/01/14.
//  Copyright (c) 2014 Florian Morel. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ChapterModel.h"
#import "DownloadManagerDelegate.h"

@interface ProgressDownloadQueue : NSOperationQueue

@property (strong, nonatomic) NSString *title;
@property (assign, nonatomic) CGFloat progress;
@property (weak, nonatomic) ChapterModel *chapter;
@property (weak, nonatomic) id<DownloadManagerDelegate> delegate;

- (void)queueIsReady;

@end
