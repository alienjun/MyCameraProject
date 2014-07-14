
//
//  CameraImageHelper.m
//  MyCameraTest
//
//  Created by AlienJun on 14-7-5.
//  Copyright (c) 2014年 AlienJun. All rights reserved.
//

#import "CameraImageHelper.h"
#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>
#import <ImageIO/ImageIO.h>

@implementation CameraImageHelper

static CameraImageHelper *sharedInstance=nil;

/**
 *  初始化
 */
-(void)initParamWithPreset:(NSString *)sessionPreset devicePosition:(AVCaptureDevicePosition)postion
{
    NSError *error=nil;
    
    //创建会话
    self.session=[[AVCaptureSession alloc] init];
    //采集大小
    self.session.sessionPreset=sessionPreset;
    //找到一个合适的采集设备
    //创建一个输入设备,并将它添加到会话
    AVCaptureDeviceInput *captureInput;
    NSArray *devices=[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if (device.position==postion) {
            captureInput=[AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
            _device=device;
        }
    }
    if (!captureInput) {
        NSLog(@"error:%@",error);
        return;
    }
    [self.session addInput:captureInput];
    
    //创建一个输出设备,并将它添加到会话
    self.captureOutput=[[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings=@{ AVVideoCodecKey : AVVideoCodecJPEG};
    [self.captureOutput setOutputSettings:outputSettings];
    [self.session addOutput:self.captureOutput];
    
    _before =[[NSDate date] timeIntervalSince1970];
}


-(id)init
{
    if (self=[super init]) {
        [self initParamWithPreset:AVCaptureSessionPreset640x480 devicePosition:AVCaptureDevicePositionFront];
    }
    return self;
}

/**
 *  初始化操作，根据
 *
 *  @param sessionPreset 捕获预置图像大小
 *
 *  @param postion       获取前/后摄像头
 *
 * @return instance
 */
-(instancetype)initWithPreset:(NSString *)sessionPreset devicePosition:(AVCaptureDevicePosition)postion
{
    if (self=[super init]) {
        [self initParamWithPreset:sessionPreset devicePosition:postion];
    }
    return self;
}


/**
 *  启用实时监测
 */
-(void)enableRTime
{
    //创建输出数据，用于每一帧回调使用。
    AVCaptureVideoDataOutput *captureOutput=[[AVCaptureVideoDataOutput  alloc] init];
    captureOutput.alwaysDiscardsLateVideoFrames=YES;
    dispatch_queue_t queue = dispatch_queue_create("captureQueue", NULL);
    [captureOutput setSampleBufferDelegate:self queue:queue];
    //dispatch_release(queue); ios6.0以上已纳入ARC，本工具需要6.0以上
    
    NSString *key=(NSString *)kCVPixelBufferPixelFormatTypeKey;
    NSNumber *value=[NSNumber numberWithUnsignedInteger:kCVPixelFormatType_32BGRA];
    NSDictionary *videoSettings=[NSDictionary dictionaryWithObject:value forKey:key];
    [captureOutput setVideoSettings:videoSettings];
    [self.session addOutput:captureOutput];
}


/**
 *  拍照获取静止图片
 */
-(void)captureStillImage:(ImageBackBlock)imageBackBlock
{
    //获取连接
    AVCaptureConnection *videoConnection=nil;
    for (AVCaptureConnection *connection in self.captureOutput.connections) {
        for (AVCaptureInputPort *port in connection.inputPorts) {
            if ([[port mediaType] isEqualToString:AVMediaTypeVideo]) {
                videoConnection=connection;
                break;
            }
        }
        if (videoConnection) {
            break;
        }
    }
    
    
    // 获取图片
    [self.captureOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
        [self.session stopRunning];
        CFDictionaryRef exifAttachments = CMGetAttachment(imageSampleBuffer, kCGImagePropertyExifDictionary, nil);
        if (exifAttachments) {
            // Do something with the attachments.
        }
        // 获取图片数据
        NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
        UIImage *t_image = [[UIImage alloc] initWithData:imageData];
        if(_device.position==AVCaptureDevicePositionFront){//前置摄像头照片保留镜面效果
            t_image= [UIImage imageWithCGImage:t_image.CGImage
                                         scale:1.0
                                   orientation: UIImageOrientationLeftMirrored];
        } else {
            t_image = [UIImage imageWithCGImage:t_image.CGImage
                                          scale:1.0
                                    orientation:UIImageOrientationRight];
        }
        if (imageBackBlock) {
            imageBackBlock(t_image);
        }
        self.image = t_image;
    }];
    
}


#pragma AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    @autoreleasepool {
        NSTimeInterval now = [[NSDate dateWithTimeIntervalSinceNow:0] timeIntervalSince1970]*1;
        if((now - _before) > 0.5)//多少秒进行一次检测
        {
            //NSLog(@" before: %f  num: %f" , _before, now - _before);
            _before = [[NSDate date] timeIntervalSince1970];
            UIImage *image = [self imageFromSampleBuffer:sampleBuffer];
            if(image != nil)
            {
                //execute block
                if (self.callBackBlock)
                {
                    self.callBackBlock(image);
                }else
                {
                    if ([self.delegate respondsToSelector:@selector(captureOutputSimpleBuffer:)])
                    {
                        [self.delegate captureOutputSimpleBuffer:image];
                    }
                }
                
            }
            
        }
        
    }
}




