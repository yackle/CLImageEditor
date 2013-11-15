//
//  CLRotateTool.m
//
//  Created by sho yakushiji on 2013/11/08.
//  Copyright (c) 2013年 CALACULU. All rights reserved.
//

#import "CLRotateTool.h"

#import "UIView+Frame.h"




@interface CLRotatePanel : UIView
@property(nonatomic, strong) UIColor *bgColor;
@property(nonatomic, strong) UIColor *gridColor;
@property(nonatomic, assign) CGRect gridRect;
- (id)initWithSuperview:(UIView*)superview frame:(CGRect)frame;
@end





@implementation CLRotateTool
{
    UISlider *_rotateSlider;
    UIScrollView *_menuScroll;
    CATransform3D _initialTransform;
    CGRect _initialRect;
    
    CLRotatePanel *_gridView;
    
    NSInteger _flipState1;
    NSInteger _flipState2;
}

+ (NSString*)title
{
    return @"Rotate";
}

+ (BOOL)isAvailable
{
    return ([UIDevice iosVersion] >= 5.0);
}

- (void)setup
{
    CGFloat minZoomScale = self.editor.scrollView.minimumZoomScale;
    self.editor.scrollView.maximumZoomScale = 0.95*minZoomScale;
    self.editor.scrollView.minimumZoomScale = 0.95*minZoomScale;
    [self.editor.scrollView setZoomScale:self.editor.scrollView.minimumZoomScale animated:YES];
    
    _initialTransform = self.editor.imageView.layer.transform;
    _initialRect = self.editor.imageView.frame;
    
    _flipState1 = 0;
    _flipState2 = 0;
    
    _gridView = [[CLRotatePanel alloc] initWithSuperview:self.editor.scrollView frame:self.editor.imageView.frame];
    _gridView.backgroundColor = [UIColor clearColor];
    _gridView.bgColor = [self.editor.view.backgroundColor colorWithAlphaComponent:0.8];
    _gridView.gridColor = [[UIColor darkGrayColor] colorWithAlphaComponent:0.8];
    _gridView.clipsToBounds = NO;
    
    _rotateSlider = [self sliderWithValue:0 minimumValue:-1 maximumValue:1];
    _rotateSlider.superview.center = CGPointMake(self.editor.view.width/2, self.editor.menuView.top-30);
    
    _menuScroll = [[UIScrollView alloc] initWithFrame:self.editor.menuView.frame];
    _menuScroll.backgroundColor = self.editor.menuView.backgroundColor;
    _menuScroll.showsHorizontalScrollIndicator = NO;
    [self.editor.view addSubview:_menuScroll];
    [self setMenu];
    
    _menuScroll.transform = CGAffineTransformMakeTranslation(0, self.editor.view.height-_menuScroll.top);
    [UIView animateWithDuration:kCLImageToolAnimationDuration
                     animations:^{
                         _menuScroll.transform = CGAffineTransformIdentity;
                     }];
}

- (void)cleanup
{
    [_rotateSlider.superview removeFromSuperview];
    [_gridView removeFromSuperview];
    
    self.editor.imageView.layer.transform = _initialTransform;
    [self.editor resetZoomScaleWithAnimate:YES];
    
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
        UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 80, 80)];
        indicator.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6];
        indicator.layer.cornerRadius = 5;
        indicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
        indicator.center = CGPointMake(_gridView.width/2, _gridView.height/2);
        [_gridView addSubview:indicator];
        [indicator startAnimating];
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *image = [self buildImage:self.editor.imageView.image];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completionBlock(image, nil, nil);
        });
    });
}

#pragma mark-

