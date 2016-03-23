//
//  REXSmileDetector.h
//  REXSmilingDetectionResearch
//
//  Created by 饶欣 on 15/12/15.
//  Copyright © 2015年 Rex Rao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface REXSmileDetector : NSObject

- (instancetype)initWithImage:(UIImage *)image;

- (BOOL)detect;

- (UIImage *)markedImage;

- (UIImage *)faceImage;

- (UIImage *)smileImage;

- (int)smileScore;

@end
