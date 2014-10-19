//
//  ViewController.m
//  MathParse
//
//  Created by Andrew Chun on 10/18/14.
//  Copyright (c) 2014 std::. All rights reserved.
//

#import <opencv2/opencv.hpp>
#import "Tesseract.h"
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
    [self.imagePickerController dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    if (self.currentImageView) {
        [self.currentImageView removeFromSuperview];
    }
    
    [self.imagePickerController dismissViewControllerAnimated:YES completion:nil];
    
    UIImage *chosenImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    
//    NSData *imageData = UIImageJPEGRepresentation(chosenImage, 1.00);
//    UIImage *jpgImage = [UIImage imageWithData:imageData];
    
    UIImageOrientation orientation = chosenImage.imageOrientation;
    
    cv::Size size(3, 3);
    cv::Mat cvImageMatrix = [self cvMatFromUIImage:chosenImage];
    cv::cvtColor(cvImageMatrix, cvImageMatrix, CV_BGR2GRAY);
    cv::GaussianBlur(cvImageMatrix, cvImageMatrix, size, 0);
    cv::adaptiveThreshold(cvImageMatrix, cvImageMatrix, 255, CV_ADAPTIVE_THRESH_MEAN_C, CV_THRESH_BINARY, 125, 10);
    cv::bitwise_not(cvImageMatrix, cvImageMatrix);
    
    UIImage *cvImage = [self UIImageFromCVMat:cvImageMatrix orientation:orientation];
    
    self.currentImageView = [[UIImageView alloc]initWithImage:cvImage];
    self.currentImageView.backgroundColor = [UIColor grayColor];
    self.currentImageView.frame = CGRectMake(0, 0, cvImage.size.width, cvImage.size.height);
    self.currentImageView.center = CGPointMake(CGRectGetWidth(self.view.bounds) * 0.5, CGRectGetHeight(self.view.bounds) * 0.45);
    [self.view addSubview:self.currentImageView];
    
    UIImage *finishedImage = gs_convert_image(cvImage);
    
    Tesseract* tesseract = [[Tesseract alloc]initWithDataPath:@"tessdata" language:@"eng"];
    
    [tesseract setVariableValue:@"0123456789+-/=xyXY" forKey:@"tessedit_char_whitelist"]; //limit search
    [tesseract setImage:[self toGrayscale:finishedImage]];
    [tesseract recognize];
    NSString *text = [tesseract recognizedText];
    [self.cameraButton setTitle:text forState:UIControlStateNormal];
    NSLog(@"\n%@", text);
    
    [tesseract clear];
}

- (UIImage *) toGrayscale:(UIImage*)img
{
    const int RED = 1;
    const int GREEN = 2;
    const int BLUE = 3;
    
    // Create image rectangle with current image width/height
    CGRect imageRect = CGRectMake(0, 0, img.size.width * img.scale, img.size.height * img.scale);
    
    int width = imageRect.size.width;
    int height = imageRect.size.height;
    
    // the pixels will be painted to this array
    uint32_t *pixels = (uint32_t *) malloc(width * height * sizeof(uint32_t));
    
    // clear the pixels so any transparency is preserved
    memset(pixels, 0, width * height * sizeof(uint32_t));
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // create a context with RGBA pixels
    CGContextRef context = CGBitmapContextCreate(pixels, width, height, 8, width * sizeof(uint32_t), colorSpace,
                                                 kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedLast);
    
    // paint the bitmap to our context which will fill in the pixels array
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), [img CGImage]);
    
    for(int y = 0; y < height; y++) {
        for(int x = 0; x < width; x++) {
            uint8_t *rgbaPixel = (uint8_t *) &pixels[y * width + x];
            
            uint32_t gray = 0.3 * rgbaPixel[RED] + 0.59 * rgbaPixel[GREEN] + 0.11 * rgbaPixel[BLUE];
            
            // set the pixels to gray
            rgbaPixel[RED] = gray;
            rgbaPixel[GREEN] = gray;
            rgbaPixel[BLUE] = gray;
        }
    }
    
    // create a new CGImageRef from our context with the modified pixels
    CGImageRef image = CGBitmapContextCreateImage(context);
    
    // we're done with the context, color space, and pixels
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    free(pixels);
    
    // make a new UIImage to return
    UIImage *resultUIImage = [UIImage imageWithCGImage:image
                                                 scale:img.scale
                                           orientation:UIImageOrientationUp];
    
    // we're done with image now too
    CGImageRelease(image);
    
    return resultUIImage;
}

UIImage * gs_convert_image (UIImage *src_img) {
    CGColorSpaceRef d_colorSpace = CGColorSpaceCreateDeviceRGB();
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(src_img.CGImage);
    /*
     * Note we specify 4 bytes per pixel here even though we ignore the
     * alpha value; you can't specify 3 bytes per-pixel.
     */
    size_t d_bytesPerRow = src_img.size.width * 4;
    unsigned char * imgData = (unsigned char*)malloc(src_img.size.height*d_bytesPerRow);
    CGContextRef context =  CGBitmapContextCreate(imgData,
                                                  src_img.size.width,
                                                  src_img.size.height,
                                                  8,
                                                  d_bytesPerRow,
                                                  colorSpace,
                                                  kCGImageAlphaNone);
    
    UIGraphicsPushContext(context);
    // These next two lines 'flip' the drawing so it doesn't appear upside-down.
    CGContextTranslateCTM(context, 0.0, src_img.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    // Use UIImage's drawInRect: instead of the CGContextDrawImage function, otherwise you'll have issues when the source image is in portrait orientation.
    [src_img drawInRect:CGRectMake(0.0, 0.0, src_img.size.width, src_img.size.height)];
    UIGraphicsPopContext();
    
    /*
     * At this point, we have the raw ARGB pixel data in the imgData buffer, so
     * we can perform whatever image processing here.
     */
    
    
    // After we've processed the raw data, turn it back into a UIImage instance.
    CGImageRef new_img = CGBitmapContextCreateImage(context);
    UIImage * convertedImage = [[UIImage alloc] initWithCGImage:
                                new_img];
    
    CGImageRelease(new_img);
    CGContextRelease(context);
    CGColorSpaceRelease(d_colorSpace);
    free(imgData);
    return convertedImage;
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
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef scale:7.00 orientation:orientation];
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
