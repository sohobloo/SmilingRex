//
//  REXViewController.m
//  REXSmilingDetectionResearch
//
//  Created by 饶欣 on 15/12/18.
//  Copyright © 2015年 Rex Rao. All rights reserved.
//

#import "REXDetectViewController.h"
#import "REXPhotoLoader.h"

@interface REXDetectViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>


@property (weak, nonatomic) IBOutlet UIView *infoView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *indicator;
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;
@property (weak, nonatomic) IBOutlet UIImageView *photoImageView;
@property (weak, nonatomic) IBOutlet UIView *toolbarView;
@property (weak, nonatomic) IBOutlet UIButton *presetButton;
@property (weak, nonatomic) IBOutlet UIButton *prevButton;
@property (weak, nonatomic) IBOutlet UILabel *indexLabel;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;
@property (weak, nonatomic) IBOutlet UIButton *albumButton;
@property (weak, nonatomic) IBOutlet UIButton *cameraButton;

- (IBAction)presetButtonDidTouch:(id)sender;
- (IBAction)prevButtonDidTouch:(id)sender;
- (IBAction)nextButtonDidTouch:(id)sender;
- (IBAction)albumButtonDidTouch:(id)sender;
- (IBAction)cameraButtonDidTouch:(id)sender;

@property (strong, nonatomic) REXPhotoLoader *photoLoader;
@property (strong, nonatomic) UIImagePickerController *imagePicker;

@end

@implementation REXDetectViewController {

}

#pragma mark - Lifecycle

- (void)loadView {
    static UINib *nib;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        nib = [UINib nibWithNibName:NSStringFromClass([REXDetectViewController class]) bundle:nil];
    });
    self.view = [nib instantiateWithOwner:self options:nil].firstObject;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    _compressRate = 1.0;
}

#pragma mark - Getter / Setter

- (void)setThemeColor:(UIColor *)themeColor {
    self.infoView.backgroundColor = themeColor;
    self.toolbarView.backgroundColor = themeColor;
}

- (UIColor *)themeColor {
    return self.infoView.backgroundColor;
}

- (REXPhotoLoader *)photoLoader {
    if (!_photoLoader) {
        _photoLoader = [REXPhotoLoader new];
    }
    return _photoLoader;
}

- (UIImagePickerController *)imagePicker {
    if (!_imagePicker) {
        _imagePicker = [UIImagePickerController new];
        _imagePicker.delegate = self;
    }
    return _imagePicker;
}

#pragma mark - Actions

- (IBAction)presetButtonDidTouch:(id)sender {
    UIImage *photo = [self.photoLoader photoWithIndex:0];
    [self updateIndexLabel];
    [self startDetectWithPhoto:photo];
}

- (IBAction)prevButtonDidTouch:(id)sender {
    UIImage *photo = [self.photoLoader prevPhoto];
    [self updateIndexLabel];
    [self startDetectWithPhoto:photo];
}

- (IBAction)nextButtonDidTouch:(id)sender {
    UIImage *photo = [self.photoLoader nextPhoto];
    [self updateIndexLabel];
    [self startDetectWithPhoto:photo];
}

- (void)albumButtonDidTouch:(id)sender {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        self.imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        [self presentViewController:self.imagePicker animated:YES completion:nil];
    } else {
        [self showInfo:@"📷 Failed to open photo library."];
    }
}

- (IBAction)cameraButtonDidTouch:(id)sender {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        self.imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        [self presentViewController:self.imagePicker animated:YES completion:nil];
    } else {
        [self showInfo:@"📷 Failed to open camera."];
    }
}

#pragma mark - Public function

- (void)detect {
    @throw [NSException exceptionWithName:@"REXNotImplementException" reason:@"Method not implement." userInfo:nil];
}

- (void)showInfo:(NSString *)info {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSMutableAttributedString *attributedString = self.infoLabel.attributedText.mutableCopy;
        [attributedString replaceCharactersInRange:NSMakeRange(0, attributedString.length) withString:info];
        self.infoLabel.attributedText = attributedString;
    });
}

- (void)showPhoto:(UIImage *)photo {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.photoImageView.image = photo;
    });
}

#pragma mark - Private function

- (void)startDetectWithPhoto:(UIImage *)photo {
    _photo = photo;
    if (!_photo) {
        [self showInfo:@"😲 Failed to load photo."];
        return;
    }

    [self showInfo:@"🕓 Detecting..."];
    self.view.userInteractionEnabled = NO;
    [self.indicator startAnimating];
    self.photoImageView.image = _photo;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        _photoData = UIImageJPEGRepresentation(photo, self.compressRate);
        if (self.compressRate) {
            _photo = [UIImage imageWithData:_photoData];
        }
        [self detect];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.indicator stopAnimating];
            self.view.userInteractionEnabled = YES;
        });
    });
}

- (void)updateIndexLabel {
    u_int32_t index = [self.photoLoader curentIndex];
    u_int32_t total = [self.photoLoader total];
    NSString *indexString = [NSString stringWithFormat:@"%u/%u", index + 1, total];
    self.indexLabel.text = indexString;
    
    self.prevButton.hidden = NO;
    self.nextButton.hidden = NO;
    self.indexLabel.hidden = NO;
}

- (UIImage *)fixOrientation:(UIImage *)aImage {
    
    // No-op if the orientation is already correct
    if (aImage.imageOrientation == UIImageOrientationUp)
        return aImage;
    
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, aImage.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, aImage.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        default:
            break;
    }
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        default:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, aImage.size.width, aImage.size.height,
                                             CGImageGetBitsPerComponent(aImage.CGImage), 0,
                                             CGImageGetColorSpace(aImage.CGImage),
                                             CGImageGetBitmapInfo(aImage.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (aImage.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.height,aImage.size.width), aImage.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.width,aImage.size.height), aImage.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    __block UIImage *photo = info[UIImagePickerControllerOriginalImage];
    photo = [self fixOrientation:photo];
    
    __weak REXDetectViewController *weakSelf = self;
    
    [picker dismissViewControllerAnimated:YES completion:^{
        if (weakSelf) {
            self.prevButton.hidden = YES;
            self.nextButton.hidden = YES;
            self.indexLabel.hidden = YES;
            [weakSelf startDetectWithPhoto:photo];
        }
    }];
}

@end
