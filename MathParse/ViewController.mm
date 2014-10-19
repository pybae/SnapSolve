//
//  ViewController.m
//  MathParse
//
//  Created by Andrew Chun on 10/18/14.
//  Copyright (c) 2014 std::. All rights reserved.
//

#import <opencv2/opencv.hpp>
#import <TesseractOCR/TesseractOCR.h>
#import "ViewController.h"
#include <stack>
#include <string>
#include <vector>

@interface ViewController ()

@property (strong, nonatomic) UIButton                  *cameraButton;
@property (strong, nonatomic) UIImagePickerController   *imagePickerController;
@property (strong, nonatomic) UIImageView               *currentImageView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.cameraButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.cameraButton.frame = CGRectMake(0, 0, 100, 50);
    self.cameraButton.center = CGPointMake(CGRectGetWidth(self.view.bounds) * 0.50, CGRectGetHeight(self.view.bounds) * 0.90);
    
    [self.cameraButton setTitle:@"Camera" forState:UIControlStateNormal];
    [self.cameraButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.cameraButton];
    
    NSString *equation = @"1+1*2-4";
    std::string *bar = new std::string([equation UTF8String]);
    int result = solve(*bar);
    NSLog(@"Result: %d", result);
}

- (void)buttonPressed:(UIButton *)sender
{
    if (sender == self.cameraButton) {
        self.imagePickerController = [[UIImagePickerController alloc]init];
        self.imagePickerController.delegate = self;
        self.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
        [self presentViewController:self.imagePickerController animated:YES completion:nil];
        NSLog(@"Presented Camera ViewController");
    } else {
        
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self.imagePickerController dismissViewControllerAnimated:self completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    if (self.currentImageView) {
        [self.currentImageView removeFromSuperview];
    }
    
    [self.imagePickerController dismissViewControllerAnimated:YES completion:nil];
    
    UIImage *chosenImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    UIImageOrientation orientation = chosenImage.imageOrientation;
    
    cv::Size size(3, 3);
    cv::Mat cvImageMatrix = [self cvMatFromUIImage:chosenImage];
    cv::cvtColor(cvImageMatrix, cvImageMatrix, CV_BGR2GRAY);
    cv::GaussianBlur(cvImageMatrix, cvImageMatrix, size, 0);
    cv::adaptiveThreshold(cvImageMatrix, cvImageMatrix, 255, CV_ADAPTIVE_THRESH_MEAN_C, CV_THRESH_BINARY, 75, 10);
    cv::bitwise_not(cvImageMatrix, cvImageMatrix);
    
    UIImage *cvImage = [self UIImageFromCVMat:cvImageMatrix orientation:orientation];
    
    self.currentImageView = [[UIImageView alloc]initWithImage:cvImage];
    self.currentImageView.backgroundColor = [UIColor grayColor];
    self.currentImageView.frame = CGRectMake(0, 0, cvImage.size.width * 0.15, cvImage.size.height * 0.15);
    self.currentImageView.center = CGPointMake(CGRectGetWidth(self.view.bounds) * 0.5, CGRectGetHeight(self.view.bounds) * 0.45);
    [self.view addSubview:self.currentImageView];
}

- (cv::Mat)cvMatFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    if  (image.imageOrientation == UIImageOrientationLeft
         || image.imageOrientation == UIImageOrientationRight) {
        cols = image.size.height;
        rows = image.size.width;
    }
    
    cv::Mat cvMat = *new cv::Mat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}

-(UIImage *)UIImageFromCVMat:(cv::Mat)cvMat orientation:(UIImageOrientation)orientation
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                            //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef scale:1 orientation:orientation];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//Does not work if first character is '-'
int solve(std::string a) {
    std::vector<int> postfix;
    std::stack<char> ops;
    
    char op;
    int num1, num2;
    
    postfix.push_back(0);
    
    for(int i = 0; i < a.length(); ++i) {
        if(a[i] >= '0' && a[i] <= '9') {
            postfix[postfix.size() - 1] *= 10;
            postfix[postfix.size() - 1] += a[i] - '0';
        } else {
            if((a[i] == '+' || a[i] == '-') &&
               !ops.empty() && (ops.top() == '*' || ops.top() == '/')) {
                while(!ops.empty()) {
                    op = ops.top();
                    ops.pop();
                    num2 = postfix.back();
                    postfix.pop_back();
                    num1 = postfix.back();
                    postfix.pop_back();
                    
                    if(op == '+') {
                        postfix.push_back(num1 + num2);
                    } else if(op == '-') {
                        postfix.push_back(num1 - num2);
                    } else if(op == '*') {
                        postfix.push_back(num1 * num2);
                    } else if(op == '/') {
                        postfix.push_back(num1 / num2);
                    } else {
                        throw -1;
                    }
                }
            }
            
            ops.push(a[i]);
            postfix.push_back(0);
        }
    }
    
    while(!ops.empty()) {
        op = ops.top();
        ops.pop();
        num2 = postfix.back();
        postfix.pop_back();
        num1 = postfix.back();
        postfix.pop_back();
        
        if(op == '+') {
            postfix.push_back(num1 + num2);
        } else if(op == '-') {
            postfix.push_back(num1 - num2);
        } else if(op == '*') {
            postfix.push_back(num1 * num2);
        } else if(op == '/') {
            postfix.push_back(num1 / num2);
        } else {
            throw -1;
        }
    }
    
    return postfix.back();
}

@end
