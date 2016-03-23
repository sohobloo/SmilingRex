//
//  REXFaceDetector.m
//  REXSmilingDetectionResearch
//
//  Created by 饶欣 on 15/12/10.
//  Copyright © 2015年 Rex Rao. All rights reserved.
//

#ifdef __cplusplus
#import <opencv2/opencv.hpp>
#endif

#import "REXFaceDetector.h"

using namespace cv;

@implementation REXFaceDetector {
    UIImage *_image;
    CGFloat _scale;
    
    CascadeClassifier _faceDetector;
    CascadeClassifier _smileDetector;
    
    cv::Mat _mat;
    cv::Mat _grayMat;
    
    std::vector<cv::Rect> _faceRects;
    std::vector<cv::Mat> _faceMats;
    
    NSArray *_faceImages;
    NSMutableDictionary *_smileImages;
}

- (instancetype)initWithImage:(UIImage *)image {
    if (self = [super init]) {
        _image = image;
        _scale = [UIScreen mainScreen].scale;
        
        const NSString *faceCascadePath = [[NSBundle mainBundle] pathForResource:@"haarcascade_frontalface_alt2"
                                                                    ofType:@"xml"];
        const NSString *smileCascadePath = [[NSBundle mainBundle] pathForResource:@"haarcascade_smile" ofType:@"xml"];
        
        const CFIndex CASCADE_NAME_LEN = 2048;
        char *CASCADE_NAME = (char *) malloc(CASCADE_NAME_LEN);
        
        CFStringGetFileSystemRepresentation( (CFStringRef)faceCascadePath, CASCADE_NAME, CASCADE_NAME_LEN);
        
        _faceDetector.load(CASCADE_NAME);
        
        CFStringGetFileSystemRepresentation( (CFStringRef)smileCascadePath, CASCADE_NAME, CASCADE_NAME_LEN);
        _smileDetector.load(CASCADE_NAME);
        
        free(CASCADE_NAME);
        
        _smileImages = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)detectFaces {
    _mat = [self cvMatFromUIImage:_image];
    cvtColor(_mat, _grayMat, COLOR_BGR2GRAY);
    
    double scalingFactor = 1.1;
    int minNeighbors = 2;
    int flags = 0;
    cv::Size minSize(30, 30);
    cv::Size maxSize(_mat.rows, _mat.cols);
    
    _faceDetector.detectMultiScale(
                                   _grayMat,
                                   _faceRects,
                                   scalingFactor,
                                   minNeighbors,
                                   flags,
                                   minSize
                                   );
    
    std::vector<cv::Mat> faceMats;
    NSMutableArray *faceImages = [NSMutableArray array];
    
    for( int i = 0; i < (int)(_faceRects).size(); i++ ) {
        NSLog(@"face detected: %d", i);
        
        cv::Rect faceRect = _faceRects[i];
        cv::Mat faceMat = _mat(faceRect);
        
        //UIImage *testFace = [self UIImageFromCVMat:faceMat.clone()];
        
        BOOL isSmileDelected = [self detectSmile:i faceMat:faceMat.clone() faceRect:faceRect];
        if (isSmileDelected) {
            rectangle(_mat,
                      cvPoint(faceRect.x, faceRect.y),
                      cvPoint(faceRect.x + faceRect.width, faceRect.y + faceRect.height),
                      CV_RGB(0
                             , 255, 255), 2, 8, 0);
            
            UIImage *faceImage = [self UIImageFromCVMat:faceMat.clone()];
            
            _faceMats.push_back(faceMat.clone());
            [faceImages addObject:faceImage];
        }
    }
    
    @synchronized(self) {
        _faceMats = faceMats;
        _faceImages = faceImages;
    }
}

- (BOOL)detectSmile:(NSUInteger)index faceMat:(cv::Mat)faceMat faceRect:(cv::Rect)faceRect {
    cv::Rect cropRect(0, faceRect.height / 2, faceRect.width, faceRect.height / 2);
    faceMat = faceMat(cropRect);
    
    std::vector<cv::Rect> smileRects;
    std::vector<int> rejectLevels;
    std::vector<double> levelWeights;
    
    double scalingFactor = 1.1;
    int minNeighbors = 2;
    int flags = 0;
    cv::Size minSize(faceRect.width / 5, faceRect.height / 10);
    cv::Size maxSize(faceRect.width, faceRect.height);
    bool outputRejectLevels = true;
    
    _smileDetector.detectMultiScale(
                                   faceMat,
                                   smileRects,
                                   rejectLevels,
                                   levelWeights,
                                   scalingFactor,
                                   minNeighbors,
                                   flags,
                                   minSize,
                                   maxSize,
                                   outputRejectLevels
                                   );
    
    std::vector<cv::Mat> smileMats;
    UIImage *smileImage;
    
    double maxWeight = DBL_MIN;
    int finalIndex = -1;
    
    for( int i = 0; i < (int)(smileRects).size(); i++ ) {
        double weight = levelWeights[i];
        NSLog(@"smile detected: %d-%d, reject:%d, weight:%.2f", (int)index, i, rejectLevels[i], weight);
        if (weight < maxWeight) {
            continue;
        }
        
        maxWeight = weight;
        finalIndex = i;
    }
    
    if (finalIndex >= 0) {
        cv::Rect smileRect = smileRects[finalIndex];
        cv::Mat smileMat = faceMat(smileRect);
        
        int smilePoint = [self smilePointFromWeight:maxWeight];
        
        int x = faceRect.x + smileRect.x;
        int y = faceRect.y + faceRect.height / 2 + smileRect.y;
        
        cv::Point p1 = cvPoint(x, y);
        cv::Point p2 = cvPoint(x + smileRect.width, y + smileRect.height);
        cv::Point p3 = cvPoint(x, y - 2);
        
        rectangle(_mat, p1, p2,
                  CV_RGB(255, 0, 255), 2,
                  8, 0);
        
        putText(_mat, std::to_string(smilePoint), p3,
                1, _scale, CV_RGB(0, 0, 255),
                2, FILLED,
                false);
        
        smileImage = [self UIImageFromCVMat:smileMat.clone()];
        
        smileMats.push_back(smileMat.clone());
    }
    
    @synchronized(self) {
        _smileImages[@(index)] = smileImage;
    }
    
    return finalIndex >= 0;
}

- (UIImage *)detectedFace:(NSUInteger)index {
    if (_faceImages && _faceImages.count > 0 && index < _faceImages.count) {
        return _faceImages[index];
    }
    
    return nil;
}

- (UIImage *)markedImage {
    return [self UIImageFromCVMat:_mat.clone()];
}

- (cv::Mat)cvMatFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}

- (cv::Mat)cvMatGrayFromUIImage:(UIImage *)image
{
    cv::Mat cvMat = [self cvMatFromUIImage:image];
    cv::Mat grayMat;
    if ( cvMat.channels() == 1 ) {
        grayMat = cvMat;
    }
    else {
        grayMat = cv :: Mat( cvMat.rows,cvMat.cols, CV_8UC1 );
        cv::cvtColor( cvMat, grayMat, CV_BGR2GRAY );
    }
    return grayMat;
}

-(UIImage *)UIImageFromCVMat:(cv::Mat)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                            //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}

- (int)smilePointFromWeight:(double)weight {
    if (weight <= 0) {
        return 1;
    }
    
    if (weight >= 6) {
        return 100;
    }
    
    double x = weight / 6.0f * M_PI_2;
    double y = ceil(sin(x) * 100.0f);
    return (int)y;
}

@end
