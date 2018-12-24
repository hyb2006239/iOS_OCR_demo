//
//  OCRManager.h
//  iOS_Tesseract_demo
//
//  Created by 黄云碧 on 2018/12/18.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
typedef void (^CompleteBlock)(NSString *result);

@interface OCRManager : NSObject
+ (instancetype)shareInstance;
-(void)recognizeImageWithTesseract:(UIImage *)image withComplete:(CompleteBlock)complete;
@end
