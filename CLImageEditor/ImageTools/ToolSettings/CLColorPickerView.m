//
//  CLColorPickerView.m
//
//  Created by sho yakushiji on 2013/12/13.
//  Copyright (c) 2013年 CALACULU. All rights reserved.
//

#import "CLColorPickerView.h"

#import "CLCircleView.h"
#import "UIView+Frame.h"


#pragma mark- Hue circle

@protocol _CLHueCircleViewDelegate;

@interface _CLHueCircleView : UIView
@property (nonatomic, weak) id<_CLHueCircleViewDelegate> delegate;
- (CGFloat)hue;
- (CGFloat)brightness;
- (UIColor*)color;
- (void)setColor:(UIColor*)color;
- (void)setColorWithHue:(CGFloat)hue saturation:(CGFloat)saturation brightness:(CGFloat)brightness alpha:(CGFloat)alpha;
- (void)setColorSaturation:(CGFloat)saturation;
- (void)setColorAlpha:(CGFloat)alpha;
@end

@protocol _CLHueCircleViewDelegate <NSObject>
@optional
- (void)hueCircleViewDidChange:(_CLHueCircleView*)view;

@end



#pragma mark- CLColorPickerView

@interface CLColorPickerView()
<_CLHueCircleViewDelegate>
@end

@implementation CLColorPickerView
{
    _CLHueCircleView *_hueCircle;
    
    UISlider *_saturationSlider;
    UISlider *_alphaSlider;
}

- (id)init
{
    self = [self initWithFrame:CGRectMake(0, 0, 0, 180)];
    if(self){
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self customeInit];
    }
    return self;
}

- (void)awakeFromNib
{
    [self customeInit];
}

- (UISlider*)defaultSliderWithWidth:(CGFloat)width
{
    UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(0, 0, width, 34)];
    slider.value = 1;
    
    slider.maximumTrackTintColor = [UIColor clearColor];
    slider.minimumTrackTintColor = [UIColor clearColor];
    [slider setMaximumTrackImage:[UIImage new] forState:UIControlStateNormal];
    [slider setMinimumTrackImage:[UIImage new] forState:UIControlStateNormal];
    [slider setThumbTintColor:[UIColor whiteColor]];
    slider.transform = CGAffineTransformMakeRotation(-M_PI_2);
    
    return slider;
}

- (void)customeInit
{
    self.backgroundColor = [UIColor clearColor];
    
    CGFloat W = self.height;
    
    _hueCircle = [[_CLHueCircleView alloc] initWithFrame:CGRectMake(0, 0, W, W)];
    _hueCircle.delegate = self;
    [self addSubview:_hueCircle];
    
    _saturationSlider = [self defaultSliderWithWidth:0.9*W];
    _saturationSlider.center = CGPointMake(W + 20, W/2);
    [_saturationSlider addTarget:self action:@selector(saturationSliderDidChange:) forControlEvents:UIControlEventValueChanged];
    _saturationSlider.backgroundColor = [UIColor colorWithPatternImage:[self saturationSliderBackground]];
    [self addSubview:_saturationSlider];
    
    
    _alphaSlider = [self defaultSliderWithWidth:0.9*W];
    _alphaSlider.center = CGPointMake(_saturationSlider.center.x + 40, W/2);
    [_alphaSlider addTarget:self action:@selector(alphaSliderDidChange:) forControlEvents:UIControlEventValueChanged];
    _alphaSlider.backgroundColor = [UIColor colorWithPatternImage:[self alphaSliderBackground]];
    [self addSubview:_alphaSlider];
    
    self.width =  _alphaSlider.center.x + 30;
}

- (void)setColor:(UIColor *)color
{
    CGFloat H, S, B, A;
    
    if([color getHue:&H saturation:&S brightness:&B alpha:&A]){
        _saturationSlider.value = (B==0) ? 1 :S;
        _alphaSlider.value = A;
    }
    else if([color getWhite:&S alpha:&A]){
        _saturationSlider.value = (S==0) ? 1 : 0;
        _alphaSlider.value = A;
    }
    
    _hueCircle.color = color;
}

- (void)setColorWithHue:(CGFloat)hue saturation:(CGFloat)saturation brightness:(CGFloat)brightness alpha:(CGFloat)alpha
{
    _saturationSlider.value = (brightness==0) ? 1 :saturation;
    _alphaSlider.value = alpha;
    
    [_hueCircle setColorWithHue:hue saturation:saturation brightness:brightness alpha:alpha];
}

- (UIColor*)color
{
    return _hueCircle.color;
}

- (CGFloat)hueComponent
{
    return _hueCircle.hue;
}

- (CGFloat)saturationComponent
{
    return _saturationSlider.value;
}

- (CGFloat)brightnessComponent
{
    return _hueCircle.brightness;
}

- (CGFloat)alphaComponent
{
    return _alphaSlider.value;
}