/**
 *   读取图片
 *
 *  @param sampleBuffer
 *
 *  @return 图片
 */
- (UIImage *)imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer
{
    
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // Lock the base address of the pixel buffer
    CVPixelBufferLockBaseAddress(imageBuffer,0);
    // Get the number of bytes per row for the pixel buffer
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // Get the pixel buffer width and height
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    // Create a device-dependent RGB color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    if (!colorSpace)
    {
        NSLog(@"CGColorSpaceCreateDeviceRGB failure");
        return nil;
    }
    
    // Get the base address of the pixel buffer
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    // Get the data size for contiguous planes of the pixel buffer.
    size_t bufferSize = CVPixelBufferGetDataSize(imageBuffer);
    // Create a Quartz direct-access data provider that uses data we supply
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, baseAddress, bufferSize,NULL);
    // Create a bitmap image from data supplied by our data provider
    CGImageRef cgImage =
    CGImageCreate(width,
                  height,
                  8,
                  32,
                  bytesPerRow,
                  colorSpace,
                  kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Little,
                  provider,
                  NULL,
                  true,
                  kCGRenderingIntentDefault);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    // Create and return an image object representing the specified Quartz image
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    if (_device.position==AVCaptureDevicePositionFront){//前置摄像头照片保留镜面效果
        image= [UIImage imageWithCGImage:image.CGImage
                                   scale:1.0
                             orientation: UIImageOrientationLeftMirrored];
    } else {
        image = [UIImage imageWithCGImage:image.CGImage
                                    scale:1.0
                              orientation:UIImageOrientationRight];
    }
    CGImageRelease(cgImage);
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    
    return image;
    
}



/**
 *  闪光灯调整
 *
 *  @return 闪光灯状态
 */
-(FlashStatus)changeFlash
{
    FlashStatus result=OFF;
    if([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera] && [_device hasFlash])
    {
        [_device lockForConfiguration:nil];
        if([_device flashMode] == AVCaptureFlashModeOff)
        {
            result=AUTO;
            [_device setFlashMode:AVCaptureFlashModeAuto];
            NSLog(@"设置为自动");
        }
        else if([_device flashMode] == AVCaptureFlashModeAuto)
        {
            result=ON;
            [_device setFlashMode:AVCaptureFlashModeOn];
            NSLog(@"设置为开启");
        }
        else{
            result=OFF;
            [_device setFlashMode:AVCaptureFlashModeOff];
            NSLog(@"设置为关闭");
        }
        [_device unlockForConfiguration];
    }
    
    return result;
}


