MyCameraProject
===============
自定义相机开发

使用方式：引入CameraImageHelper.h  进行使用

    //初始化一个camera，并指定参数，前、后摄像头，拍照大小。
    CameraImageHelper *_cameraImageHelper=[[CameraImageHelper alloc] initWithPreset:AVCaptureSessionPresetPhoto
                        
                                                  devicePosition:AVCaptureDevicePositionFront];

    //开始实时监测
    [_cameraImageHelper enableRTime:^(UIImage *image){
            //1.先做旋转等操作
            image=[image fixOrientation];
            //2.做人脸监测处理
            [self detectForFacesInUIImage:image];
    }];
    
    //开启
  [_cameraImageHelper startRunning];
  //嵌入到视图中
  [_cameraImageHelper embedPreviewInView:self.cameraView];
  
  
  //拍照获取图片
  [_cameraImageHelper captureStillImage:^(UIImage *image) {
        
    }];
    
    //闪光灯切换状态，可以根据状态效果自行设置按钮的图标样式
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
    
    //摄像头切换
    [_cameraImageHelper swapCameraPosition];
