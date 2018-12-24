//
//  ViewController.m
//  iOS_Tesseract_demo
//
//  Created by 黄云碧 on 2018/12/18.
//

#import "ViewController.h"
#import "OCRViewController.h"
@interface ViewController ()
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)start:(id)sender {
    
    OCRViewController *ctl = [[OCRViewController alloc] initWithNibName:@"OCRViewController" bundle:nil];
    [self presentViewController:ctl animated:YES completion:nil];
    
}

@end
