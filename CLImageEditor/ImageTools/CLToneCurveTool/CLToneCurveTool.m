//
//  CLToneCurveTool.m
//
//  Created by sho yakushiji on 2013/10/24.
//  Copyright (c) 2013年 CALACULU. All rights reserved.
//

#import "CLToneCurveTool.h"

#import "CLSplineInterpolator.h"

static NSString* const kCLToneCurveToolArrowIconName = @"arrowIconAssetsName";
static NSString* const kCLToneCurveToolResetIconName = @"resetIconAssetsName";


@protocol CLToneCurveGridDelegate;

@interface CLToneCurveView : UIView

@property (nonatomic, weak) id<CLToneCurveGridDelegate> delegate;
@property (nonatomic, strong) UIColor *gridColor;
@property (nonatomic, strong) UIColor *pointColor;
@property (nonatomic, strong) UIColor *lineColor;
@property (nonatomic, assign) BOOL continuous;

@property (nonatomic, readonly) CIVector *point0;
@property (nonatomic, readonly) CIVector *point1;
@property (nonatomic, readonly) CIVector *point2;
@property (nonatomic, readonly) CIVector *point3;
@property (nonatomic, readonly) CIVector *point4;

- (id)initWithSuperview:(UIView*)superview frame:(CGRect)frame;
- (void)resetPoints;

@end

@protocol CLToneCurveGridDelegate <NSObject>
@required
- (void)toneCurveDidChange:(CLToneCurveView*)view;
@end


@interface CLToneCurveTool()
<CLToneCurveGridDelegate>
@end

@implementation CLToneCurveTool
{
    UIImage *_originalImage;
    UIImage *_thumbnailImage;
    
    UIView *_menuContainer;
    CLToneCurveView *_tonecurveView;
    UIActivityIndicatorView *_indicatorView;
}

#pragma mark-

+ (NSString*)defaultTitle
{
    return [CLImageEditorTheme localizedString:@"CLToneCurveTool_DefaultTitle" withDefault:@"ToneCurve"];
}

+ (BOOL)isAvailable
{
    return ([UIDevice iosVersion] >= 5.0);
}

#pragma mark- optional info

+ (NSDictionary*)optionalInfo
{
    return @{
             kCLToneCurveToolArrowIconName : @"",
             kCLToneCurveToolResetIconName : @"",
             };
}

#pragma mark-

- (void)setup
{
    _originalImage = self.editor.imageView.image;
    _thumbnailImage = [_originalImage resize:self.editor.imageView.frame.size];
    
    self.editor.imageView.image = _thumbnailImage;
    
    _menuContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.editor.view.width, 280)];
    _menuContainer.backgroundColor = [UIColor colorWithWhite:1 alpha:0.6];
    [self.editor.view addSubview:_menuContainer];
    
    // Adjust for iPhone X
    if (@available(iOS 11.0, *)) {
        UIEdgeInsets theInsets = [UIApplication sharedApplication].keyWindow.rootViewController.view.safeAreaInsets;
        _menuContainer.height += theInsets.bottom;
    }
    _menuContainer.bottom = self.editor.view.height;
    
    _tonecurveView = [[CLToneCurveView alloc] initWithSuperview:_menuContainer frame:CGRectMake(10, 20, _menuContainer.width-80, 240)];
    _tonecurveView.delegate = self;
    _tonecurveView.backgroundColor = [UIColor clearColor];
    _tonecurveView.gridColor  = [UIColor colorWithWhite:0 alpha:0.2];
    _tonecurveView.pointColor = [UIColor colorWithWhite:0.5 alpha:1];
    _tonecurveView.lineColor  = [UIColor colorWithWhite:0.5 alpha:1];
    _tonecurveView.continuous = NO;
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(_tonecurveView.right + 20, 15, 30, 30);
    [btn addTarget:self action:@selector(pushedHideBtn:) forControlEvents:UIControlEventTouchUpInside];
	
    [btn setImage:[self imageForKey:kCLToneCurveToolArrowIconName defaultImageName:@"btn_arrow.png"] forState:UIControlStateNormal];
    [_menuContainer addSubview:btn];
    
    btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(_tonecurveView.right + 20, _tonecurveView.bottom - 30, 30, 30);
    [btn addTarget:self action:@selector(pushedResetBtn:) forControlEvents:UIControlEventTouchUpInside];
	
    [btn setImage:[self imageForKey:kCLToneCurveToolResetIconName defaultImageName:@"btn_reset.png"] forState:UIControlStateNormal];
    [_menuContainer addSubview:btn];
    
    _menuContainer.transform = CGAffineTransformMakeTranslation(0, self.editor.view.height-_menuContainer.top);
    [UIView animateWithDuration:kCLImageToolAnimationDuration
                     animations:^{
                         self->_menuContainer.transform = CGAffineTransformIdentity;
                     }];
}

