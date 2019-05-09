//
//  SettingView.h
//  MorphoSelfPhoto
//
//  Created by nakano on 2018/08/08.
//  Copyright © 2018年 nakano. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface CameraSettingView : UIView {
    NSMutableArray *    _expImages;
    NSMutableArray *    _expUnsuppotedImages;
}
@property (nonatomic, assign) AVCaptureExposureMode exposureMode;
@property (nonatomic, retain) UIButton * expButton;
@property (nonatomic, retain) AVCaptureDevice * captureDevice;
@end
