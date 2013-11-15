//
//  CLAdjustmentTool.m
//
//  Created by sho yakushiji on 2013/10/23.
//  Copyright (c) 2013年 CALACULU. All rights reserved.
//

#import "CLAdjustmentTool.h"

#import "UIImage+Utility.h"
#import "UIView+Frame.h"

@implementation CLAdjustmentTool
{
    UIImage *_originalImage;
    UIImage *_thumnailImage;
    
    UISlider *_saturationSlider;
    UISlider *_brightnessSlider;
    UISlider *_contrastSlider;
    UIActivityIndicatorView *_indicatorView;
}

+ (NSString*)title
{
    return @"Adjustment";
}

+ (BOOL)isAvailable
{
    return ([UIDevice iosVersion] >= 5.0);
}

- (void)setup
{
    _originalImage = self.editor.imageView.image;
    _thumnailImage = [_originalImage resize:self.editor.imageView.frame.size];
    
    CGFloat minZoomScale = self.editor.scrollView.minimumZoomScale;
    self.editor.scrollView.maximumZoomScale = 0.95*minZoomScale;
    self.editor.scrollView.minimumZoomScale = 0.95*minZoomScale;
    [self.editor.scrollView setZoomScale:self.editor.scrollView.minimumZoomScale animated:YES];
    
    [self setupSlider];
}

- (void)cleanup
{
    [_indicatorView removeFromSuperview];
    [_saturationSlider.superview removeFromSuperview];
    [_brightnessSlider.superview removeFromSuperview];
    [_contrastSlider.superview removeFromSuperview];
    
    [self.editor resetZoomScaleWithAnimate:YES];
}

- (void)executeWithCompletionBlock:(void(^)(UIImage *image, NSError *error, NSDictionary *userInfo))completionBlock
{
    dispatch_async(dispatch_get_main_queue(), ^{
        _indicatorView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 80, 80)];
        _indicatorView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6];
        _indicatorView.layer.cornerRadius = 5;
        _indicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
        _indicatorView.center = self.editor.view.center;
        [self.editor.view addSubview:_indicatorView];
        [_indicatorView startAnimating];
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *image = [self filteredImage:_originalImage];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completionBlock(image, nil, nil);
        });
    });
}

#pragma mark- 

- (UISlider*)sliderWithValue:(CGFloat)value minimumValue:(CGFloat)min maximumValue:(CGFloat)max action:(SEL)action
{
    UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(10, 0, 240, 35)];
    
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 260, slider.height)];
    container.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.3];
    container.layer.cornerRadius = slider.height/2;
    
    slider.continuous = YES;
    [slider addTarget:self action:action forControlEvents:UIControlEventValueChanged];
    
    slider.maximumValue = max;
    slider.minimumValue = min;
    slider.value = value;
    
    [container addSubview:slider];
    [self.editor.view addSubview:container];
    
    return slider;
}

- (void)setupSlider
{
    _saturationSlider = [self sliderWithValue:1 minimumValue:0 maximumValue:2 action:@selector(sliderDidChange:)];
    _saturationSlider.superview.center = CGPointMake(self.editor.view.width/2, self.editor.menuView.top-30);
    [_saturationSlider setThumbImage:[UIImage imageNamed:[NSString stringWithFormat:@"CLImageEditor.bundle/%@/saturation.png", [self class]]] forState:UIControlStateNormal];
    [_saturationSlider setThumbImage:[UIImage imageNamed:[NSString stringWithFormat:@"CLImageEditor.bundle/%@/saturation.png", [self class]]] forState:UIControlStateHighlighted];
    
    _brightnessSlider = [self sliderWithValue:0 minimumValue:-1 maximumValue:1 action:@selector(sliderDidChange:)];
    _brightnessSlider.superview.center = CGPointMake(20, _saturationSlider.superview.top - 150);
    _brightnessSlider.superview.transform = CGAffineTransformMakeRotation(-M_PI * 90 / 180.0f);
    [_brightnessSlider setThumbImage:[UIImage imageNamed:[NSString stringWithFormat:@"CLImageEditor.bundle/%@/brightness.png", [self class]]] forState:UIControlStateNormal];
    [_brightnessSlider setThumbImage:[UIImage imageNamed:[NSString stringWithFormat:@"CLImageEditor.bundle/%@/brightness.png", [self class]]] forState:UIControlStateHighlighted];
    
    _contrastSlider = [self sliderWithValue:1 minimumValue:0.5 maximumValue:1.5 action:@selector(sliderDidChange:)];
    _contrastSlider.superview.center = CGPointMake(300, _brightnessSlider.superview.center.y);
    _contrastSlider.superview.transform = CGAffineTransformMakeRotation(-M_PI * 90 / 180.0f);
    [_contrastSlider setThumbImage:[UIImage imageNamed:[NSString stringWithFormat:@"CLImageEditor.bundle/%@/contrast.png", [self class]]] forState:UIControlStateNormal];
    [_contrastSlider setThumbImage:[UIImage imageNamed:[NSString stringWithFormat:@"CLImageEditor.bundle/%@/contrast.png", [self class]]] forState:UIControlStateHighlighted];
}

- (void)sliderDidChange:(UISlider*)sender
{
    static BOOL inProgress = NO;
    
    if(inProgress){ return; }
    inProgress = YES;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *image = [self filteredImage:_thumnailImage];
        [self.editor.imageView performSelectorOnMainThread:@selector(setImage:) withObject:image waitUntilDone:NO];
        inProgress = NO;
    });
}

- (UIImage*)filteredImage:(UIImage*)image
{
    CIImage *ciImage = [[CIImage alloc] initWithImage:image];
    CIFilter *filter = [CIFilter filterWithName:@"CIColorControls" keysAndValues:kCIInputImageKey, ciImage, nil];
    
    [filter setDefaults];
    [filter setValue:[NSNumber numberWithFloat:_saturationSlider.value] forKey:@"inputSaturation"];
    
    filter = [CIFilter filterWithName:@"CIExposureAdjust" keysAndValues:kCIInputImageKey, [filter outputImage], nil];
    [filter setDefaults];
    CGFloat brightness = 2*_brightnessSlider.value;
    [filter setValue:[NSNumber numberWithFloat:brightness] forKey:@"inputEV"];
    
    filter = [CIFilter filterWithName:@"CIGammaAdjust" keysAndValues:kCIInputImageKey, [filter outputImage], nil];
    [filter setDefaults];
    CGFloat contrast   = _contrastSlider.value*_contrastSlider.value;
    [filter setValue:[NSNumber numberWithFloat:contrast] forKey:@"inputPower"];
    
    CIContext *context = [CIContext contextWithOptions:nil];
    CIImage *outputImage = [filter outputImage];
    CGImageRef cgImage = [context createCGImage:outputImage fromRect:[outputImage extent]];
    
    UIImage *result = [UIImage imageWithCGImage:cgImage];
    
    CGImageRelease(cgImage);
    
    return result;
}

@end
