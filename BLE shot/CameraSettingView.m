//
//  SettingView.m
//  MorphoSelfPhoto
//
//  Created by nakano on 2018/08/08.
//  Copyright © 2018年 nakano. All rights reserved.
//

#import "CameraSettingView.h"

@implementation CameraSettingView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _expImages = [[NSMutableArray alloc] init];
        _expUnsuppotedImages = [[NSMutableArray alloc] init];
        _expButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_expButton addTarget:self action:@selector(expButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_expButton];
        [_expImages addObject:[UIImage imageNamed:@"icon-exp-lock"]];
        [_expImages addObject:[UIImage imageNamed:@"icon-exp-auto"]];
        [_expImages addObject:[UIImage imageNamed:@"icon-exp-cauto"]];
        [_expImages addObject:[UIImage imageNamed:@"icon-exp-custom"]];
        [_expUnsuppotedImages addObject:[UIImage imageNamed:@"icon-exp-lock-us"]];
        [_expUnsuppotedImages addObject:[UIImage imageNamed:@"icon-exp-auto-us"]];
        [_expUnsuppotedImages addObject:[UIImage imageNamed:@"icon-exp-cauto-us"]];
        [_expUnsuppotedImages addObject:[UIImage imageNamed:@"icon-exp-custom-us"]];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    CGFloat splitWidth = (screenSize.width - (48 * 5)) / 6;
    CGRect r = CGRectMake(splitWidth, 0, 48, 48);
    _expButton.frame = r;
    r.origin.x += r.size.width + splitWidth;
    [self updateDisplay];
}

- (void)setCaptureDevice:(AVCaptureDevice *)captureDevice
{
    _captureDevice = captureDevice;
    _exposureMode = _captureDevice.exposureMode;
    [self updateDisplay];
}

- (NSInteger)exposureModeIndex
{
    NSInteger index = 0;
    switch(_exposureMode) {
        case AVCaptureExposureModeLocked:                   index = 0;  break;
        case AVCaptureExposureModeAutoExpose:               index = 1;  break;
        case AVCaptureExposureModeContinuousAutoExposure:   index = 2;  break;
        case AVCaptureExposureModeCustom:                   index = 3;  break;
    }
    return index;
}

- (void)exposureModeIndexNext
{
    _exposureMode ++;
    if (_exposureMode > AVCaptureExposureModeCustom) {
        _exposureMode = AVCaptureExposureModeLocked;
    }
}

- (void)exposureModeSetDevice
{
    [_captureDevice lockForConfiguration:nil];
    if (_exposureMode == AVCaptureExposureModeCustom) {
        CMTime time = CMTimeMakeWithSeconds(2.0*1e-3, 1000*1000*1000);
        [_captureDevice setExposureModeCustomWithDuration:time ISO:200 completionHandler:nil];
        [_captureDevice setExposureTargetBias:0.0 completionHandler:nil];
    } else {
        if ([_captureDevice isFocusModeSupported:_exposureMode]) {
            _captureDevice.exposureMode = _exposureMode;
        }
    }
    [_captureDevice unlockForConfiguration];
}

- (void)updateDisplay
{
    if ([_captureDevice isExposureModeSupported:_exposureMode]) {
        [_expButton setImage:[_expImages objectAtIndex:[self exposureModeIndex]] forState:UIControlStateNormal];
    } else {
        [_expButton setImage:[_expUnsuppotedImages objectAtIndex:[self exposureModeIndex]] forState:UIControlStateNormal];
    }
}

// Action
- (void)expButtonPressed
{
    [self exposureModeIndexNext];
    [self exposureModeSetDevice];
    [self updateDisplay];
}
@end
