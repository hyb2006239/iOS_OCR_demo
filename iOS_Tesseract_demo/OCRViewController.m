//
//  OCRViewController.m
//  iOS_Tesseract_demo
//
//  Created by 黄云碧 on 2018/12/18.
//

#import "OCRViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "ImageAddition.h"
#import "OCRManager.h"

#define m_scanViewY  50.0
#define m_scale [UIScreen mainScreen].scale
#define SCREEN_WIDTH     [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT     [UIScreen mainScreen].bounds.size.height
@interface OCRViewController ()
{
    NSTimer *timer;
    UILabel *textLabel;
    BOOL isBegining;
    AVCaptureDevice *device;
    NSString *recognizedText;
    BOOL isFocus;
    
}
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureDeviceInput *videoInput;
@property (nonatomic, strong) AVCaptureStillImageOutput *stillImageOutput;
@property (nonatomic, strong) AVCaptureVideoDataOutput *captureVideoDataOutput;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

@property (nonatomic, strong) UIImage *myImage;


@end

@implementation OCRViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        //给个默认值
        self.m_width = (SCREEN_WIDTH - 20);
        self.m_higth = 50.0;
        //([0-9A-Z]{20})+\_+[0-9A-Z]{8}
        self.regular = @"";
        recognizedText = @"";
    }
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"扫一扫";
//    UIButton *leftBtn = [UIButton buttonWithType:UIButtonTypeCustom];
//    UIImage *leftImage = [UIImage imageNamed:@"back_icon"];
//    [leftBtn setImage:leftImage forState:UIControlStateNormal];
//    [leftBtn setTitleColor:[[KKSkinManager getInstance] kkNavButtonColor] forState:UIControlStateNormal];
//    [leftBtn setTitle:KKLocalizedString(@"m01_back") forState:UIControlStateNormal];
//    [leftBtn setFrame:CGRectMake(0, 0, 80, 40)];
//    [leftBtn addTarget:self action:@selector(goBack) forControlEvents:UIControlEventTouchUpInside];
//
//    if (IOS11) {
//        [leftBtn setImageEdgeInsets:UIEdgeInsetsMake(0, -20, 0, 20)];
//        [leftBtn setTitleEdgeInsets:UIEdgeInsetsMake(0, -20, 0, 20)];
//    }
//
//    UIBarButtonItem *backBtn = [[UIBarButtonItem alloc] initWithCustomView:leftBtn];
//    UIBarButtonItem *nagativeSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
//    nagativeSpace.width = -20;
//
//    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:nagativeSpace,backBtn, nil];
    
    self.navigationController.navigationBar.translucent = NO;
    self.view.backgroundColor = [UIColor blackColor];
    
    isBegining = NO;
    self.myImage = [[UIImage alloc] init];
    
    //如果传值比屏幕大，就用默认值

    if (self.m_width > SCREEN_WIDTH) {
        self.m_width = (SCREEN_WIDTH - 20);
    }
    if (self.m_higth > SCREEN_HEIGHT) {
        self.m_higth = 50.0;
    }
    
    
    [self initAVCaptureSession];
    
    
}
- (void)initAVCaptureSession{
    
    self.session = [[AVCaptureSession alloc] init];
    NSError *error;
    
    device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    self.videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:device error:&error];
    if (error) {
        NSLog(@"%@",error);
    }
    self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    //输出设置。AVVideoCodecJPEG   输出jpeg格式图片
    NSDictionary * outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG,AVVideoCodecKey, nil];
    [self.stillImageOutput setOutputSettings:outputSettings];
    
    NSString* key = (NSString*)kCVPixelBufferPixelFormatTypeKey;
    NSNumber* value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA];
    NSDictionary* videoSettings = [NSDictionary
                                   dictionaryWithObject:value forKey:key];
    self.captureVideoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    [self.captureVideoDataOutput setVideoSettings:videoSettings];
    
    
    dispatch_queue_t queue;
    queue = dispatch_queue_create("cameraQueue", NULL);
    [self.captureVideoDataOutput setSampleBufferDelegate:self queue:queue];
    
    if ([self.session canAddInput:self.videoInput]) {
        [self.session addInput:self.videoInput];
    }
    if ([self.session canAddOutput:self.captureVideoDataOutput]) {
        [self.session addOutput:self.captureVideoDataOutput];
    }
    
    //输出照片铺满屏幕

    if ([self.session canSetSessionPreset:AVCaptureSessionPresetHigh]) {
        
        self.session.sessionPreset = AVCaptureSessionPresetHigh;
        
    }
    
    //初始化预览图层
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if (orientation == UIInterfaceOrientationPortrait) {
        [[self.previewLayer connection] setVideoOrientation:AVCaptureVideoOrientationPortrait];
        
    }
    else if (orientation == UIInterfaceOrientationLandscapeLeft) {
        [[self.previewLayer connection] setVideoOrientation:AVCaptureVideoOrientationLandscapeLeft];
        
    }
    else if (orientation == UIInterfaceOrientationLandscapeRight) {
        [[self.previewLayer connection] setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
        
    }
    else {
        [[self.previewLayer connection] setVideoOrientation:AVCaptureVideoOrientationPortraitUpsideDown];
        
    }
    
    self.previewLayer.frame = CGRectMake(0,0, SCREEN_WIDTH,SCREEN_HEIGHT);
    
    [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
    self.view.layer.masksToBounds = YES;
    [self.view.layer addSublayer:self.previewLayer];
    
    //扫描框
    [self initScanView];
    
    textLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, (SCREEN_HEIGHT - 100)/2.0, SCREEN_WIDTH, 100)];
    textLabel.textAlignment = NSTextAlignmentCenter;
    textLabel.numberOfLines = 0;
    
    textLabel.font = [UIFont systemFontOfSize:19];
        

    
    textLabel.textColor = [UIColor whiteColor];
    [self.view addSubview:textLabel];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.view addSubview:button];
    button.frame = CGRectMake((SCREEN_WIDTH - 100)/2.0, SCREEN_HEIGHT - 164, 100, 50);
    [button setTitle:@"完成" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(clickedFinishBtn:) forControlEvents:UIControlEventTouchUpInside];
    
    
    int flags =NSKeyValueObservingOptionNew;
    [device addObserver:self forKeyPath:@"adjustingFocus" options:flags context:nil];
    
    //更改这个设置的时候必须先锁定设备，修改完后再解锁，否则崩溃
    [device lockForConfiguration:nil];
    //设置闪光灯为自动
    if ([device isFlashModeSupported:AVCaptureFlashModeAuto]) {
        [device setFlashMode:AVCaptureFlashModeAuto];
    }
    //自动对焦
    if ([device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
        [device setFocusMode:AVCaptureFocusModeAutoFocus];
    }
    
    [device unlockForConfiguration];
    
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(tesseractImage) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    
    //    mySwitch = [[UISwitch alloc] initWithFrame:CGRectMake((SCREEN_WIDTH - 80), SCREEN_HEIGHT - 164, 80, 40)];
    //    [self.view addSubview:mySwitch];
    //    mySwitch.on = NO;
    
    
}
- (void)initScanView
{
    UILabel *tipLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, m_scanViewY - 30, SCREEN_WIDTH, 25)];
    [self.view addSubview:tipLabel];
    tipLabel.text = @"轻点屏幕对焦";
    tipLabel.textAlignment = NSTextAlignmentCenter;
    tipLabel.textColor = [UIColor whiteColor];
    // 中间空心洞的区域
    CGRect cutRect = CGRectMake((SCREEN_WIDTH - _m_width)/2.0,m_scanViewY, _m_width, _m_higth);
    
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:CGRectMake(0,0, SCREEN_WIDTH,SCREEN_HEIGHT)];
    // 挖空心洞 显示区域
    UIBezierPath *cutRectPath = [UIBezierPath bezierPathWithRect:cutRect];
    
    //        将circlePath添加到path上
    [path appendPath:cutRectPath];
    path.usesEvenOddFillRule = YES;
    
    CAShapeLayer *fillLayer = [CAShapeLayer layer];
    fillLayer.path = path.CGPath;
    fillLayer.fillRule = kCAFillRuleEvenOdd;
    fillLayer.opacity = 0.2;//透明度
    fillLayer.backgroundColor = [UIColor lightGrayColor].CGColor;
    [self.view.layer addSublayer:fillLayer];
    
    
    // 边界校准线
    const CGFloat lineWidth = 2;
    UIBezierPath *linePath = [UIBezierPath bezierPathWithRect:CGRectMake(cutRect.origin.x - lineWidth,
                                                                         cutRect.origin.y - lineWidth,
                                                                         cutRect.size.width / 4.0,
                                                                         lineWidth)];
    //        追加路径
    [linePath appendPath:[UIBezierPath bezierPathWithRect:CGRectMake(cutRect.origin.x - lineWidth,
                                                                     cutRect.origin.y - lineWidth,
                                                                     lineWidth,
                                                                     cutRect.size.height / 4.0)]];
    
    [linePath appendPath:[UIBezierPath bezierPathWithRect:CGRectMake(cutRect.origin.x + cutRect.size.width - cutRect.size.width / 4.0 + lineWidth,
                                                                     cutRect.origin.y - lineWidth,
                                                                     cutRect.size.width / 4.0,
                                                                     lineWidth)]];
    [linePath appendPath:[UIBezierPath bezierPathWithRect:CGRectMake(cutRect.origin.x + cutRect.size.width ,
                                                                     cutRect.origin.y - lineWidth,
                                                                     lineWidth,
                                                                     cutRect.size.height / 4.0)]];
    
    [linePath appendPath:[UIBezierPath bezierPathWithRect:CGRectMake(cutRect.origin.x - lineWidth,
                                                                     cutRect.origin.y + cutRect.size.height - cutRect.size.height / 4.0 + lineWidth,
                                                                     lineWidth,
                                                                     cutRect.size.height / 4.0)]];
    [linePath appendPath:[UIBezierPath bezierPathWithRect:CGRectMake(cutRect.origin.x - lineWidth,
                                                                     cutRect.origin.y + cutRect.size.height,
                                                                     cutRect.size.width / 4.0,
                                                                     lineWidth)]];
    
    [linePath appendPath:[UIBezierPath bezierPathWithRect:CGRectMake(cutRect.origin.x + cutRect.size.width,
                                                                     cutRect.origin.y + cutRect.size.height - cutRect.size.height / 4.0 + lineWidth,
                                                                     lineWidth,
                                                                     cutRect.size.height / 4.0)]];
    [linePath appendPath:[UIBezierPath bezierPathWithRect:CGRectMake(cutRect.origin.x + cutRect.size.width - cutRect.size.width / 4.0 + lineWidth,
                                                                     cutRect.origin.y + cutRect.size.height,
                                                                     cutRect.size.width / 4.0,
                                                                     lineWidth)]];
    
    CAShapeLayer *pathLayer = [CAShapeLayer layer];
    pathLayer.path = linePath.CGPath;// 从贝塞尔曲线获取到形状
    pathLayer.fillColor = [UIColor greenColor].CGColor; // 闭环填充的颜色
    //        pathLayer.lineCap       = kCALineCapSquare;               // 边缘线的类型
    //    pathLayer.strokeColor = [UIColor greenColor].CGColor; // 边缘线的颜色
    //        pathLayer.lineWidth     = 4.0f;                           // 线条宽度
    [self.view.layer addSublayer:pathLayer];
    
    //    //        扫描条动画
    //    UIImageView *line = [[UIImageView alloc] initWithFrame:CGRectMake(cutRect.origin.x + cutRect.size.width/8.0,
    //                                                                      cutRect.origin.y,
    //                                                                      cutRect.size.width - cutRect.size.width/4.0,
    //                                                                      lineWidth)];
    //    line.image = [[UIImage imageNamed:@"line"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    //    line.tintColor = [UIColor greenColor];
    //    [self.view addSubview:line];
    //
    //    // 上下游走动画
    //    CABasicAnimation *animation=[CABasicAnimation animationWithKeyPath:@"transform.translation.y"];
    //    animation.fromValue = @0;
    //    animation.toValue = [NSNumber numberWithFloat:cutRect.size.height];
    //    animation.autoreverses = YES;
    //    animation.duration = 3;
    //    animation.repeatCount = FLT_MAX;
    //    animation.removedOnCompletion = NO;
    //    animation.fillMode = kCAFillModeForwards;
    //    [line.layer addAnimation:animation forKey:@"A"];
    
    
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
    if (isFocus && !isBegining) {
        
        //        NSTimeInterval nowTime = [[NSDate date] timeIntervalSince1970];
        
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        CVPixelBufferLockBaseAddress(imageBuffer,0);
        uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
        size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
        size_t width = CVPixelBufferGetWidth(imageBuffer);
        size_t height = CVPixelBufferGetHeight(imageBuffer);
        
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef newContext = CGBitmapContextCreate(baseAddress,
                                                        width, height, 8, bytesPerRow, colorSpace,
                                                        kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
        CGImageRef newImage = CGBitmapContextCreateImage(newContext);
        
        CGContextRelease(newContext);
        CGColorSpaceRelease(colorSpace);
        
        CGFloat scale = [UIScreen mainScreen].scale;
        UIImage *image = [UIImage imageWithCGImage:newImage scale:scale orientation:UIImageOrientationRight];
        
        CGImageRelease(newImage);
        CVPixelBufferUnlockBaseAddress(imageBuffer,0);
        
        self.myImage = image;
        
        
    }
    
    
}

