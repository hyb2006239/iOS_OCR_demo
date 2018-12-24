//
//  OCRManager.m
//  iOS_Tesseract_demo
//
//  Created by 黄云碧 on 2018/12/18.
//

#import "OCRManager.h"
#import <TesseractOCR/TesseractOCR.h>
@interface OCRManager()
{
    
}
@property (nonatomic, strong) NSOperationQueue *operationQueue;
@end

@implementation OCRManager
+ (instancetype)shareInstance {
    static OCRManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[OCRManager alloc] init];
        
    });
    return manager;
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.operationQueue = [[NSOperationQueue alloc] init];
        
    }
    return self;
}

-(void)recognizeImageWithTesseract:(UIImage *)image withComplete:(CompleteBlock)complete
{
    UIImage *img = image;
    
    //1.初始化，选择英文库
    G8RecognitionOperation *operation = [[G8RecognitionOperation alloc] init];
    operation.tesseract.language = @"eng";
    //2.这个模式识别最快，但识别率差点
    operation.tesseract.engineMode = G8OCREngineModeTesseractOnly;
    
    //3.让Tesseract自动将页面分割成文本块
    operation.tesseract.pageSegmentationMode = G8PageSegmentationModeAutoOnly;
    
    //4.限制Tesseract执行该操作所需的时间
    //    operation.tesseract.maximumRecognitionTime = 10.0;
    
    //5.白名单
    operation.tesseract.charWhitelist = @"abcdefghijklmnopqrstuvwsyzABCDEFGHIJKLMNOPQRSTUVWSYZ1234567890_";
    //6.黑名单
    operation.tesseract.charBlacklist = @"`~!@#$%^&*()+='/?.>,<-";
    
    //7.要识别的图片
    operation.tesseract.image = [img g8_blackAndWhite];
    operation.tesseract.image = img;
    
    
    //9.开始识别
    operation.recognitionCompleteBlock = ^(G8Tesseract *tesseract) {
        NSString *recognizedText = tesseract.recognizedText;
        complete(recognizedText);
        
    };
    
    // Finally, add the recognition operation to the queue
    [self.operationQueue addOperation:operation];
}


@end
