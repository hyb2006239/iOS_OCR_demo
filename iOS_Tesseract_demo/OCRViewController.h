//
//  OCRViewController.h
//  iOS_Tesseract_demo
//
//  Created by 黄云碧 on 2018/12/18.
//

#import <UIKit/UIKit.h>

@interface OCRViewController : UIViewController
@property (nonatomic,assign) CGFloat m_width; //扫描框宽度
@property (nonatomic,assign) CGFloat m_higth; //扫描框高度
@property (nonatomic,retain) NSString *regular; //过滤正则
@end