- (void)viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:YES];
    
    if (self.session) {
        
        [self.session startRunning];
    }
}


- (void)viewDidDisappear:(BOOL)animated{
    
    [super viewDidDisappear:YES];
    
    if (self.session) {
        
        [self.session stopRunning];
    }
    self.myImage = nil;
    [device removeObserver:self forKeyPath:@"adjustingFocus" context:nil];
    
    [timer invalidate];
    timer = nil;
}

- (void)dealloc
{
    [timer invalidate];
    timer = nil;
}

- (void)clickedFinishBtn:(UIButton *)sender {
    
    [timer invalidate];
    timer = nil;

    [self dismissViewControllerAnimated:YES completion:nil];
    
}
- (void)tesseractImage
{
    if (isFocus && !isBegining) {
        isBegining = YES;
        UIImage *img = self.myImage;
        [self recognizeImageWithTesseract:img];
        
    }
}

-(void)recognizeImageWithTesseract:(UIImage *)image
{
    NSTimeInterval beginTime = [[NSDate date] timeIntervalSince1970];
    
    //    logDebug(TAG, @"recognizeImage begin=%.3f秒",beginTime);
    UIImage *img = image;
    
    //    if (mySwitch.on) {
    //        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
    //        UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil);
    //    }

    img = [self fixOrientation:img];
    
    //在画布展开照片
    img = [self image:img scaleToSize:CGSizeMake(SCREEN_WIDTH, SCREEN_HEIGHT)];
    
    //截图
    img = [self imageFromImage:img inRect:CGRectMake((SCREEN_WIDTH - _m_width)*0.5*m_scale, m_scanViewY*m_scale, _m_width*m_scale ,_m_higth*m_scale)];
        
    
    [[OCRManager shareInstance] recognizeImageWithTesseract:img withComplete:^(NSString *result) {
        NSTimeInterval endTime = [[NSDate date] timeIntervalSince1970];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (result != nil && result.length > 0) {
                NSString *str = [NSString stringWithString:result];
                str = [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]; //去除掉首尾的空白字符和换行字符
                str = [str stringByReplacingOccurrencesOfString:@" " withString:@""];
                BOOL isMatch = YES;
                if (str.length > 0) {
                    //过滤
                    if (self.regular.length > 0) {
                        NSString *pattern = self.regular;
                        NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", pattern];
                        isMatch = [pred evaluateWithObject:str];
                    }
                    
                    if (isMatch) {
                        self->recognizedText = str;
                        textLabel.text = recognizedText;
                    }
                }
                
            }
            
            self->isBegining = NO;
        });
        
    }];
    
}