- (void)setMenu
{
    CGFloat W = 70;
    CGFloat x = 0;
    
    NSArray *_menu = @[
                       @{@"title":@"", @"icon":[NSString stringWithFormat:@"CLImageEditor.bundle/%@/icon_rotate.png", [self class]]},
                       @{@"title":@"", @"icon":[NSString stringWithFormat:@"CLImageEditor.bundle/%@/icon_flip1.png", [self class]]},
                       @{@"title":@"", @"icon":[NSString stringWithFormat:@"CLImageEditor.bundle/%@/icon_flip2.png", [self class]]},
                       ];
    
    NSInteger tag = 0;
    for(NSDictionary *obj in _menu){
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(x, 0, W, _menuScroll.height)];
        view.tag = tag++;
        
        UIImageView *iconView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 5, 50, 50)];
        iconView.clipsToBounds = YES;
        iconView.image = [UIImage imageNamed:obj[@"icon"]];
        [view addSubview:iconView];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, W-10, W, 15)];
        label.backgroundColor = [UIColor clearColor];
        label.text = obj[@"title"];
        label.font = [UIFont systemFontOfSize:10];
        label.textAlignment = NSTextAlignmentCenter;
        [view addSubview:label];
        
        UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedMenu:)];
        [view addGestureRecognizer:gesture];
        
        [_menuScroll addSubview:view];
        x += W;
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
    
    switch (sender.view.tag) {
        case 0:
        {
            CGFloat value = (int)floorf((_rotateSlider.value + 1)*2) + 1;
            
            if(value>4){ value -= 4; }
            _rotateSlider.value = value / 2 - 1;
            
            _gridView.hidden = YES;
            break;
        }
        case 1:
            _flipState1 = (_flipState1==0) ? 1 : 0;
            break;
        case 2:
            _flipState2 = (_flipState2==0) ? 1 : 0;
            break;
        default:
            break;
    }
    
    [UIView animateWithDuration:kCLImageToolAnimationDuration
                     animations:^{
                         [self rotateStateDidChange];
                     }
                     completion:^(BOOL finished) {
                        _gridView.hidden = NO;
                     }
     ];
}

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
    [self.editor.view addSubview:container];
    
    return slider;
}

- (void)sliderDidChange:(UISlider*)slider
{
    [self rotateStateDidChange];
}

- (CATransform3D)rotateTransform:(CATransform3D)initialTransform clockwise:(BOOL)clockwise
{
    CGFloat arg = _rotateSlider.value*M_PI;
    if(!clockwise){
        arg *= -1;
    }
    
    CATransform3D transform = initialTransform;
    transform = CATransform3DRotate(transform, arg, 0, 0, 1);
    transform = CATransform3DRotate(transform, _flipState1*M_PI, 0, 1, 0);
    transform = CATransform3DRotate(transform, _flipState2*M_PI, 1, 0, 0);
    
    return transform;
}

- (void)rotateStateDidChange
{
    CATransform3D transform = [self rotateTransform:_initialTransform clockwise:YES];
    
    CGFloat arg = _rotateSlider.value*M_PI;
    CGFloat Wnew = fabs(_initialRect.size.width * cos(arg)) + fabs(_initialRect.size.height * sin(arg));
    CGFloat Hnew = fabs(_initialRect.size.width * sin(arg)) + fabs(_initialRect.size.height * cos(arg));
    
    CGFloat Rw = _gridView.width / Wnew;
    CGFloat Rh = _gridView.height / Hnew;
    CGFloat scale = MIN(Rw, Rh) * 0.95;
    
    transform = CATransform3DScale(transform, scale, scale, 1);
    self.editor.imageView.layer.transform = transform;
    
    _gridView.gridRect = self.editor.imageView.frame;
}

- (UIImage*)buildImage:(UIImage*)image
{
    CIImage *ciImage = [[CIImage alloc] initWithImage:image];
    CIFilter *filter = [CIFilter filterWithName:@"CIAffineTransform" keysAndValues:kCIInputImageKey, ciImage, nil];
    
    //NSLog(@"%@", [filter attributes]);
    
    [filter setDefaults];
    CGAffineTransform transform = CATransform3DGetAffineTransform([self rotateTransform:CATransform3DIdentity clockwise:NO]);
    [filter setValue:[NSValue valueWithBytes:&transform objCType:@encode(CGAffineTransform)] forKey:@"inputTransform"];
    
    
    CIContext *context = [CIContext contextWithOptions:nil];
    CIImage *outputImage = [filter outputImage];
    CGImageRef cgImage = [context createCGImage:outputImage fromRect:[outputImage extent]];
    
    UIImage *result = [UIImage imageWithCGImage:cgImage];
    
    CGImageRelease(cgImage);
    
    return result;
}

@end







@implementation CLRotatePanel

- (id)initWithSuperview:(UIView*)superview frame:(CGRect)frame
{
    self = [super initWithFrame:superview.bounds];
    if(self){
        self.gridRect = frame;
        [superview addSubview:self];
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGRect rct = self.gridRect;
    
    CGContextSetStrokeColorWithColor(context, self.gridColor.CGColor);
    CGContextStrokeRect(context, rct);
}

- (void)setGridRect:(CGRect)gridRect
{
    _gridRect = gridRect;
    [self setNeedsDisplay];
}
@end