- (void)setSaturationSliderColor
{
    _saturationSlider.backgroundColor = [UIColor colorWithPatternImage:[self saturationSliderBackground]];
}

- (void)setAlphaSliderColor
{
    _alphaSlider.backgroundColor = [UIColor colorWithPatternImage:[self alphaSliderBackground]];
}

- (void)saturationSliderDidChange:(UISlider*)sender
{
    [_hueCircle setColorSaturation:sender.value];
}

- (void)alphaSliderDidChange:(UISlider*)sender
{
    [_hueCircle setColorAlpha:sender.value];
}

- (UIImage*)saturationSliderBackground
{
    CGAffineTransform transform = _saturationSlider.transform;
    _saturationSlider.transform = CGAffineTransformIdentity;
    
    UIGraphicsBeginImageContextWithOptions(_saturationSlider.frame.size, NO, 0.0);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGRect frame = CGRectMake(5, (_saturationSlider.frame.size.height-10)/2, _saturationSlider.frame.size.width-10, 10);
    CGPathRef path = [UIBezierPath bezierPathWithRoundedRect:frame cornerRadius:5].CGPath;
    CGContextAddPath(context, path);
    CGContextClip(context);
    
    UIColor *color = [UIColor colorWithHue:_hueCircle.hue saturation:1 brightness:_hueCircle.brightness alpha:1];
    
    CGFloat r=0, g=0, b=0 , a=0;
    if(![color getRed:&r green:&g blue:&b alpha:&a]){
        if([color getWhite:&r alpha:&a]){
            b = g = r;
        }
    }
    
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGFloat components[] = {
        1.0f, 1.0f, 1.0f, 1.0f,     // R, G, B, A
        r, g, b, 1.0f
    };
    CGFloat locations[] = { 0.0f, 1.0f };
    
    size_t count = sizeof(components)/ (sizeof(CGFloat)* 4);
    
    CGPoint startPoint = CGPointMake(5, 0);
    CGPoint endPoint = CGPointMake(_saturationSlider.frame.size.width-10, 0);

    CGGradientRef gradientRef = CGGradientCreateWithColorComponents(colorSpaceRef, components, locations, count);
    
    CGContextDrawLinearGradient(context, gradientRef, startPoint, endPoint, kCGGradientDrawsAfterEndLocation);
    
    
    
    UIImage *tmp = UIGraphicsGetImageFromCurrentImageContext();
    
    CGGradientRelease(gradientRef);
    CGColorSpaceRelease(colorSpaceRef);
    
    UIGraphicsEndImageContext();
    
    _saturationSlider.transform = transform;
    
    return tmp;
}

- (UIImage*)alphaSliderBackground
{
    CGAffineTransform transform = _alphaSlider.transform;
    _alphaSlider.transform = CGAffineTransformIdentity;
    
    UIGraphicsBeginImageContextWithOptions(_alphaSlider.frame.size, NO, 0.0);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGRect frame = CGRectMake(5, (_alphaSlider.frame.size.height-10)/2, _alphaSlider.frame.size.width-10, 10);
    CGPathRef path = [UIBezierPath bezierPathWithRoundedRect:frame cornerRadius:5].CGPath;
    CGContextAddPath(context, path);
    CGContextClip(context);
    
    CGContextSetFillColorWithColor(context, [[UIColor colorWithWhite:0.9 alpha:1] CGColor]);
    CGContextBeginPath(context);
    for(int i=0; i<_alphaSlider.frame.size.width/5; ++i){
        CGFloat x = i*5;
        CGFloat y = _alphaSlider.frame.size.height/2 - (i%2)*5;
        path = [UIBezierPath bezierPathWithRect:CGRectMake(x, y, 5, 5)].CGPath;
        CGContextAddPath(context, path);
    }
    CGContextFillPath(context);
    
    
    CGFloat r=0, g=0, b=0, a=0;
    if(![_hueCircle.color getRed:&r green:&g blue:&b alpha:&a]){
        if([_hueCircle.color getWhite:&r alpha:&a]){
            b = g = r;
        }
    }
    
    
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGFloat components[] = {
        r, g, b, 0.0f,
        r, g, b, 1.0f
    };
    CGFloat locations[] = { 0.0f, 1.0f };
    
    size_t count = sizeof(components)/ (sizeof(CGFloat)* 4);
    
    CGPoint startPoint = CGPointMake(5, 0);
    CGPoint endPoint = CGPointMake(_alphaSlider.frame.size.width-10, 0);
    
    CGGradientRef gradientRef = CGGradientCreateWithColorComponents(colorSpaceRef, components, locations, count);
    
    CGContextDrawLinearGradient(context, gradientRef, startPoint, endPoint, kCGGradientDrawsAfterEndLocation);
    
    UIImage *tmp = UIGraphicsGetImageFromCurrentImageContext();
    
    CGGradientRelease(gradientRef);
    CGColorSpaceRelease(colorSpaceRef);
    
    UIGraphicsEndImageContext();
    
    _alphaSlider.transform = transform;
    
    return tmp;
}

