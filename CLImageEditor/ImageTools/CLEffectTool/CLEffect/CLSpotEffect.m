//
//  CLSpotEffect.m
//
//  Created by sho yakushiji on 2013/10/23.
//  Copyright (c) 2013年 CALACULU. All rights reserved.
//

#import "CLSpotEffect.h"

#import "UIView+Frame.h"



@interface CLSpotCircle : UIView
@property (nonatomic, strong) UIColor *color;
@end

@interface CLSpotEffect()
<UIGestureRecognizerDelegate>
@end


@implementation CLSpotEffect
{
    UIView *_containerView;
    CLSpotCircle *_circleView;
    
    CGFloat _X;
    CGFloat _Y;
    CGFloat _R;
}

#pragma mark-

+ (NSString*)defaultTitle
{
    return [CLImageEditorTheme localizedString:@"CLSpotEffect_DefaultTitle" withDefault:@"Spot"];
}

+ (BOOL)isAvailable
{
    return ([UIDevice iosVersion] >= 7.0);
}

- (id)initWithSuperView:(UIView*)superview imageViewFrame:(CGRect)frame toolInfo:(CLImageToolInfo *)info
{
    self = [super initWithSuperView:superview imageViewFrame:frame toolInfo:info];
    if(self){
        _containerView = [[UIView alloc] initWithFrame:frame];
        [superview addSubview:_containerView];
        
        _X = 0.5;
        _Y = 0.5;
        _R = 0.5;
        
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
    CIFilter *filter = [CIFilter filterWithName:@"CIVignetteEffect" keysAndValues:kCIInputImageKey, ciImage, nil];
    
    [filter setDefaults];
    
    CGFloat R = MIN(image.size.width, image.size.height) * image.scale * 0.5 * (_R + 0.1);
    CIVector *vct = [[CIVector alloc] initWithX:image.size.width * image.scale * _X Y:image.size.height * image.scale * (1 - _Y)];
    [filter setValue:vct forKey:@"inputCenter"];
    [filter setValue:[NSNumber numberWithFloat:R] forKey:@"inputRadius"];
    
    CIContext *context = [CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer : @(NO)}];
    CIImage *outputImage = [filter outputImage];
    CGImageRef cgImage = [context createCGImage:outputImage fromRect:[outputImage extent]];
    
    UIImage *result = [UIImage imageWithCGImage:cgImage];
    
    CGImageRelease(cgImage);
    
    return result;
}

#pragma mark- 

- (void)setUserInterface
{
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapContainerView:)];
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panContainerView:)];
    UIPinchGestureRecognizer *pinch    = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchContainerView:)];
    
    pan.maximumNumberOfTouches = 1;
    
    tap.delegate = self;
    //pan.delegate = self;
    pinch.delegate = self;
    
    [_containerView addGestureRecognizer:tap];
    [_containerView addGestureRecognizer:pan];
    [_containerView addGestureRecognizer:pinch];
    
    _circleView = [[CLSpotCircle alloc] init];
    _circleView.backgroundColor = [UIColor clearColor];
    _circleView.color = [UIColor whiteColor];
    [_containerView addSubview:_circleView];
    
    [self drawCircleView];
}

- (void)drawCircleView
{
    CGFloat R = MIN(_containerView.width, _containerView.height) * (_R + 0.1) * 1.2;
    
    _circleView.width  = R;
    _circleView.height = R;
    _circleView.center = CGPointMake(_containerView.width * _X, _containerView.height * _Y);
    
    [_circleView setNeedsDisplay];
}

- (void)tapContainerView:(UITapGestureRecognizer*)sender
{
    CGPoint point = [sender locationInView:_containerView];
    _X = MIN(1.0, MAX(0.0, point.x / _containerView.width));
    _Y = MIN(1.0, MAX(0.0, point.y / _containerView.height));
    
    [self drawCircleView];
    
    if (sender.state == UIGestureRecognizerStateEnded){
        [self.delegate effectParameterDidChange:self];
    }
}

- (void)panContainerView:(UIPanGestureRecognizer*)sender
{
    CGPoint point = [sender locationInView:_containerView];
    _X = MIN(1.0, MAX(0.0, point.x / _containerView.width));
    _Y = MIN(1.0, MAX(0.0, point.y / _containerView.height));
    
    [self drawCircleView];
    
    if (sender.state == UIGestureRecognizerStateEnded){
        [self.delegate effectParameterDidChange:self];
    }
}

- (void)pinchContainerView:(UIPinchGestureRecognizer*)sender
{
    static CGFloat initialScale;
    if (sender.state == UIGestureRecognizerStateBegan) {
        initialScale = (_R + 0.1);
    }
    
    _R = MIN(1.1, MAX(0.1, initialScale * sender.scale)) - 0.1;
    
    [self drawCircleView];
    
    if (sender.state == UIGestureRecognizerStateEnded){
        [self.delegate effectParameterDidChange:self];
    }
}

@end




#pragma mark- UI components

@implementation CLSpotCircle

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [self setNeedsDisplay];
}

- (void)setCenter:(CGPoint)center
{
    [super setCenter:center];
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGRect rct = self.bounds;
    rct.origin.x += 1;
    rct.origin.y += 1;
    rct.size.width -= 2;
    rct.size.height -= 2;
    
    CGContextSetStrokeColorWithColor(context, self.color.CGColor);
    CGContextStrokeEllipseInRect(context, rct);
    
    self.alpha = 1;
    [UIView animateWithDuration:kCLEffectToolAnimationDuration
                          delay:1
                        options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         self.alpha = 0;
                     }
                     completion:^(BOOL finished) {
                         
                     }
     ];
}

@end