- (void)cleanup
{
    [_indicatorView removeFromSuperview];
    
    [UIView animateWithDuration:kCLImageToolAnimationDuration
                     animations:^{
                         self->_menuContainer.transform = CGAffineTransformTranslate(self->_menuContainer.transform, 0, self.editor.view.height-self->_menuContainer.top);
                     }
                     completion:^(BOOL finished) {
                         [self->_menuContainer removeFromSuperview];
                     }];
}

- (void)executeWithCompletionBlock:(void(^)(UIImage *image, NSError *error, NSDictionary *userInfo))completionBlock
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self->_indicatorView = [CLImageEditorTheme indicatorView];
        self->_indicatorView.center = self.editor.view.center;
        [self.editor.view addSubview:self->_indicatorView];
        [self->_indicatorView startAnimating];
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *image = [self filteredImage:self->_originalImage];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completionBlock(image, nil, nil);
        });
    });
}

#pragma mark-

- (void)toneCurveDidChange:(CLToneCurveView *)view
{
    static BOOL inProgress = NO;
    
    if(inProgress){ return; }
    inProgress = YES;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *image = [self filteredImage:self->_thumbnailImage];
        [self.editor.imageView performSelectorOnMainThread:@selector(setImage:) withObject:image waitUntilDone:NO];
        inProgress = NO;
    });
}

- (UIImage*)filteredImage:(UIImage*)image
{
    CIImage *ciImage = [[CIImage alloc] initWithImage:image];
    CIFilter *filter = [CIFilter filterWithName:@"CIToneCurve" keysAndValues:kCIInputImageKey, ciImage, nil];
    
    //NSLog(@"%@", [filter attributes]);
    
    [filter setDefaults];
    [filter setValue:_tonecurveView.point0 forKey:@"inputPoint0"];
    [filter setValue:_tonecurveView.point1 forKey:@"inputPoint1"];
    [filter setValue:_tonecurveView.point2 forKey:@"inputPoint2"];
    [filter setValue:_tonecurveView.point3 forKey:@"inputPoint3"];
    [filter setValue:_tonecurveView.point4 forKey:@"inputPoint4"];
    
    CIContext *context = [CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer : @(NO)}];
    CIImage *outputImage = [filter outputImage];
    CGImageRef cgImage = [context createCGImage:outputImage fromRect:[outputImage extent]];
    
    UIImage *result = [UIImage imageWithCGImage:cgImage];
    
    CGImageRelease(cgImage);
    
    return result;
}

- (void)pushedHideBtn:(UIButton*)sender
{
    [UIView animateWithDuration:kCLImageToolAnimationDuration
                     animations:^{
                         if(CGAffineTransformIsIdentity(self->_menuContainer.transform)){
                             self->_menuContainer.transform = CGAffineTransformMakeTranslation(0, self.editor.view.height-self->_menuContainer.top-self.editor.menuView.height);
                             sender.transform = CGAffineTransformMakeRotation(M_PI);
                             self->_tonecurveView.userInteractionEnabled = NO;
                         }
                         else{
                             self->_menuContainer.transform = CGAffineTransformIdentity;
                             sender.transform = CGAffineTransformIdentity;
                             self->_tonecurveView.userInteractionEnabled = YES;
                         }
                     }
     ];
}

