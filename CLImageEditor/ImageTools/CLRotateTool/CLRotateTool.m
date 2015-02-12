//
//  CLRotateTool.m
//
//  Created by sho yakushiji on 2013/11/08.
//  Copyright (c) 2013年 CALACULU. All rights reserved.
//

#import "CLRotateTool.h"

static NSString* const kCLRotateToolRotateIconName = @"rotateIconAssetsName";
static NSString* const kCLRotateToolFlipHorizontalIconName = @"flipHorizontalIconAssetsName";
static NSString* const kCLRotateToolFlipVerticalIconName = @"flipVerticalIconAssetsName";


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
    CGRect _initialRect;
    
    BOOL _executed;
    
    CLRotatePanel *_gridView;
    UIImageView *_rotateImageView;
    
    NSInteger _flipState1;
    NSInteger _flipState2;
}

+ (NSString*)defaultTitle
{
    return [CLImageEditorTheme localizedString:@"CLRotateTool_DefaultTitle" withDefault:@"Rotate"];
}

+ (BOOL)isAvailable
{
    return ([UIDevice iosVersion] >= 5.0);
}

#pragma mark- optional info

+ (NSDictionary*)optionalInfo
{
    return @{
             kCLRotateToolRotateIconName : @"",
             kCLRotateToolFlipHorizontalIconName : @"",
             kCLRotateToolFlipVerticalIconName : @""
             };
}

#pragma mark-

- (void)setup
{
    _executed = NO;
    
    [self.editor fixZoomScaleWithAnimated:YES];
    
    _initialRect = self.editor.imageView.frame;
    
    _flipState1 = 0;
    _flipState2 = 0;
    
    _gridView = [[CLRotatePanel alloc] initWithSuperview:self.editor.imageView.superview frame:self.editor.imageView.frame];
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
                     }
                     completion:^(BOOL finished) {
                         _rotateImageView = [[UIImageView alloc] initWithFrame:_initialRect];
                         _rotateImageView.image = self.editor.imageView.image;
                         [_gridView.superview insertSubview:_rotateImageView belowSubview:_gridView];
                         self.editor.imageView.hidden = YES;
                     }];
}

- (void)cleanup
{
    [_rotateSlider.superview removeFromSuperview];
    [_gridView removeFromSuperview];
    
    if(_executed){
        [self.editor resetZoomScaleWithAnimated:NO];
        [self.editor fixZoomScaleWithAnimated:NO];
        
        _rotateImageView.transform = CGAffineTransformIdentity;
        _rotateImageView.frame = self.editor.imageView.frame;
        _rotateImageView.image = self.editor.imageView.image;
    }
    [self.editor resetZoomScaleWithAnimated:NO];
    
    [UIView animateWithDuration:kCLImageToolAnimationDuration
                     animations:^{
                         _menuScroll.transform = CGAffineTransformMakeTranslation(0, self.editor.view.height-_menuScroll.top);
                         
                         _rotateImageView.transform = CGAffineTransformIdentity;
                         _rotateImageView.frame = self.editor.imageView.frame;
                     }
                     completion:^(BOOL finished) {
                         [_menuScroll removeFromSuperview];
                         [_rotateImageView removeFromSuperview];
                         self.editor.imageView.hidden = NO;
                     }];
}

- (void)executeWithCompletionBlock:(void(^)(UIImage *image, NSError *error, NSDictionary *userInfo))completionBlock
{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIActivityIndicatorView *indicator = [CLImageEditorTheme indicatorView];
        indicator.center = CGPointMake(_gridView.width/2, _gridView.height/2);
        [_gridView addSubview:indicator];
        [indicator startAnimating];
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *image = [self buildImage:self.editor.imageView.image];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            _executed = YES;
            completionBlock(image, nil, nil);
        });
    });
}

#pragma mark-

- (void)setMenu
{
    CGFloat W = 70;
    CGFloat H = _menuScroll.height;
    CGFloat x = 0;
	
    NSArray *_menu = @[
                       @{@"title":[CLImageEditorTheme localizedString:@"CLRotateTool_MenuItemRotateTitle" withDefault:@" "], @"icon":[self imageForKey:kCLRotateToolRotateIconName defaultImageName:@"btn_rotate.png"]},
                       @{@"title":[CLImageEditorTheme localizedString:@"CLRotateTool_MenuItemFlipTitle1" withDefault:@" "], @"icon":[self imageForKey:kCLRotateToolFlipHorizontalIconName defaultImageName:@"btn_flip1.png"]},
                       @{@"title":[CLImageEditorTheme localizedString:@"CLRotateTool_MenuItemFlipTitle2" withDefault:@" "], @"icon":[self imageForKey:kCLRotateToolFlipVerticalIconName defaultImageName:@"btn_flip2.png"]},
                       ];
    
    NSInteger tag = 0;
    for(NSDictionary *obj in _menu){
        CLToolbarMenuItem *view = [CLImageEditorTheme menuItemWithFrame:CGRectMake(x, 0, W, H) target:self action:@selector(tappedMenu:) toolInfo:nil];
        view.tag = tag++;
        view.iconImage = obj[@"icon"];
        view.title = obj[@"title"];
        
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
    CATransform3D transform = [self rotateTransform:CATransform3DIdentity clockwise:YES];
    
    CGFloat arg = _rotateSlider.value*M_PI;
    CGFloat Wnew = fabs(_initialRect.size.width * cos(arg)) + fabs(_initialRect.size.height * sin(arg));
    CGFloat Hnew = fabs(_initialRect.size.width * sin(arg)) + fabs(_initialRect.size.height * cos(arg));
    
    CGFloat Rw = _gridView.width / Wnew;
    CGFloat Rh = _gridView.height / Hnew;
    CGFloat scale = MIN(Rw, Rh) * 0.95;
    
    transform = CATransform3DScale(transform, scale, scale, 1);
    _rotateImageView.layer.transform = transform;
    
    _gridView.gridRect = _rotateImageView.frame;
}

- (UIImage*)buildImage:(UIImage*)image
{
    CIImage *ciImage = [[CIImage alloc] initWithImage:image];
    CIFilter *filter = [CIFilter filterWithName:@"CIAffineTransform" keysAndValues:kCIInputImageKey, ciImage, nil];
    
    //NSLog(@"%@", [filter attributes]);
    
    [filter setDefaults];
    CGAffineTransform transform = CATransform3DGetAffineTransform([self rotateTransform:CATransform3DIdentity clockwise:NO]);
    [filter setValue:[NSValue valueWithBytes:&transform objCType:@encode(CGAffineTransform)] forKey:@"inputTransform"];
    
    
    CIContext *context = [CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer : @(NO)}];
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