//截取图片
-(UIImage*)image:(UIImage *)imageI scaleToSize:(CGSize)size{
    /*
     UIGraphicsBeginImageContextWithOptions(CGSize size, BOOL opaque, CGFloat scale)
     CGSize size：指定将来创建出来的bitmap的大小
     BOOL opaque：设置透明YES代表透明，NO代表不透明
     CGFloat scale：代表缩放,0代表不缩放
     创建出来的bitmap就对应一个UIImage对象
     */
    UIGraphicsBeginImageContextWithOptions(size, NO, m_scale); //此处将画布放大两倍，这样在retina屏截取时不会影响像素
    
    [imageI drawInRect:CGRectMake(0, 0, size.width, size.height)];
    
    
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return scaledImage;
}
-(UIImage *)imageFromImage:(UIImage *)imageI inRect:(CGRect)rect{
    
    CGImageRef sourceImageRef = [imageI CGImage];
    
    CGImageRef newImageRef = CGImageCreateWithImageInRect(sourceImageRef, rect);
    
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];
    
    CGImageRelease(newImageRef);
    
    return newImage;
}
//对焦
- (void)focus
{
    [device lockForConfiguration:nil];
    
    if ([device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
        [device setFocusMode:AVCaptureFocusModeAutoFocus];
    }
    
    [device unlockForConfiguration];
}

-(void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    if([keyPath isEqualToString:@"adjustingFocus"]){
        BOOL adjustingFocus =[[change objectForKey:NSKeyValueChangeNewKey] isEqualToNumber:[NSNumber numberWithInt:1]];
        if (adjustingFocus) {
            isFocus = YES;
        }
        
        NSLog(@"Is adjusting focus? %@", adjustingFocus ?@"YES":@"NO");
    }
}
-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self focus];
}

- (UIImage*)fixOrientation:(UIImage *)img
{
    // No-op if the orientation is already correct
    if (img.imageOrientation == UIImageOrientationUp) return img;
    
    UIImage *result;
    
    UIGraphicsBeginImageContextWithOptions(img.size, NO, img.scale);
    
    [img drawInRect:(CGRect){0, 0, img.size}];
    result = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return result;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
