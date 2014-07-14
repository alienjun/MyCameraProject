//
//  CameraImageHelper.h
//  MyCameraTest
//
//  Created by AlienJun on 14-7-5.
//  Copyright (c) 2014年 AlienJun. All rights reserved.
//
//
//
//  可以通过代理方式使用实时监测图片，也可以使用block方式。
//


#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

/**
 *  闪光灯状态
 */
typedef enum {
    OFF=0,
    ON=1,
    AUTO=2
} FlashStatus;

/**
 *  实时监测回调
 */
typedef void(^RTimeCallBackBlock)(UIImage *image);
typedef void(^ImageBackBlock)(UIImage *image);
/**
 *  实时监测回调协议
 */
@protocol CameraImageDelegate <NSObject>
@required
- (void)captureOutputSimpleBuffer:(UIImage *)image;
@end

@interface CameraImageHelper : NSObject<AVCaptureVideoDataOutputSampleBufferDelegate>

@property (strong, nonatomic) AVCaptureSession *session;                    // 捕获会话
@property (strong, nonatomic) AVCaptureStillImageOutput *captureOutput;     // 捕获输出
@property (strong, nonatomic) UIImage *image;                               // 图片
@property (assign, nonatomic) UIImageOrientation imageOrientation;          // 图片方向
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *preview;          // 预览视图
@property (strong, nonatomic) AVCaptureDevice *device;                      // 当前捕获设备
@property (strong, nonatomic) RTimeCallBackBlock callBackBlock;             // 实时回调block
@property (weak,   nonatomic) id<CameraImageDelegate> delegate;
@property (assign, nonatomic) NSTimeInterval before;

/**
 *  默认是AVCaptureSessionPreset640x480
 *
 *  @return CameraImageHelper实例
 */
+(CameraImageHelper *)sharedInstance;


/**
 *  初始化操作，根据
 *
 *  @param sessionPreset 捕获预置图像大小
 *
 *  @param postion       获取前/后摄像头
 *
 * @return instance
 */
-(instancetype)initWithPreset:(NSString *)sessionPreset devicePosition:(AVCaptureDevicePosition)postion;

/**
 *  启用实时监测，图片需要自己做旋转等操作
 */
-(void)enableRTime:(RTimeCallBackBlock)callBackBlock;

/**
 *  开始运行
 */
-(void)startRunning;


/**
 *  停止运行
 */
-(void)stopRunning;


/**
 *  获取图片，需要自己做旋转等操作
 */
-(UIImage *)image;


/**
 *  获取静止图片
 */
-(void)captureStillImage:(ImageBackBlock)imageBackBlock;


/**
 *  嵌入预览视图到指定视图中
 *
 *  @param view 指定的视图
 */
-(void)embedPreviewInView:(UIView *)view;

/**
 *  改变预览方向
 *
 *  @param interfaceOrientation 图片方向
 */
-(void)changePreviewOrientation:(UIInterfaceOrientation ) interfaceOrientation;


/**
 *  切换摄像头
 */
-(void)swapCameraPosition;

/**
 *  闪光灯调整
 *
 *  @return 闪光灯状态
 */
-(FlashStatus)changeFlash;

/**
 *  获取闪光灯状态
 *
 *  @return 闪光灯状态
 */
-(FlashStatus)flashStatus;

@end
