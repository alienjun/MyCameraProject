//
//  ViewController.m
//  MyCameraProject
//
//  Created by AlienJun on 14-7-14.
//  Copyright (c) 2014年 AlienJun. All rights reserved.
//

#import "ViewController.h"
#import "CameraImageHelper.h"
#import "UIImage+fixOrientation.h"

@interface ViewController ()<CameraImageDelegate>
@property (strong, nonatomic) IBOutlet UIView *cameraView;
@property (strong, nonatomic) IBOutlet UIButton *flashButton;
@property (strong,nonatomic)  UIView *highlitView;
@property (strong, nonatomic) IBOutlet UIImageView *hview;
@property (strong,nonatomic)   CameraImageHelper *cameraImageHelper;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _cameraImageHelper=[[CameraImageHelper alloc] initWithPreset:AVCaptureSessionPresetPhoto
                        
                                                  devicePosition:AVCaptureDevicePositionFront];
    
    _cameraImageHelper.delegate=self;
    
    //开始实时监测
    [_cameraImageHelper enableRTime:^(UIImage *image){
        
        
        //1.先做旋转等操作
        image=[image fixOrientation];
        //2.做人脸监测处理
        [self detectForFacesInUIImage:image];
        
        
        
    }];
    //不需要实时处理使用nil
    //    [CameraImageHelper enableRTime:nil];
    
    [_cameraImageHelper startRunning];
    [_cameraImageHelper embedPreviewInView:self.cameraView];
}


//人脸识别处理
-(void)detectForFacesInUIImage:(UIImage *)facePicture{
    CIImage* image = [CIImage imageWithCGImage:facePicture.CGImage];
    
    CIDetector* detectorF = [CIDetector detectorOfType:CIDetectorTypeFace
                                               context:nil
                                               options:[NSDictionary dictionaryWithObject:CIDetectorAccuracyLow forKey:CIDetectorAccuracy]];
    
    NSArray* features = [detectorF featuresInImage:image];
    CGRect maxRect=CGRectMake(0, 0, 0, 0);
    int i=0;
    for(CIFaceFeature* faceObject in features)
    {
        NSLog(@"found face");
        CGRect modifiedFaceBounds = faceObject.bounds;
        
        NSLog(@"faceObjBounds:%@",NSStringFromCGRect(faceObject.bounds));
        NSLog(@"facePicture:%f",facePicture.size.height);
        modifiedFaceBounds.origin.y =facePicture.size.height-faceObject.bounds.size.height-faceObject.bounds.origin.y;
        
        if (modifiedFaceBounds.size.width>maxRect.size.width) {
            maxRect=modifiedFaceBounds;
        }
        
        i++;
    }
    
    if ([features count]>0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self addSubViewWithFrame:maxRect index:i];
        });
        
    }else{
        NSLog(@"没有识别到人脸!");
    }
    
}

//画框人脸
-(void)addSubViewWithFrame:(CGRect)frame  index:(int)_index
{
    if(_highlitView==nil)
    {
        _highlitView= [[UIImageView alloc] initWithFrame:frame];
        
        _highlitView.layer.borderWidth = 2;
        _highlitView.layer.borderColor = [[UIColor redColor] CGColor];
        [self.hview addSubview:_highlitView];
    }
    
    frame.origin.x = frame.origin.x/1.5;
    frame.origin.y = frame.origin.y/1.5;
    frame.size.width = frame.size.width/1.5;
    frame.size.height = frame.size.height/1.5;
    _highlitView.frame = frame;
    
    ///根据头像大小缩放自画View
    float scale =frame.size.width/220;
    
    CAKeyframeAnimation *anim2=[CAKeyframeAnimation animationWithKeyPath:@"transform"];
    anim2.duration=3;
    CATransform3D trans=CATransform3DScale(CATransform3DIdentity, scale, scale, 1);
    anim2.values=[NSArray arrayWithObjects:[NSValue valueWithCATransform3D:trans],nil];
    [_highlitView.layer addAnimation:anim2 forKey:@"nm3"];
    
    _highlitView.hidden = NO;
    
    
}
-(UIImage *)rotateImage:(UIImage *)aImage

