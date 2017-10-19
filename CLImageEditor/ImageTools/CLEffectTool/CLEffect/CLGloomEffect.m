//
//  CLGloomEffect.m
//
//  Created by sho yakushiji on 2013/10/23.
//  Copyright (c) 2013年 CALACULU. All rights reserved.
//

#import "CLGloomEffect.h"

#import "UIImage+Utility.h"
#import "UIView+Frame.h"

@implementation CLGloomEffect
{
    UIView *_containerView;
    UISlider *_radiusSlider;
    UISlider *_intensitySlider;
}

#pragma mark-

+ (NSString*)defaultTitle
{
    return [CLImageEditorTheme localizedString:@"CLGloomEffect_DefaultTitle" withDefault:@"Gloom"];
}

+ (BOOL)isAvailable
{
    return ([UIDevice iosVersion] >= 6.0);
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
    CIFilter *filter = [CIFilter filterWithName:@"CIGloom" keysAndValues:kCIInputImageKey, ciImage, nil];
    
    //NSLog(@"%@", [filter attributes]);
    
    [filter setDefaults];
    
    CGFloat R = [self getRadius] * MIN(image.size.width, image.size.height) * 0.05;
    [filter setValue:[NSNumber numberWithFloat:R] forKey:@"inputRadius"];
    [filter setValue:[self getIntensityValue] forKey:@"inputIntensity"];
    
    CIContext *context = [CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer : @(NO)}];
    CIImage *outputImage = [filter outputImage];
    CGImageRef cgImage = [context createCGImage:outputImage fromRect:[outputImage extent]];
    
    UIImage *result = [UIImage imageWithCGImage:cgImage];
    
    CGImageRelease(cgImage);
    
    CGFloat dW = (result.size.width - image.size.width)/2;
    CGFloat dH = (result.size.height - image.size.height)/2;
    
    CGRect rct = CGRectMake(dW, dH, image.size.width, image.size.height);
    
    return [result crop:rct];
}

- (CGFloat)getRadius
{
    __block CGFloat value = 0;
    
    safe_dispatch_sync_main(^{
        value = _radiusSlider.value;
    });
    return value;
}

- (NSNumber*)getIntensityValue
{
    __block NSNumber *value = nil;
    
    safe_dispatch_sync_main(^{
        value = [NSNumber numberWithFloat:_intensitySlider.value];
    });
    return value;
}

#pragma mark-

- (UISlider*)sliderWithValue:(CGFloat)value minimumValue:(CGFloat)min maximumValue:(CGFloat)max
{
    UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(10, 0, 260, 30)];
    
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 280, slider.height)];
    container.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.3];
    container.layer.cornerRadius = slider.height/2;
    
    slider.continuous = NO;
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
    _radiusSlider = [self sliderWithValue:0.5 minimumValue:0 maximumValue:1.0];
    _radiusSlider.superview.center = CGPointMake(_containerView.width/2, _containerView.height-30);
    
    _intensitySlider = [self sliderWithValue:1 minimumValue:0 maximumValue:1.0];
    _intensitySlider.superview.center = CGPointMake(_containerView.width-20, _radiusSlider.superview.top - 150);
    _intensitySlider.superview.transform = CGAffineTransformMakeRotation(-M_PI * 90 / 180.0f);
}

- (void)sliderDidChange:(UISlider*)sender
{
    [self.delegate effectParameterDidChange:self];
}

@end
