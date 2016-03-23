//
//  OpenCVViewController.m
//  REXSmilingDetectionResearch
//
//  Created by 饶欣 on 15/12/8.
//  Copyright © 2015年 Rex Rao. All rights reserved.
//

#import "OpenCVViewController.h"
#import "REXFaceDetector.h"

@interface OpenCVViewController ()

@end

@implementation OpenCVViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    self.themeColor = [UIColor colorWithRed:240/255.0 green:195/255.0 blue:48/255.0 alpha:1];;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)detect {
    REXFaceDetector *faceDetector = [[REXFaceDetector alloc] initWithImage:self.photo];
    [faceDetector detectFaces];
    [self showPhoto:[faceDetector markedImage]];
    [self showInfo:@"👌 Complete."];
}

@end