- (void)pushedResetBtn:(UIButton*)sender
{
    [_tonecurveView resetPoints];
    
    CABasicAnimation* rotation;
    rotation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotation.toValue  = [NSNumber numberWithFloat:-M_PI*2.0];
    rotation.duration = kCLImageToolAnimationDuration;
    rotation.cumulative = YES;
    rotation.repeatCount = 1;
    rotation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    [sender.layer addAnimation:rotation forKey:@"rotationAnimation"];
}

@end



#pragma mark- UI components


@interface CLControlPoint : UIView

@property (nonatomic, strong) CIVector *controlPoint;
@property (nonatomic, strong) UIColor *bgColor;
@property (nonatomic, assign) CGRect layoutFrame;

@end

@implementation CLControlPoint

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGRect rct = self.bounds;
    rct.origin.x = rct.size.width/2-rct.size.width/6;
    rct.origin.y = rct.size.height/2-rct.size.height/6;
    rct.size.width /= 3;
    rct.size.height /= 3;
    
    CGContextSetFillColorWithColor(context, self.bgColor.CGColor);
    CGContextFillEllipseInRect(context, rct);
}

- (void)setControlPoint:(CIVector *)controlPoint
{
    if(controlPoint != _controlPoint){
        _controlPoint = controlPoint;
        self.center = CGPointMake(_controlPoint.X * self.layoutFrame.size.width + self.layoutFrame.origin.x, (1 - _controlPoint.Y) * self.layoutFrame.size.height + self.layoutFrame.origin.y);
    }
}

- (void)setBgColor:(UIColor *)bgColor
{
    _bgColor = bgColor;
    [self setNeedsDisplay];
}

@end



@implementation CLToneCurveView
{
    NSArray *_controlPoints;
}

- (CLControlPoint*)controlPoint
{
    CLControlPoint *view = [[CLControlPoint alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    view.backgroundColor = [UIColor clearColor];
    view.layoutFrame = self.frame;
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panControlPoint:)];
    pan.maximumNumberOfTouches = 1;
    [view addGestureRecognizer:pan];
    
    [self.superview addSubview:view];
    
    return view;
}

- (id)initWithSuperview:(UIView *)superview frame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self){
        [superview addSubview:self];
        
        NSMutableArray *tmp = [NSMutableArray array];
        for(NSInteger i=0; i<5; ++i){
            [tmp addObject:[self controlPoint]];
        }
        _controlPoints = [tmp copy];
        
        [self resetPoints];
    }
    return self;
}

- (void)resetPoints
{
    for(NSInteger i=0; i<_controlPoints.count; ++i){
        CGFloat x = i/(CGFloat)(_controlPoints.count-1);
        CLControlPoint *point = _controlPoints[i];
        point.controlPoint = [CIVector vectorWithCGPoint:CGPointMake(x, x)];
    }
    
    [self setNeedsDisplay];
    [self.delegate toneCurveDidChange:self];
}

- (void)setPointColor:(UIColor *)pointColor
{
    for(CLControlPoint *view in _controlPoints){
        view.bgColor = pointColor;
    }
}

- (void)setUserInteractionEnabled:(BOOL)userInteractionEnabled
{
    [super setUserInteractionEnabled:userInteractionEnabled];
    for(CLControlPoint *view in _controlPoints){
        view.userInteractionEnabled = userInteractionEnabled;
    }
}

- (CIVector*)point0
{
    return [_controlPoints[0] controlPoint];
}

- (CIVector*)point1
{
    return [_controlPoints[1] controlPoint];
}

- (CIVector*)point2
{
    return [_controlPoints[2] controlPoint];
}

- (CIVector*)point3
{
    return [_controlPoints[3] controlPoint];
}

- (CIVector*)point4
{
    return [_controlPoints[4] controlPoint];
}

