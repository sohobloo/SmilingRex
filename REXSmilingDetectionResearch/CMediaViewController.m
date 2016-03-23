//
//  CMediaViewController.m
//  REXSmilingDetectionResearch
//
//  Created by 饶欣 on 15/12/15.
//  Copyright © 2015年 Rex Rao. All rights reserved.
//

#import "CMediaViewController.h"
#import "REXSmileDetector.h"

@interface CMediaViewController ()

@end

@implementation CMediaViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    self.themeColor = [UIColor colorWithRed:141/155.0 green:89/255.0 blue:167/255.0 alpha:1];;
}

- (void)detect {
    REXSmileDetector *smileDetector = [[REXSmileDetector alloc] initWithImage:self.photo];
    NSString *infoString;
    BOOL isDetected = [smileDetector detect];
    if (isDetected) {
        UIImage *markedPhoto = [smileDetector markedImage];
        [self showPhoto:markedPhoto];
        //UIImage *faceImage = [smileDetector faceImage];
        //UIImage *smileImage = [smileDetector smileImage];
        int smileScore = [smileDetector smileScore];
        
        infoString = [NSString stringWithFormat:@"😄 Smile score: %d", smileScore];
    } else {
        infoString = @"😫 Not smiling.";
    }
    
    [self showInfo:infoString];
}

@end