/**
 *  获取闪光灯状态
 *
 *  @return 闪光灯状态
 */
-(FlashStatus)flashStatus
{
    FlashStatus result=OFF;
    if([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera] && [_device hasFlash])
    {
        if([_device flashMode] == AVCaptureFlashModeOff)
        {
            result=AUTO;
        }
        else if([_device flashMode] == AVCaptureFlashModeAuto)
        {
            result=ON;
        }
        else{
            result=OFF;
        }
    }
    return result;
}

#pragma mark interface

+(CameraImageHelper *)sharedInstance
{
    if (!sharedInstance) {
        sharedInstance=[[CameraImageHelper alloc] init];
    }
    return sharedInstance;
}

/**
 *  启用实时监测
 */
-(void)enableRTime:(RTimeCallBackBlock)callBackBlock
{
    self.callBackBlock=callBackBlock;
    [self enableRTime];
}



/**
 *  开始运行
 */
-(void)startRunning
{
    [_session startRunning];
}


/**
 *  停止运行
 */
-(void)stopRunning
{
    [_session stopRunning];
}


/**
 *  获取图片
 */
-(UIImage *)image
{
    return _image;
}




/**
 *  嵌入预览视图到指定视图中
 *
 *  @param view 指定的视图
 */
-(void)embedPreviewInView:(UIView *)view
{
    if (!self.session) {
        return;
    }
    self.preview=[AVCaptureVideoPreviewLayer layerWithSession:self.session];
    self.preview.frame=view.bounds;
    self.preview.videoGravity=AVLayerVideoGravityResizeAspectFill;
    [view.layer addSublayer:self.preview];
    
}

/**
 *  改变预览方向
 *
 *  @param interfaceOrientation 图片方向
 */
-(void)changePreviewOrientation:(UIInterfaceOrientation ) interfaceOrientation
{
    if (!self.session) {
        return;
    }
    [CATransaction begin];
    if (interfaceOrientation==UIInterfaceOrientationLandscapeRight) {
        self.imageOrientation=UIInterfaceOrientationLandscapeRight;
        self.preview.connection.videoOrientation=AVCaptureVideoOrientationLandscapeRight;
    }else if(interfaceOrientation==UIInterfaceOrientationLandscapeLeft){
        self.imageOrientation=UIInterfaceOrientationLandscapeLeft;
        self.preview.connection.videoOrientation=AVCaptureVideoOrientationLandscapeLeft;
    }
    [CATransaction commit];
}


/**
 *  切换摄像头
 */
-(void)swapCameraPosition
{
    NSArray *inputs = self.session.inputs;
    for ( AVCaptureDeviceInput *input in inputs )
    {
        AVCaptureDevice *device = input.device;
        if ([device hasMediaType:AVMediaTypeVideo])
        {
            AVCaptureDevicePosition position = device.position;
            AVCaptureDevice *newCamera = nil;
            AVCaptureDeviceInput *newInput = nil;
            
            if (position == AVCaptureDevicePositionFront)
            {
                newCamera = [self cameraWithPosition:AVCaptureDevicePositionBack];
            }else{
                newCamera = [self cameraWithPosition:AVCaptureDevicePositionFront];
            }
            newInput = [AVCaptureDeviceInput deviceInputWithDevice:newCamera error:nil];
            self.device=newCamera;
            // beginConfiguration ensures that pending changes are not applied immediately
            [self.session beginConfiguration];
            
            [self.session removeInput:input];
            [self.session addInput:newInput];
            
            // Changes take effect once the outermost commitConfiguration is invoked.
            [self.session commitConfiguration];
            break;
        }
    }
    
}

- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices)
    {
        if (device.position == position)
        {
            return device;
        }
    }
    return nil;
}

-(void)dealloc
{
    
    NSLog(@"%s",__func__);
}

@end
