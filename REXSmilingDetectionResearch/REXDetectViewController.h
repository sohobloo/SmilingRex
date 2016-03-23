//
//  REXViewController.h
//  REXSmilingDetectionResearch
//
//  Created by 饶欣 on 15/12/18.
//  Copyright © 2015年 Rex Rao. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface REXDetectViewController : UIViewController

@property (nonatomic) CGFloat compressRate;
@property (strong, nonatomic, readonly) UIImage *photo;
@property (strong, nonatomic, readonly) NSData *photoData;
@property (weak, nonatomic) UIColor *themeColor;

- (void)detect;
- (void)showInfo:(NSString *)info;
- (void)showPhoto:(UIImage *)photo;

@end