{
    CGImageRef imgRef = aImage.CGImage;
    CGFloat width = CGImageGetWidth(imgRef);
    CGFloat height = CGImageGetHeight(imgRef);
    CGAffineTransform transform = CGAffineTransformIdentity;
    CGRect bounds = CGRectMake(0, 0, width, height);
    CGFloat scaleRatio = 1;
    CGFloat boundHeight;
    UIImageOrientation orient = aImage.imageOrientation;
    
    switch(orient)
    {
        case UIImageOrientationUp: //EXIF = 1
            transform = CGAffineTransformIdentity;
            break;
        case UIImageOrientationUpMirrored: //EXIF = 2
            transform = CGAffineTransformMakeTranslation(width, 0.0);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            break;
        case UIImageOrientationDown: //EXIF = 3
            transform = CGAffineTransformMakeTranslation(width, height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
        case UIImageOrientationDownMirrored: //EXIF = 4
            transform = CGAffineTransformMakeTranslation(0.0, height);
            transform = CGAffineTransformScale(transform, 1.0, -1.0);
            break;
        case UIImageOrientationLeftMirrored: //EXIF = 5
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(height, width);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
        case UIImageOrientationLeft: //EXIF = 6
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(0.0, width);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
        case UIImageOrientationRightMirrored: //EXIF = 7
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeScale(-1.0, 1.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
        case UIImageOrientationRight: //EXIF = 8
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(height, 0.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
        default:
            [NSException raise:NSInternalInconsistencyException format:@"Invalid image orientation"];
    }
    UIGraphicsBeginImageContext(bounds.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (orient == UIImageOrientationRight || orient == UIImageOrientationLeft) {
        CGContextScaleCTM(context, -scaleRatio, scaleRatio);
        CGContextTranslateCTM(context, -height, 0);
    }
    else {
        CGContextScaleCTM(context, scaleRatio, -scaleRatio);
        CGContextTranslateCTM(context, 0, -height);
    }
    CGContextConcatCTM(context, transform);
    CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), imgRef);
    UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    
    float scaleSize = 0.0;
    if (imageCopy.size.width > imageCopy.size.height) {
        scaleSize = 1 - (imageCopy.size.width > 2000 ?  (imageCopy.size.width - 2000)/imageCopy.size.width : 0  );
    }else{
        scaleSize = 1 - (imageCopy.size.height > 2000 ?  (imageCopy.size.height - 2000)/imageCopy.size.height : 0  );
    }
    
    UIGraphicsBeginImageContext(CGSizeMake(imageCopy.size.width * scaleSize, imageCopy.size.height * scaleSize));
    [imageCopy drawInRect:CGRectMake(0, 0, imageCopy.size.width * scaleSize, imageCopy.size.height * scaleSize)];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    
    return scaledImage;
}

- (void)captureOutputSimpleBuffer:(UIImage *)image{
    
    //dispatch_async(dispatch_get_main_queue(), ^{
    [image fixOrientation];
    //});
    
}



- (IBAction)takeAction:(id)sender {
    
    UIView *maskView=[[UIView alloc] initWithFrame:self.cameraView.frame];
    [maskView setBackgroundColor:[UIColor whiteColor]];
    [maskView setAlpha:1];
    
    [self.view addSubview:maskView];
    
    //[maskView.layer addAnimation:[self opacityTimes_Animation:1 durTimes:0.3] forKey:@"test"];
    
    [UIView animateWithDuration:0.3 animations:^{
        [maskView setAlpha:0];
    } completion:^(BOOL finish){
        [maskView setAlpha:0];
    }];
    
    
    [_cameraImageHelper captureStillImage:^(UIImage *image) {
        
    }];
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag{
    NSLog(@"结束动画");
    
}

- (IBAction)flashAction:(UIButton *)sender
{
    sender.titleLabel.text=@"";
    FlashStatus status= [_cameraImageHelper changeFlash];
    
    switch (status) {
        case ON:
            [sender setTitle:@"ON" forState:UIControlStateNormal];
            break;
            
        case OFF:
            [sender setTitle:@"OFF" forState:UIControlStateNormal];
            break;
        case AUTO:
            [sender setTitle:@"AUTO" forState:UIControlStateNormal];
            break;
    }
    
}

- (IBAction)positionAction:(id)sender
{
    [_cameraImageHelper swapCameraPosition];
}


- (IBAction)reTakeAction:(id)sender
{
    [_cameraImageHelper startRunning];
}

@end