- (void)setControlPoint:(CGPoint)point atIndex:(NSInteger)index
{
    if(index>=0 && index < _controlPoints.count){
        CLControlPoint *prev = (index==0) ? nil : _controlPoints[index-1];
        CLControlPoint *target = _controlPoints[index];
        CLControlPoint *next = (index+1<_controlPoints.count) ? _controlPoints[index+1] : nil;
        
        CGFloat left_limit  = (prev==nil) ? 0 : prev.controlPoint.X + 0.05;
        CGFloat right_limit = (next==nil) ? 1 : next.controlPoint.X - 0.05;
        
        point.x = MAX(left_limit, MIN(point.x, right_limit));
        point.y = MAX(0, MIN(1 - point.y, 1));
        
        target.controlPoint = [CIVector vectorWithCGPoint:point];
    }
}

- (CGPoint)convertControlPointToViewPoint:(CIVector*)controlPoint
{
    CGFloat X = MAX(0, MIN(controlPoint.X, 1));
    CGFloat Y = MAX(0, MIN(controlPoint.Y, 1));
    return CGPointMake(X * self.frame.size.width, (1 - Y) * self.frame.size.height);
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGRect rct = self.bounds;
    rct.origin.x += 1;
    rct.origin.y += 1;
    rct.size.width  -= 2;
    rct.size.height -= 2;
    
    // Draw grid
    
    CGContextSetStrokeColorWithColor(context, self.gridColor.CGColor);
    CGContextSetLineWidth(context, 1);
    
    CGContextBeginPath(context);
    CGFloat dW = 0;
    for(int i=0;i<5;++i){
        CGContextMoveToPoint(context, rct.origin.x+dW, rct.origin.y);
        CGContextAddLineToPoint(context, rct.origin.x+dW, rct.origin.y+rct.size.height);
        dW += rct.size.width/4;
    }
    
    dW = 0;
    for(int i=0;i<5;++i){
        CGContextMoveToPoint(context, rct.origin.x, rct.origin.y+dW);
        CGContextAddLineToPoint(context, rct.origin.x+rct.size.width, rct.origin.y+dW);
        dW += rct.size.height/4;
    }
    CGContextStrokePath(context);
    
    // Draw spline curve: It would be different from the actual curve.
    
    NSMutableArray *points = [NSMutableArray array];
    for(CLControlPoint *view in _controlPoints){ [points addObject:view.controlPoint]; }
    
    CLSplineInterpolator *spline = [[CLSplineInterpolator alloc] initWithPoints:points];
    
    UIBezierPath *curve = [UIBezierPath bezierPath];
    CGContextSetStrokeColorWithColor(context, self.lineColor.CGColor);
    [curve setLineWidth:1.0];
    
    const NSInteger L = 100;
    
    [curve moveToPoint:[self convertControlPointToViewPoint:[CIVector vectorWithCGPoint:CGPointMake(0, self.point0.Y)]]];
    for(NSInteger i=0; i<L; ++i){
        double t = i / (double)(L-1);
        CIVector *point = [spline interpolatedPoint:t];
        [curve addLineToPoint:[self convertControlPointToViewPoint:point]];
    }
    [curve addLineToPoint:[self convertControlPointToViewPoint:[CIVector vectorWithCGPoint:CGPointMake(1, self.point4.Y)]]];
    [curve stroke];
}

- (void)panControlPoint:(UIPanGestureRecognizer*)sender
{
    static CGPoint initialPoint;
    if(sender.state == UIGestureRecognizerStateBegan){
        initialPoint = [sender locationInView:self];
    }
    
    CGPoint point = [sender translationInView:self];
    NSInteger index = [_controlPoints indexOfObject:sender.view];
    
    point.x = (initialPoint.x + point.x) / self.width;
    point.y = (initialPoint.y + point.y) / self.height;
    
    [self setControlPoint:point atIndex:index];
    
    [self setNeedsDisplay];
    if(self.continuous ||  sender.state == UIGestureRecognizerStateEnded){
        [self.delegate toneCurveDidChange:self];
    }
}

@end

