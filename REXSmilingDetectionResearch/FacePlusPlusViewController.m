//
//  FacePlusPlusViewController.m
//  REXSmilingDetectionResearch
//
//  Created by 饶欣 on 15/12/18.
//  Copyright © 2015年 Rex Rao. All rights reserved.
//

#import "FacePlusPlusViewController.h"
#import "FaceppAPI.h"

#define REX_FPP_API_KEY @""
#define REX_FPP_API_SECRET @""

@interface FacePlusPlusViewController ()

@end

@implementation FacePlusPlusViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    [FaceppAPI initWithApiKey:REX_FPP_API_KEY andApiSecret:REX_FPP_API_SECRET andRegion:APIServerRegionCN];

    // turn on the debug mode
    [FaceppAPI setDebugMode:YES];

    self.themeColor = [UIColor colorWithRed:58/255.0 green:153/255.0 blue:216/255.0 alpha:1];;
}

- (void)detect {
    UIImage *photo = self.photo.copy;
    NSData *photoData = self.photoData.copy;

    FaceppResult *result = [[FaceppAPI detection] detectWithURL:nil orImageData:photoData mode:FaceppDetectionModeNormal attribute:FaceppDetectionAttributeAll];
    if (result.success) {
        double photoWidth = [[result content][@"img_width"] doubleValue] * 0.01f;
        double photoHeight = [[result content][@"img_height"] doubleValue] * 0.01f;

        UIGraphicsBeginImageContext(photo.size);
        [photo drawAtPoint:CGPointZero];
        CGContextRef context = UIGraphicsGetCurrentContext();

        NSMutableDictionary *textAttributes = [NSMutableDictionary dictionary];
        textAttributes[NSFontAttributeName] = [UIFont systemFontOfSize:photoWidth * 5.0];
        textAttributes[NSForegroundColorAttributeName] = [UIColor redColor];

        // draw rectangle in the image
        NSUInteger faceCount = [[result content][@"face"] count];
        for (NSUInteger i = 0; i < faceCount; i++) {
            double width = [[result content][@"face"][i][@"position"][@"width"] doubleValue];
            double height = [[result content][@"face"][i][@"position"][@"height"] doubleValue];
            CGRect rect = CGRectMake(([[result content][@"face"][i][@"position"][@"center"][@"x"] doubleValue] - width / 2) * photoWidth,
                                     ([[result content][@"face"][i][@"position"][@"center"][@"y"] doubleValue] - height / 2) * photoHeight,
                                     width * photoWidth,
                                     height * photoHeight);
            CGContextSetRGBStrokeColor(context, 1, 1, 0, 1);
            CGContextSetLineWidth(context, photoWidth * 0.3f);
            CGContextStrokeRect(context, rect);

            double smileScore = [[result content][@"face"][i][@"attribute"][@"smiling"][@"value"] doubleValue];
            NSString *smileScoreText = [NSString stringWithFormat:@"%.2f", smileScore];
            CGPoint point = CGPointMake(rect.origin.x , rect.origin.y + rect.size.height);
            [smileScoreText drawAtPoint:point withAttributes:textAttributes];
        }

        UIImage *markedPhoto = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        [self showPhoto:markedPhoto];
        [self showInfo:@"✅ Complete."];
    } else {
        // some errors occurred
        NSString *errorInfo = [NSString stringWithFormat:@"❌ %@", [result error].message];
        [self showInfo:errorInfo];
    }
}

@end
