//
//  CLHighlightShadowEffect.m
//
//  Created by sho yakushiji on 2013/10/23.
//  Copyright (c) 2013年 CALACULU. All rights reserved.
//

#import "CLHighlightShadowEffect.h"

#import "UIView+Frame.h"

@implementation CLHighlightShadowEffect
{
    UIView *_containerView;
    
    //UISlider *_highlightSlider;
    UISlider *_shadowSlider;
    //UISlider *_radiusSlider;
}

#pragma mark-

+ (NSString*)defaultTitle
{
    return [CLImageEditorTheme localizedString:@"CLHighlightSadowEffect_DefaultTitle" withDefault:@"Highlight"];
}

+ (BOOL)isAvailable
{
    return ([UIDevice iosVersion] >= 5.0);
}

- (id)initWithSuperView:(UIView*)superview imageViewFrame:(CGRect)frame toolInfo:(CLImageToolInfo *)info
{
    self = [super initWithSuperView:superview imageViewFrame:frame toolInfo:info];
    if(self){
        _containerView = [[UIView alloc] initWithFrame:superview.bounds];
        [superview addSubview:_containerView];
        
        [self setUserInterface];
    }
    return self;
}

- (void)cleanup
{
    [_containerView removeFromSuperview];
}

- (UIImage*)applyEffect:(UIImage*)image
{
    CIImage *ciImage = [[CIImage alloc] initWithImage:image];
    CIFilter *filter = [CIFilter filterWithName:@"CIHighlightShadowAdjust" keysAndValues:kCIInputImageKey, ciImage, nil];
    
    //NSLog(@"%@", [filter attributes]);
    
    [filter setDefaults];
    //[filter setValue:[NSNumber numberWithFloat:_highlightSlider.value] forKey:@"inputHighlightAmount"];
    [filter setValue:[NSNumber numberWithFloat:_shadowSlider.value] forKey:@"inputShadowAmount"];
    //CGFloat R = MAX(image.size.width, image.size.height) * 0.02 * _radiusSlider.value;
    //[filter setValue:[NSNumber numberWithFloat:R] forKey:@"inputRadius"];
    
    CIContext *context = [CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer : @(NO)}];
    CIImage *outputImage = [filter outputImage];
    CGImageRef cgImage = [context createCGImage:outputImage fromRect:[outputImage extent]];
    
    UIImage *result = [UIImage imageWithCGImage:cgImage];
    
    CGImageRelease(cgImage);
    
    return result;
}

#pragma mark-

- (UISlider*)sliderWithValue:(CGFloat)value minimumValue:(CGFloat)min maximumValue:(CGFloat)max
{
    UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(10, 0, 260, 30)];
    
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 280, slider.height)];
    container.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.3];
    container.layer.cornerRadius = slider.height/2;
    
    slider.continuous = YES;
    [slider addTarget:self action:@selector(sliderDidChange:) forControlEvents:UIControlEventValueChanged];
    
    slider.maximumValue = max;
    slider.minimumValue = min;
    slider.value = value;
    
    [container addSubview:slider];
    [_containerView addSubview:container];
    
    return slider;
}

- (void)setUserInterface
{
    _shadowSlider = [self sliderWithValue:0 minimumValue:-1 maximumValue:1];
    _shadowSlider.superview.center = CGPointMake(_containerView.width/2, _containerView.height-30);
    
    //_radiusSlider = [self sliderWithValue:0.5 minimumValue:0 maximumValue:1];
    //_radiusSlider.superview.center = CGPointMake(_containerView.width/2, _containerView.height-30);
    
    //_highlightSlider = [self sliderWithValue:1 minimumValue:0.3 maximumValue:1];
    //_highlightSlider.superview.center = CGPointMake(20, _radiusSlider.superview.top - 150);
    //_highlightSlider.superview.transform = CGAffineTransformMakeRotation(-M_PI * 90 / 180.0f);
    
    //_shadowSlider = [self sliderWithValue:0 minimumValue:-1 maximumValue:1];
    //_shadowSlider.superview.center = CGPointMake(300, _highlightSlider.superview.center.y);
    //_shadowSlider.superview.transform = CGAffineTransformMakeRotation(-M_PI * 90 / 180.0f);
}

- (void)sliderDidChange:(UISlider*)sender
{
    [self.delegate effectParameterDidChange:self];
}

@end
