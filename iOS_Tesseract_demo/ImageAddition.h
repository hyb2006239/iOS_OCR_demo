//
//  ImageAddition.h
//
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@interface ImageAddition : NSObject

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize;
+ (UIImage*)getGrayImage:(UIImage*)sourceImage;
+ (UIImage*)makeRoundCornerImage:(UIImage*)img;

+ (UIImage *)imageByScalingToMaxSize:(UIImage *)sourceImage originalMaxWidth:(float)originalMaxWidth;
+ (UIImage *)imageByScalingAndCroppingForSourceImage:(UIImage *)sourceImage targetSize:(CGSize)targetSize;



+ (UIImage*)originImage:(UIImage *)image scaleToSize:(CGSize)size;
+ (UIImage*)originImage:(UIImage *)image scaleToSize:(CGSize)size scale:(CGFloat)scale;

+ (UIImage *)addImage:(UIImage *)addedImage
              toImage:(UIImage *)toImage;
@end
