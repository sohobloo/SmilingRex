//
//  REXSmileDetector.m
//  REXSmilingDetectionResearch
//
//  Created by 饶欣 on 15/12/15.
//  Copyright © 2015年 Rex Rao. All rights reserved.
//

#ifdef __cplusplus
#import <opencv2/opencv.hpp>
#endif

#import "REXSmileDetector.h"

using namespace cv;


@implementation REXSmileDetector {
    BOOL _drawResult;
    
    UIImage *_image;
    CGFloat _scale;
    
    CascadeClassifier _faceDetector;
    CascadeClassifier _smileDetector;
    
    cv::Mat _mat;
    cv::Mat _grayMat;
    
    cv::Rect _faceRect;
    cv::Rect _smileRect;
    
    int _smilePoint;
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
    }
    return self;
}

- (void)dealloc {
    _image = nil;
    _mat.release();
    _grayMat.release();
}

- (BOOL)detect {
    BOOL detected = [self detectFace] && [self detectSmile];
    if (!detected) {
        _mat.release();
    }

    return detected;
}

- (UIImage *)markedImage {
    UIImage *image;
    if (!_mat.empty()) {
        cv::Mat mat = _mat.clone();
        [self drawDetectedHead:mat];
        [self drawDetectedSmile:mat];
        image = [self UIImageFromCVMat:mat];
        mat.release();
    }
    return image;
}

- (UIImage *)faceImage {
    UIImage *image;
    if (!_mat.empty()) {
        cv::Mat faceMat = _mat(_faceRect).clone();
        image = [self UIImageFromCVMat:faceMat];
        faceMat.release();
    }
    return image;
}

- (UIImage *)smileImage {
    UIImage *image;
    if (!_mat.empty()) {
        cv::Mat smileMat = _mat(_smileRect).clone();
        image = [self UIImageFromCVMat:smileMat];
        smileMat.release();
    }
    return image;
}

-(int)smileScore {
    return _smilePoint;
}

- (BOOL)detectFace {
    _mat = [self cvMatFromUIImage:_image];
    cvtColor(_mat, _grayMat, COLOR_BGR2GRAY);
    
    std::vector<cv::Rect> faceRects;
    std::vector<int> rejectLevels;
    std::vector<double> levelWeights;
    double scalingFactor = 1.1;
    int minNeighbors = 2;
    int flags = 0;
    cv::Size minSize(30, 30);
    cv::Size maxSize(_mat.rows, _mat.cols);
    bool outputRejectLevels = true;
    
    _faceDetector.detectMultiScale(
                                   _grayMat,
                                   faceRects,
                                   rejectLevels,
                                   levelWeights,
                                   scalingFactor,
                                   minNeighbors,
                                   flags,
                                   minSize,
                                   maxSize,
                                   outputRejectLevels
                                   );
    
    double maxWeight = DBL_MIN;
    int finalIndex = -1;
    
    for(int i = 0; i < (int)(faceRects).size(); i++) {
        double weight = levelWeights[i];
        NSLog(@"face detected: index=%d, weight=%.2f.", i, weight);
        if (weight < maxWeight) {
            continue;
        }
        
        maxWeight = weight;
        finalIndex = i;
    }
    
    if (finalIndex == -1) {
        return NO;
    }
    
    _faceRect = faceRects[finalIndex];

    return YES;
}

- (BOOL)detectSmile {
    cv::Rect cropFaceRect(_faceRect.x, _faceRect.y + _faceRect.height / 2, _faceRect.width, _faceRect.height / 2);
    cv::Mat faceMat = _mat(cropFaceRect);

    std::vector<cv::Rect> smileRects;
    std::vector<int> rejectLevels;
    std::vector<double> levelWeights;
    double scalingFactor = 1.1;
    int minNeighbors = 2;
    int flags = 0;
    cv::Size minSize(cropFaceRect.width / 5, cropFaceRect.height / 5);
    cv::Size maxSize(cropFaceRect.width, cropFaceRect.height);
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
    faceMat.release();
    _grayMat.release();
    
    double maxWeight = DBL_MIN;
    int finalIndex = -1;
    
    for(int i = 0; i < (int)(smileRects).size(); i++) {
        double weight = levelWeights[i];
        NSLog(@"smile detected: index=%d, weight=%.2f.", i, weight);
        if (weight < maxWeight) {
            continue;
        }
        
        maxWeight = weight;
        finalIndex = i;
    }
    
    if (finalIndex == -1) {
        faceMat.release();
        return NO;
    }
    
    cv::Rect smileRect = smileRects[finalIndex];
    
    int x = _faceRect.x + smileRect.x;
    int y = _faceRect.y + _faceRect.height / 2 + smileRect.y;
    int width = smileRect.width;
    int height = smileRect.height;
    
    _smileRect = cvRect(x, y, width, height);
    _smilePoint = [self smilePointFromWeight:maxWeight];
    
    return YES;
}

- (void)drawDetectedHead:(cv::Mat)mat {
    cv::Point p1 = cvPoint(_faceRect.x, _faceRect.y);
    cv::Point p2 = cvPoint(_faceRect.x + _faceRect.width, _faceRect.y + _faceRect.height);
    cv::Scalar color = CV_RGB(0, 255, 255);
    int thickness = 2;
    int lineType = FILLED;
    int shift = 0;
    
    rectangle(mat, p1, p2,
              color, thickness,
              lineType, shift);
}

- (void)drawDetectedSmile:(cv::Mat)mat {
    cv::Point p1 = cvPoint(_smileRect.x, _smileRect.y);
    cv::Point p2 = cvPoint(_smileRect.x + _smileRect.width, _smileRect.y + _smileRect.height);
    cv::Scalar rectColor = CV_RGB(255, 0, 255);
    int thickness = 2;
    int lineType = FILLED;
    int shift = 0;
    
    rectangle(mat, p1, p2,
              rectColor, thickness,
              lineType, shift);
    
    const cv::String &text = std::to_string(_smilePoint);
    cv::Point org = cvPoint(_smileRect.x, _smileRect.y - 2);
    int fontFace = 1;
    double fontScale = _scale;
    cv::Scalar textColor = CV_RGB(0, 33, 255);
    bool bottomLeftOrigin = false;
    
    putText(mat, text, org,
            fontFace, fontScale, textColor,
            thickness, lineType,
            bottomLeftOrigin);
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
