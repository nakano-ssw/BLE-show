//
//  ViewController.m
//  CamSample
//
//  Created by nakano on 2018/08/20.
//  Copyright © 2018年 nakano. All rights reserved.
//

#import "CameraViewController.h"
#include <sys/sysctl.h>

@interface CameraViewController () {
    AVCaptureDevice * _captureDevice;
    AVCaptureDeviceInput * _videoInput;
    AVCaptureVideoDataOutput * _videoOutput;
    AVCaptureSession * _captureSession;
    AVCaptureStillImageOutput * _stillImageOutput;
    AVCapturePhotoOutput * _rawImageOutput;
}
@end

@implementation CameraViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    self.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenSize.width, screenSize.height)];
    _previewImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, screenSize.width, screenSize.height)];
    [self.view addSubview:_previewImageView];
    _captureButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_captureButton setTitle:@"Capture" forState:UIControlStateNormal];
    [_captureButton addTarget:self action:@selector(captureButtonPressed:) forControlEvents:UIControlEventTouchDown];
    _captureButton.frame = CGRectMake((screenSize.width-100)/2, screenSize.height-200, 100, 100);
    [self.view addSubview:_captureButton];
    _settingView = [[CameraSettingView alloc] initWithFrame:CGRectMake(0, 100, screenSize.width, 48)];
    [self.view addSubview:_settingView];
    [self startPreview];
    _settingView.captureDevice = _captureDevice;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)initCamera {
    _captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    [_captureDevice lockForConfiguration:nil];
    if ([_captureDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
        _captureDevice.focusMode = AVCaptureFocusModeContinuousAutoFocus;
    } else {
        NSLog(@"focusMode = AVCaptureFocusModeContinuousAutoFocus unsuppoted");
    }
    if ([_captureDevice isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance]) {
        _captureDevice.whiteBalanceMode = AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance;
    } else {
        NSLog(@"whiteBalanceMode = AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance unsuppoted");
    }
    if ([_captureDevice isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
        /*
         * AVCaptureExposureModeContinuousAutoExposureを設定すると、書き出したdngファイルの
         * BLE値が撮影毎に変化するが、setExposureModeCustomWithDuration, setExposureTargetBias
         * を設定すると、iPhone Xs Maxの場合のみ書き出したdngファイルのBLE値が0.059781固定となる。
         */
        if (NO) {
            _captureDevice.exposureMode = AVCaptureExposureModeContinuousAutoExposure;
        } else {
            CMTime time = CMTimeMakeWithSeconds(2.0*1e-3, 1000*1000*1000);
            [_captureDevice setExposureModeCustomWithDuration:time ISO:200 completionHandler:nil];
            [_captureDevice setExposureTargetBias:0.0 completionHandler:nil];
        }
    } else {
        NSLog(@"exposureMode = AVCaptureExposureModeContinuousAutoExposure unsuppoted");
    }
    [_captureDevice unlockForConfiguration];
    
    NSError *error    = nil;
    NSString * preset = [self presetOfMachine];
    preset = AVCaptureSessionPresetPhoto;
    _videoInput = [AVCaptureDeviceInput deviceInputWithDevice:_captureDevice error:&error];
    _videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    _videoOutput.alwaysDiscardsLateVideoFrames = YES;
    [_videoOutput setSampleBufferDelegate:self queue:dispatch_get_current_queue()];
    _stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    _rawImageOutput = [[AVCapturePhotoOutput alloc] init];
    
    // Set the video output to store frame in BGRA
    NSString* key = (NSString*)kCVPixelBufferPixelFormatTypeKey;
    // YUV形式だとBGRA形式よりフレームレートが落ちる
    /*
     kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
     Bi-Planar Component Y'CbCr 8-bit 4:2:0, video-range (luma=[16,235] chroma=[16,240]).
     baseAddr points to a big-endian CVPlanarPixelBufferInfo_YCbCrBiPlanar struct.
     Available in iOS 4.0 and later.
     */
    NSNumber* value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA];
    NSDictionary* videoSettings = [NSDictionary dictionaryWithObject:value forKey:key];
    [_videoOutput setVideoSettings:videoSettings];
    _videoOutput.alwaysDiscardsLateVideoFrames = TRUE;
    _captureSession = [[AVCaptureSession alloc] init];
    
    // Configure CaptureSession
    [_captureSession beginConfiguration];
    
    // Add to CaptureSession input and output
    [_captureSession addInput:_videoInput];
    //    [_captureSession addOutput:_videoOutput];
    //    [_captureSession addOutput:_stillImageOutput];
    [_captureSession addOutput:_rawImageOutput];
    [_captureSession setSessionPreset:preset];
    [_captureSession commitConfiguration];
    
    // HardWareプレビューを使用
    AVCaptureVideoPreviewLayer * previewLayer =[AVCaptureVideoPreviewLayer layerWithSession:_captureSession];
    previewLayer.frame = _previewImageView.bounds;
    [_previewImageView.layer addSublayer:previewLayer];
}

- (void)startPreview {
    _previewImageView.contentMode = UIViewContentModeScaleAspectFill;
    [self initCamera];
    
    // カメラプレビュー起動
    [_captureSession startRunning];
}

- (void)stopPreview {
    [_captureSession stopRunning];
}

- (NSString*)machineClass
{
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *deviceName = [NSString stringWithCString:machine encoding:NSUTF8StringEncoding];
    free(machine);
    return deviceName;
}

- (NSString*)machineFirstNmae
{
    NSString * machineName = [self machineClass];
    NSRange range = [machineName rangeOfString:@","];
    NSString * deviceNameFirst = [machineName substringToIndex:range.location];
    return deviceNameFirst;
}

- (NSInteger)machineSubNumber
{
    NSString * machineName = [self machineClass];
    NSRange range = [machineName rangeOfString:@","];
    NSInteger subNumber = [[machineName substringFromIndex:range.location+1] integerValue];
    return subNumber;
}

- (NSString*)presetOfMachine
{
    NSString * preset = AVCaptureSessionPresetLow;
    NSString * firstName = [self machineFirstNmae];
    NSInteger cmpRet = [firstName compare:@"iPhone7"];
    if (cmpRet == NSOrderedSame) {
        preset = AVCaptureSessionPresetMedium;
    } else if (cmpRet == NSOrderedDescending) {
        preset = AVCaptureSessionPresetHigh;
    }
    return preset;
}


- (NSString*)documentDirPath {
    NSArray * array = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * docDirPath = [array objectAtIndex:0];
    return docDirPath;
}

- (IBAction)captureButtonPressed:(id)sender {
    NSUInteger rawFormat = [[_rawImageOutput.availableRawPhotoPixelFormatTypes firstObject] unsignedIntValue];
    AVCapturePhotoSettings * rawSettings = [AVCapturePhotoSettings photoSettingsWithRawPixelFormatType:(OSType)rawFormat processedFormat:@{ AVVideoCodecKey: AVVideoCodecTypeJPEG }];
    rawSettings.autoStillImageStabilizationEnabled = NO;
    [_rawImageOutput capturePhotoWithSettings:rawSettings delegate:self];
}

#pragma mark AVCapturePhotoCaptureDelegate
- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhoto:(AVCapturePhoto *)photo error:(NSError *)error
{
    if (photo.isRawPhoto) {
        NSData * data = [photo fileDataRepresentation];
        NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"YYYY-MM-dd hh-mm-ss"];
        NSString * fileName = [NSString stringWithFormat:@"%@_%@.dng", [self machineFirstNmae], [formatter stringFromDate:[NSDate date]]];
        NSString * docDirPath = [self documentDirPath];
        NSString * path = [docDirPath stringByAppendingPathComponent:fileName];
        [data writeToFile:path atomically:YES];
        NSDictionary * option = @{ (NSString*)kCGImageSourceTypeIdentifierHint: @"com.adobe.raw-image" };
        CIFilter * rawConverter = [CIFilter filterWithImageData:data options:option];
        NSNumber * value = [rawConverter valueForKey:kCIInputBaselineExposureKey];
        double ble = [value doubleValue];
        NSLog(@"%@ %f", fileName, ble);
    }
}

