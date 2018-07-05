//
//  CLAdjustmentTool.m
//
//  Created by sho yakushiji on 2013/10/23.
//  Copyright (c) 2013年 CALACULU. All rights reserved.
//

#import "CLAdjustmentTool.h"

static NSString* const kCLAdjustmentToolSaturationIconName = @"saturationIconAssetsName";
static NSString* const kCLAdjustmentToolBrightnessIconName = @"brightnessIconAssetsName";
static NSString* const kCLAdjustmentToolContrastIconName = @"contrastIconAssetsName";


@implementation CLAdjustmentTool
{
    UIImage *_originalImage;
    UIImage *_thumbnailImage;
    
    UISlider *_saturationSlider;
    UISlider *_brightnessSlider;
    UISlider *_contrastSlider;
    UIActivityIndicatorView *_indicatorView;
}

+ (NSString*)defaultTitle
{
    return [CLImageEditorTheme localizedString:@"CLAdjustmentTool_DefaultTitle" withDefault:@"Adjustment"];
}

+ (BOOL)isAvailable
{
    return ([UIDevice iosVersion] >= 5.0);
}

- (void)setup
{
    _originalImage = self.editor.imageView.image;
    _thumbnailImage = [_originalImage resize:self.editor.imageView.frame.size];
    
    [self.editor fixZoomScaleWithAnimated:YES];
    
    [self setupSlider];
}

- (void)cleanup
{
    [_indicatorView removeFromSuperview];
    [_saturationSlider.superview removeFromSuperview];
    [_brightnessSlider.superview removeFromSuperview];
    [_contrastSlider.superview removeFromSuperview];
    
    [self.editor resetZoomScaleWithAnimated:YES];
}

- (void)executeWithCompletionBlock:(void(^)(UIImage *image, NSError *error, NSDictionary *userInfo))completionBlock
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self->_indicatorView = [CLImageEditorTheme indicatorView];
        self->_indicatorView.center = self.editor.view.center;
        [self.editor.view addSubview:self->_indicatorView];
        [self->_indicatorView startAnimating];
    });
    
    CGFloat saturation = _saturationSlider.value;
    CGFloat brightness = _brightnessSlider.value;
    CGFloat contrast   = _contrastSlider.value;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *image = [self filteredImage:self->_originalImage saturation:saturation brightness:brightness contrast:contrast];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completionBlock(image, nil, nil);
        });
    });
}

#pragma mark- optional info

+ (NSDictionary*)optionalInfo
{
    return @{
             kCLAdjustmentToolSaturationIconName : @"",
             kCLAdjustmentToolBrightnessIconName : @"",
             kCLAdjustmentToolContrastIconName : @""
             };
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

- (void)setIconForSlider:(UISlider*)slider withKey:(NSString*)key defaultIconName:(NSString*)defaultIconName
{
    UIImage *icon = [self imageForKey:key defaultImageName:defaultIconName];
    [slider setThumbImage:icon forState:UIControlStateNormal];
    [slider setThumbImage:icon forState:UIControlStateHighlighted];
}

- (void)setupSlider
{
    _saturationSlider = [self sliderWithValue:1 minimumValue:0 maximumValue:2 action:@selector(sliderDidChange:)];
    _saturationSlider.superview.center = CGPointMake(self.editor.view.width/2, self.editor.menuView.top-30);
    [self setIconForSlider:_saturationSlider withKey:kCLAdjustmentToolSaturationIconName defaultIconName:@"saturation.png"];
    
    _brightnessSlider = [self sliderWithValue:0 minimumValue:-1 maximumValue:1 action:@selector(sliderDidChange:)];
    _brightnessSlider.superview.center = CGPointMake(20, _saturationSlider.superview.top - 150);
    _brightnessSlider.superview.transform = CGAffineTransformMakeRotation(-M_PI * 90 / 180.0f);
    [self setIconForSlider:_brightnessSlider withKey:kCLAdjustmentToolBrightnessIconName defaultIconName:@"brightness.png"];
    
    _contrastSlider = [self sliderWithValue:1 minimumValue:0.5 maximumValue:1.5 action:@selector(sliderDidChange:)];
    _contrastSlider.superview.center = CGPointMake(self.editor.view.width-20, _brightnessSlider.superview.center.y);
    _contrastSlider.superview.transform = CGAffineTransformMakeRotation(-M_PI * 90 / 180.0f);
    [self setIconForSlider:_contrastSlider withKey:kCLAdjustmentToolContrastIconName defaultIconName:@"contrast.png"];
}

- (void)sliderDidChange:(UISlider*)sender
{
    static BOOL inProgress = NO;
    
    if(inProgress){ return; }
    inProgress = YES;
    
    CGFloat saturation = _saturationSlider.value;
    CGFloat brightness = _brightnessSlider.value;
    CGFloat contrast   = _contrastSlider.value;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *image = [self filteredImage:self->_thumbnailImage saturation:saturation brightness:brightness contrast:contrast];
        [self.editor.imageView performSelectorOnMainThread:@selector(setImage:) withObject:image waitUntilDone:NO];
        inProgress = NO;
    });
}

- (UIImage*)filteredImage:(UIImage*)image saturation:(CGFloat)saturation brightness:(CGFloat)brightness contrast:(CGFloat)contrast
{
    CIImage *ciImage = [[CIImage alloc] initWithImage:image];
    CIFilter *filter = [CIFilter filterWithName:@"CIColorControls" keysAndValues:kCIInputImageKey, ciImage, nil];
    
    [filter setDefaults];
    [filter setValue:[NSNumber numberWithFloat:saturation] forKey:@"inputSaturation"];
    
    filter = [CIFilter filterWithName:@"CIExposureAdjust" keysAndValues:kCIInputImageKey, [filter outputImage], nil];
    [filter setDefaults];
    brightness = 2*brightness;
    [filter setValue:[NSNumber numberWithFloat:brightness] forKey:@"inputEV"];
    
    filter = [CIFilter filterWithName:@"CIGammaAdjust" keysAndValues:kCIInputImageKey, [filter outputImage], nil];
    [filter setDefaults];
    contrast   = contrast * contrast;
    [filter setValue:[NSNumber numberWithFloat:contrast] forKey:@"inputPower"];
    
    CIContext *context = [CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer : @(NO)}];
    CIImage *outputImage = [filter outputImage];
    CGImageRef cgImage = [context createCGImage:outputImage fromRect:[outputImage extent]];
    
    UIImage *result = [UIImage imageWithCGImage:cgImage];
    
    CGImageRelease(cgImage);
    
    return result;
}

@end
