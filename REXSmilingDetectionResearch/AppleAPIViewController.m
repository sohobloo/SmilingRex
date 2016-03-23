//
//  AppleAPIViewController.m
//  REXSmilingDetectionResearch
//
//  Created by 饶欣 on 15/12/8.
//  Copyright © 2015年 Rex Rao. All rights reserved.
//

#import "AppleAPIViewController.h"
#import <CoreImage/CoreImage.h>
#import <ImageIO/ImageIO.h>

@interface AppleAPIViewController ()

@end

@implementation AppleAPIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    self.themeColor = [UIColor colorWithRed:41/255.0 green:187/255.0 blue:156/255.0 alpha:1];
}

- (void)detect {
    CIContext *context = [CIContext contextWithOptions:nil];                    // 1
    NSDictionary *opts = @{ CIDetectorAccuracy : CIDetectorAccuracyHigh };      // 2
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeFace
                                              context:context
                                              options:opts];                    // 3
    
    opts = @{ CIDetectorImageOrientation : @(kCGImagePropertyOrientationUp),
              CIDetectorEyeBlink : @(YES),
              CIDetectorSmile : @(YES)
              }; // 4
    
    CIImage *photo = self.photo.CIImage ?: [CIImage imageWithCGImage:self.photo.CGImage];
    
    NSArray *features = [detector featuresInImage:photo options:opts];        // 5
    
    BOOL isSmileDetected = NO;
    for (CIFaceFeature *feature in features) {
        isSmileDetected = feature.hasSmile;
        if (isSmileDetected) {
            break;
        }
    }
    
    NSString *infoString = isSmileDetected ? @"😁 Smile detected." : @"😨 No smile detected.";
    [self showInfo:infoString];
}

@end