#pragma mark AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    uint32_t* baseaddress = (uint32_t*)CVPixelBufferGetBaseAddress(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t rowBytes = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t dataSize = CVPixelBufferGetDataSize(imageBuffer);

    // データプロバイダーの生成
    CGImageRef imageref;
    CGDataProviderRef provider;
    CGColorSpaceRef colorSpaceRef;
    UIImage* image;
    provider = CGDataProviderCreateWithData(NULL, baseaddress, dataSize, NULL);
    
    NSInteger bitsPerComponent = 8;
    NSInteger bitsPerPixel = 32;
    NSInteger bytesPerRow = rowBytes;
    
    //BGRA (same as input)
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst;
    colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    imageref = CGImageCreate(
                             width,
                             height,
                             bitsPerComponent,
                             bitsPerPixel,
                             bytesPerRow,
                             colorSpaceRef,
                             bitmapInfo,
                             provider,
                             NULL,
                             NO,
                             renderingIntent
                             );
    
    image = [UIImage imageWithCGImage:imageref]; //FRAME AS UIIMAGE

    // 270度回転
    NSInteger imageWidth = height;
    NSInteger imageHeight = width;
    UIGraphicsBeginImageContext(CGSizeMake(imageWidth, imageHeight));
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextRotateCTM(context, -M_PI/2.0);
    CGContextDrawImage(context, CGRectMake(0, 0, image.size.width, image.size.height), [image CGImage]);
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    _imageView.image = image;

    CGImageRelease(imageref);
    CGColorSpaceRelease(colorSpaceRef);
    CGDataProviderRelease(provider);
    // Unlock the image buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
}
@end
