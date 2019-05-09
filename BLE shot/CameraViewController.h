//
//  ViewController.h
//  CamSample
//
//  Created by nakano on 2018/08/20.
//  Copyright © 2018年 nakano. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "CameraSettingView.h"

@interface CameraViewController : UIViewController
<AVCaptureVideoDataOutputSampleBufferDelegate,
AVCapturePhotoCaptureDelegate> {
}

@property (nonatomic, retain) CameraSettingView * settingView;

@property (nonatomic, retain) UIImageView *previewImageView;
@property (nonatomic, retain) UIButton *captureButton;
@property (nonatomic, retain) UIImageView *imageView;

@end

