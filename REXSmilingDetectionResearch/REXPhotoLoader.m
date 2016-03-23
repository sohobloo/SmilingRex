//
//  REXPhotoLoader.m
//  REXSmilingDetectionResearch
//
//  Created by 饶欣 on 15/12/18.
//  Copyright © 2015年 Rex Rao. All rights reserved.
//

#import "REXPhotoLoader.h"

#define REX_TOTAL_PHOTO_COUNT 10

@implementation REXPhotoLoader {
    u_int32_t _photoIndex;
    UIImage *_currentPhoto;
}

- (UIImage *)currentPhoto {
    return _currentPhoto;
}

- (UIImage *)photoWithIndex:(u_int32_t)index {
    [self changeIndex:index];
    [self loadPhoto];
    return _currentPhoto;
}

- (UIImage *)prevPhoto {
    return [self photoWithIndex:--_photoIndex];
}

- (UIImage *)nextPhoto {
    return [self photoWithIndex:++_photoIndex];
}

- (u_int32_t)total {
    return REX_TOTAL_PHOTO_COUNT;
}

- (u_int32_t)curentIndex {
    return _photoIndex;
}

- (UIImage *)randomPhoto {
    return [self photoWithIndex:(arc4random() % REX_TOTAL_PHOTO_COUNT)];
}

- (void)changeIndex:(u_int32_t)index {
    if (index == UINT32_MAX) {
        _photoIndex = REX_TOTAL_PHOTO_COUNT - 1;
    } else if (index >= REX_TOTAL_PHOTO_COUNT) {
        _photoIndex = 0;
    } else {
        _photoIndex = index;
    }
}

- (BOOL)loadPhoto {
    NSString *photoFileName = [NSString stringWithFormat:@"%u.jpg", _photoIndex];
    _currentPhoto = [UIImage imageNamed:photoFileName];
    return _currentPhoto != nil;
}

@end
