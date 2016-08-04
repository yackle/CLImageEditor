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
static NSString* const kCLAdjustmentToolSaturationImage = @"saturationIconImage";
static NSString* const kCLAdjustmentToolBrightnessImage = @"brightnessIconImage";
static NSString* const kCLAdjustmentToolContrastImage = @"contrastIconImage";


@implementation CLAdjustmentTool
{
    UIImage *_originalImage;
    UIImage *_thumbnailImage;

    UIScrollView *_menuScroll;

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

    _menuScroll = [[UIScrollView alloc] initWithFrame:self.editor.menuView.frame];
    _menuScroll.backgroundColor = self.editor.menuView.backgroundColor;
    _menuScroll.showsHorizontalScrollIndicator = NO;
    _menuScroll.scrollEnabled = NO;
    [self.editor.view addSubview:_menuScroll];
    [self setMenu];

    _menuScroll.transform = CGAffineTransformMakeTranslation(0, self.editor.view.height-_menuScroll.top);
    [UIView animateWithDuration:kCLImageToolAnimationDuration
                     animations:^{
                         _menuScroll.transform = CGAffineTransformIdentity;
                     }
                     completion:^(BOOL finished) {
                     }];

}

- (void)cleanup
{
    [_indicatorView removeFromSuperview];
    [_saturationSlider.superview removeFromSuperview];
    [_brightnessSlider.superview removeFromSuperview];
    [_contrastSlider.superview removeFromSuperview];
    
    [self.editor resetZoomScaleWithAnimated:YES];
    [UIView animateWithDuration:kCLImageToolAnimationDuration
                     animations:^{
                         _menuScroll.transform = CGAffineTransformMakeTranslation(0, self.editor.view.height-_menuScroll.top);
                     }
                     completion:^(BOOL finished) {
                         [_menuScroll removeFromSuperview];
                     }];
}

- (void)executeWithCompletionBlock:(void(^)(UIImage *image, NSError *error, NSDictionary *userInfo))completionBlock
{
    dispatch_async(dispatch_get_main_queue(), ^{
        _indicatorView = [CLImageEditorTheme indicatorView];
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

- (void)setMenu
{
    CGFloat W = 70;
    CGFloat H = _menuScroll.height;

    NSArray *_menu = @[
                       @{@"title":@"Brightness",
                         @"icon":self.toolInfo.optionalInfo[kCLAdjustmentToolBrightnessImage] ?: [self imageForKey:kCLAdjustmentToolBrightnessIconName defaultImageName:@"brightness.png"]},
                       @{@"title":@"Contrast",
                         @"icon":self.toolInfo.optionalInfo[kCLAdjustmentToolContrastImage] ?: [self imageForKey:kCLAdjustmentToolContrastIconName defaultImageName:@"contrast.png"]},
                       @{@"title":@"Saturation",
                         @"icon":self.toolInfo.optionalInfo[kCLAdjustmentToolSaturationImage] ?: [self imageForKey:kCLAdjustmentToolSaturationIconName defaultImageName:@"saturation.png"]},
                       ];

    NSInteger tag = 0;
    CGFloat padding = (_menuScroll.frame.size.width - _menu.count * W) / (_menu.count + 1);
    CGFloat x = padding;

    for(NSDictionary *obj in _menu){
        CLToolbarMenuItem *view = [CLImageEditorTheme menuItemWithFrame:CGRectMake(x, 0, W, H) target:self action:@selector(tappedMenu:) toolInfo:nil];
        view.tag = tag++;
        view.iconImage = obj[@"icon"];
        view.title = obj[@"title"];

        [_menuScroll addSubview:view];
        x += W+padding;
    }
    _menuScroll.contentSize = CGSizeMake(MAX(x, _menuScroll.frame.size.width+1), 0);
}

- (void)tappedMenu:(UITapGestureRecognizer*)sender
{
    sender.view.alpha = 0.2;
    [UIView animateWithDuration:kCLImageToolAnimationDuration
                     animations:^{
                         sender.view.alpha = 1;
                     }
     ];

    [self displaySlider:sender.view.tag];
}

- (void)displaySlider:(NSInteger)tag
{
    _brightnessSlider.superview.hidden = YES;
    _contrastSlider.superview.hidden = YES;
    _saturationSlider.superview.hidden = YES;

    switch (tag) {
        case 0:
            _brightnessSlider.superview.hidden = NO;
            break;
        case 1:
            _contrastSlider.superview.hidden = NO;
            break;
        case 2:
            _saturationSlider.superview.hidden = NO;
            break;
        default:
            break;
    }
}

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
    _brightnessSlider.superview.center = CGPointMake(self.editor.view.width/2, self.editor.menuView.top-30);
    [self setIconForSlider:_brightnessSlider withKey:kCLAdjustmentToolBrightnessIconName defaultIconName:@"brightness.png"];
    
    _contrastSlider = [self sliderWithValue:1 minimumValue:0.5 maximumValue:1.5 action:@selector(sliderDidChange:)];
    _contrastSlider.superview.center = CGPointMake(self.editor.view.width/2, self.editor.menuView.top-30);
    [self setIconForSlider:_contrastSlider withKey:kCLAdjustmentToolContrastIconName defaultIconName:@"contrast.png"];

    [self displaySlider:0];
}

- (void)sliderDidChange:(UISlider*)sender
{
    static BOOL inProgress = NO;
    
    if(inProgress){ return; }
    inProgress = YES;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *image = [self filteredImage:_thumbnailImage];
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
    
    CIContext *context = [CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer : @(NO)}];
    CIImage *outputImage = [filter outputImage];
    CGImageRef cgImage = [context createCGImage:outputImage fromRect:[outputImage extent]];
    
    UIImage *result = [UIImage imageWithCGImage:cgImage];
    
    CGImageRelease(cgImage);
    
    return result;
}

@end
