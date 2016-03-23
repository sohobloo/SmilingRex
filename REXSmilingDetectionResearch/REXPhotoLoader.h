//
//  REXPhotoLoader.h
//  REXSmilingDetectionResearch
//
//  Created by 饶欣 on 15/12/18.
//  Copyright © 2015年 Rex Rao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface REXPhotoLoader : NSObject

- (UIImage *)currentPhoto;

- (UIImage *)photoWithIndex:(u_int32_t)index;

- (UIImage *)prevPhoto;

- (UIImage *)nextPhoto;

- (u_int32_t)total;

- (u_int32_t)curentIndex;

- (UIImage *)randomPhoto;

@end
