//
//  ViewController.m
//  LXFAudioVideo
//
//  Created by 林洵锋 on 2017/10/14.
//  Copyright © 2017年 LXF. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

// https://developer.apple.com/library/content/documentation/AudioVideo/Conceptual/AVFoundationPG/Articles/00_Introduction.html#//apple_ref/doc/uid/TP40010188-CH1-SW3

#define ScreenW [UIScreen mainScreen].bounds.size.width
#define ScreenH [UIScreen mainScreen].bounds.size.height

@interface ViewController () <AVCaptureVideoDataOutputSampleBufferDelegate>
@property(nonatomic, strong) AVCaptureSession *captureSession;
@property(nonatomic, weak) UIImageView *imageView;

@end

@implementation ViewController

- (UIImageView *)imageView {
    if (_imageView == nil) {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
        [self.view addSubview:imageView];
        _imageView = imageView;
    }
    return _imageView;
}


/*
 AVCaptureDevice : 摄像头 麦克风
 AVCaptureInput : 输入端口
 AVCaptureOutput : 设备输出
 AVCaptureSession : 管理输入到输出的数据流
 AVCaptureVideoPreviewLayer : 展示采集 预览View
 */


// 设置捕获会话： 可以设置分辨率
- (void)setupSession {
    AVCaptureSession *captureSession = [[AVCaptureSession alloc] init];
    _captureSession = captureSession;
    
    // 设置分辨率
    // AVCaptureSessionPresetHigh : [默认值] 高分辨率，会根据当前设备进行自适应
    // 720 标清
    captureSession.sessionPreset = AVCaptureSessionPreset1280x720;
}

// 会话添加输入对象 : 可以设置帧率
- (void)setupInput {
    // 2.建立输入到输出轨道
    // 2.1 获取摄像头： AVMediaTypeVideo, AVMediaTypeAudio, or AVMediaTypeMuxed
    // 使用后置摄像头
    // AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    /* AVCaptureDeviceType
     AVMediaTypeVideo
     AVMediaTypeAudio
     AVMediaTypeText
     AVMediaTypeClosedCaption
     AVMediaTypeSubtitle
     AVMediaTypeTimecode
     AVMediaTypeMetadata
     AVMediaTypeMuxed
     */
    
    /* AVCaptureDevicePosition
     AVCaptureDevicePositionUnspecified
     AVCaptureDevicePositionBack
     AVCaptureDevicePositionFront
     */
    // 使用前置摄像头
    //    AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVMediaTypeVideo mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionFront];
    
    AVCaptureDevice *videoDevice = [self deviceWithPosition:AVCaptureDevicePositionFront];
    
    // 设备输入对象
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:nil];
    // 给会话添加输入
    if([_captureSession canAddInput:videoInput]) {
        [_captureSession addInput:videoInput];
    }
}

// 会话添加输出对象: 设置原数据YUV, RGB, 设置代理获取帧数据，获取输入与输出的连接
- (void)setupOutput {
    
    // 视频输出：设置视频原数据格式：YUV, RGB （一般我们都使用YUV，因为体积比RGB小）
    // 苹果不支持YUV的渲染，只支持RGB渲染，这意味着： YUV => RGB
    AVCaptureVideoDataOutput *videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    
    // 帧率：1秒10帧
    videoOutput.minFrameDuration = CMTimeMake(1, 10);
    
    // videoSettings: 设置视频原数据格式 YUV FULL
    /*
     On iOS, the only supported key is kCVPixelBufferPixelFormatTypeKey. Supported pixel formats are kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange, kCVPixelFormatType_420YpCbCr8BiPlanarFullRange and kCVPixelFormatType_32BGRA.
     */
    
    /*
     // key
     kCVPixelBufferPixelFormatTypeKey 指定解码后的图像格式
     
     // value
     kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange  : YUV420 用于标清视频[420v]
     kCVPixelFormatType_420YpCbCr8BiPlanarFullRange   : YUV422 用于高清视频[420f]
     kCVPixelFormatType_32BGRA : 输出的是BGRA的格式，适用于OpenGL和CoreImage
     */
    
    videoOutput.videoSettings = @{(NSString *)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)};
    
    // 设置代理：获取帧数据 在异步串行队列中
    // 队列：串行/并行，这里使用串行，保证数据顺序
    dispatch_queue_t queue = dispatch_queue_create("LinXunFengSerialQueue", DISPATCH_QUEUE_SERIAL);
    [videoOutput setSampleBufferDelegate:self queue:queue];
    
    // 给会话添加输出对象
    if([_captureSession canAddOutput:videoOutput]) {
        // 给会话添加输入输出就会自动建立起连接
        [_captureSession addOutput:videoOutput];
    }
    
    // 注意： 一定要在添加之后
    // 获取输入与输出之间的连接
    AVCaptureConnection *connection = [videoOutput connectionWithMediaType:AVMediaTypeVideo];
    // 设置采集数据的方向、镜像
    connection.videoOrientation = AVCaptureVideoOrientationPortrait;
    connection.videoMirrored = YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 1. 创建捕获会话：设置分辨率
    [self setupSession];
    
    // 2. 添加输入
    [self setupInput];
    
    // 3. 添加输出
    [self setupOutput];
    
    // 开启会话
    // 一开启会话，就会在输入与输出对象之间建立起连接
    [_captureSession startRunning];
    
//    connection = [videoOutput connectionWithMediaType:AVMediaTypeVideo];
//    NSLog(@"connection-2 ==== %@", connection);
    
    // 预览图层
//    AVCaptureVideoPreviewLayer *previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:captureSession];
//    previewLayer.frame = self.view.bounds;
//    [self.view.layer  addSublayer:previewLayer];
}

- (AVCaptureDevice *)deviceWithPosition:(AVCaptureDevicePosition)position {
    NSArray *devices = [AVCaptureDevice devices];
    for (AVCaptureDevice *device in devices) {
        if(device.position == AVCaptureDevicePositionFront) {
            return device;
        }
    }
    return nil;
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
/*
 CMSampleBufferRef: 帧缓存数据，描述当前帧信息
 获取帧缓存信息 : CMSampleBufferGet
 CMSampleBufferGetDuration : 获取当前帧播放时间
 CMSampleBufferGetImageBuffer : 获取当前帧图片信息
 */
// CoreImage: 底层绘制图片
// 获取帧数据
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    // captureSession 会话如果没有强引用，这里不会得到执行
    
    // 获取图片帧数据
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CIImage *ciImage = [CIImage imageWithCVImageBuffer:imageBuffer];
    UIImage *image = [UIImage imageWithCIImage:ciImage];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.imageView.image = image;
    });
    
    NSLog(@"----- sampleBuffer ----- %@", sampleBuffer);
}

/*
 typedef struct {
 CMTimeValue value;
 CMTimeScale timescale;
 CMTimeFlags flags;
 CMTimeEpoch epoch;
 } CMTime;
 */


@end
