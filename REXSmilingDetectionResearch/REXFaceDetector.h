//
//  REXFaceDetector.h
//  REXSmilingDetectionResearch
//
//  Created by 饶欣 on 15/12/10.
//  Copyright © 2015年 Rex Rao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface REXFaceDetector : NSObject

- (instancetype)initWithImage:(UIImage *)image;

- (void)detectFaces;

- (UIImage *)detectedFace:(NSUInteger)index;

- (UIImage *)markedImage;

@end