- (void)hueCircleViewDidChange:(_CLHueCircleView*)view
{
    [self setSaturationSliderColor];
    [self setAlphaSliderColor];
    
    if([self.delegate respondsToSelector:@selector(colorPickerView:colorDidChange:)]){
        [self.delegate colorPickerView:self colorDidChange:view.color];
    }
}

@end





@implementation _CLHueCircleView
{
    CLCircleView *_circleView;
    CGFloat _saturation;
    CGFloat _alpha;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self){
        self.backgroundColor = [UIColor clearColor];
        
        _saturation = 1;
        _alpha = 1;
        
        _circleView = [[CLCircleView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
        _circleView.radius = 0.6;
        _circleView.borderColor = [UIColor colorWithWhite:0.2 alpha:1];
        _circleView.borderWidth = 3;
        _circleView.color = [UIColor blackColor];
        _circleView.center = CGPointMake(frame.size.width/2, frame.size.width/2);
        [self addSubview:_circleView];
        
        [_circleView addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(circleViewDidPan:)]];
        [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewDidTap:)]];
    }
    return self;
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [self setNeedsDisplay];
}

- (CGFloat)hue
{
    CGPoint point = _circleView.center;
    
    point.x -= self.center.x;
    point.y -= self.center.y;
    CGFloat theta = atan2f(point.y, point.x);
    
    return (theta>0)?theta/(2*M_PI):1+theta/(2*M_PI);
}

- (CGFloat)brightness
{
    CGPoint point = _circleView.center;
    CGFloat R = self.circleRadius;
    
    point.x -= self.center.x;
    point.y -= self.center.y;
    
    return MIN(1, sqrtf(point.x*point.x+point.y*point.y)/R);
}

- (UIColor*)color
{
    return _circleView.color;
}

- (void)setColor:(UIColor *)color
{
    CGFloat H, S, B, A;
    
    if([color getHue:&H saturation:&S brightness:&B alpha:&A]){
        [self setColorWithHue:H saturation:S brightness:B alpha:A];
    }
    else if([color getWhite:&S alpha:&A]){
        [self setColorWithHue:0 saturation:S brightness:S alpha:A];
    }
    [self setNeedsDisplay];
}

- (void)setColorWithHue:(CGFloat)hue saturation:(CGFloat)saturation brightness:(CGFloat)brightness alpha:(CGFloat)alpha
{
    _saturation = (brightness==0) ? 1 : saturation;
    _alpha = alpha;
    
    CGFloat theta = hue * 2 * M_PI;
    CGFloat R = self.circleRadius * brightness;
    
    _circleView.center = CGPointMake(R*cosf(theta) + self.center.x, R*sinf(theta) + self.center.y);
    
    [self colorStateDidChange];
}

- (void)setColorSaturation:(CGFloat)saturation
{
    _saturation = saturation;
    [self setNeedsDisplay];
    [self colorStateDidChange];
}

- (void)setColorAlpha:(CGFloat)alpha
{
    _alpha = alpha;
    [self setNeedsDisplay];
    [self colorStateDidChange];
}

- (CGFloat)circleRadius
{
    return 0.80 * MIN(self.frame.size.width, self.frame.size.height)/2;
}

- (void)drawRect:(CGRect)rect
{
    CGFloat R = self.circleRadius;
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 0.1 * R);
    
    CGFloat div = 320.0;
    for(int i=0;i<div;i++){
        CGContextSetStrokeColorWithColor(context, [UIColor colorWithHue:i/div saturation:_saturation brightness:1.0 alpha:1].CGColor);
        CGContextAddArc(context, self.center.x, self.center.y, R, i/div*2*M_PI, (i+1.5)/div*2*M_PI, 0);
        CGContextStrokePath(context);
    }
}

- (void)colorStateDidChange
{
    _circleView.color = [UIColor colorWithHue:self.hue saturation:_saturation brightness:self.brightness alpha:_alpha];
    
    if([self.delegate respondsToSelector:@selector(hueCircleViewDidChange:)]){
        [self.delegate hueCircleViewDidChange:self];
    }
}

- (void)setCircleViewToPoint:(CGPoint)point
{
    CGFloat R = self.circleRadius;
    
    point.x -= self.center.x;
    point.y -= self.center.y;
    CGFloat theta = atan2f(point.y, point.x);
    CGFloat radius= MIN(R, sqrtf(point.x*point.x+point.y*point.y));
    _circleView.center = CGPointMake(radius*cosf(theta) + self.center.x, radius*sinf(theta) + self.center.y);
    
    [self colorStateDidChange];
}

- (void)viewDidTap:(UITapGestureRecognizer*)sender
{
    CGPoint point = [sender locationInView:self];
    [self setCircleViewToPoint:point];
}

- (void)circleViewDidPan:(UIPanGestureRecognizer*)sender
{
    CGPoint point = [sender locationInView:self];
    [self setCircleViewToPoint:point];
}


@end