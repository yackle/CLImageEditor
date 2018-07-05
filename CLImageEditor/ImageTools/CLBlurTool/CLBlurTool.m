//
//  CLBlurTool.m
//
//  Created by sho yakushiji on 2013/10/19.
//  Copyright (c) 2013年 CALACULU. All rights reserved.
//

#import "CLBlurTool.h"

static NSString* const kCLBlurToolNormalIconName = @"normalIconAssetsName";
static NSString* const kCLBlurToolCircleIconName = @"circleIconAssetsName";
static NSString* const kCLBlurToolBandIconName = @"bandIconAssetsName";

typedef NS_ENUM(NSUInteger, CLBlurType)
{
    kCLBlurTypeNormal = 0,
    kCLBlurTypeCircle,
    kCLBlurTypeBand,
};


@interface CLBlurCircle : UIView
@property (nonatomic, strong) UIColor *color;
@end

@interface CLBlurBand : UIView
@property (nonatomic, strong) UIColor *color;
@property (nonatomic, assign) CGFloat rotation;
@property (nonatomic, assign) CGFloat scale;
@property (nonatomic, assign) CGFloat offset;
@end



@interface CLBlurTool()
<UIGestureRecognizerDelegate>
@property (nonatomic, strong) UIView *selectedMenu;
@end

@implementation CLBlurTool
{
    UIImage *_originalImage;
    UIImage *_thumbnailImage;
    UIImage *_blurImage;
    
    UISlider *_blurSlider;
    UIScrollView *_menuScroll;
    
    UIView *_handlerView;
    
    CLBlurCircle *_circleView;
    CLBlurBand *_bandView;
    CGRect _bandImageRect;
    
    CLBlurType _blurType;
}

#pragma mark-

+ (NSString*)defaultTitle
{
    return [CLImageEditorTheme localizedString:@"CLBlurEffect_DefaultTitle" withDefault:@"Blur & Focus"];
}

+ (BOOL)isAvailable
{
    return ([UIDevice iosVersion] >= 5.0);
}

#pragma mark- optional info

+ (NSDictionary*)optionalInfo
{
    return @{
             kCLBlurToolNormalIconName : @"",
             kCLBlurToolCircleIconName : @"",
             kCLBlurToolBandIconName : @""
             };
}

#pragma mark-

- (void)setup
{
    _blurType = kCLBlurTypeNormal;
    _originalImage = self.editor.imageView.image;
    _thumbnailImage = [_originalImage resize:self.editor.imageView.frame.size];
    
    [self.editor fixZoomScaleWithAnimated:YES];
    
    _blurSlider = [self sliderWithValue:0.2 minimumValue:0 maximumValue:1];
    _blurSlider.superview.center = CGPointMake(self.editor.view.width/2, self.editor.menuView.top-30);
    
    _handlerView = [[UIView alloc] initWithFrame:self.editor.imageView.frame];
    [self.editor.imageView.superview addSubview:_handlerView];
    [self setHandlerView];
    
    _menuScroll = [[UIScrollView alloc] initWithFrame:self.editor.menuView.frame];
    _menuScroll.backgroundColor = self.editor.menuView.backgroundColor;
    _menuScroll.showsHorizontalScrollIndicator = NO;
    [self.editor.view addSubview:_menuScroll];
    [self setBlurMenu];
    
    _menuScroll.transform = CGAffineTransformMakeTranslation(0, self.editor.view.height-_menuScroll.top);
    [UIView animateWithDuration:kCLImageToolAnimationDuration
                     animations:^{
                         self->_menuScroll.transform = CGAffineTransformIdentity;
                     }];
    
    [self setDefaultParams];
    [self sliderDidChange:nil];
}

- (void)cleanup
{
    [self.editor resetZoomScaleWithAnimated:YES];
    [_blurSlider.superview removeFromSuperview];
    [_handlerView removeFromSuperview];
    
    [UIView animateWithDuration:kCLImageToolAnimationDuration
                     animations:^{
                         self->_menuScroll.transform = CGAffineTransformMakeTranslation(0, self.editor.view.height-self->_menuScroll.top);
                     }
                     completion:^(BOOL finished) {
                         [self->_menuScroll removeFromSuperview];
                     }];
}

- (void)executeWithCompletionBlock:(void(^)(UIImage *image, NSError *error, NSDictionary *userInfo))completionBlock
{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIActivityIndicatorView *indicator = [CLImageEditorTheme indicatorView];
        indicator.center = CGPointMake(self->_handlerView.width/2, self->_handlerView.height/2);
        [self->_handlerView addSubview:indicator];
        [indicator startAnimating];
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *blurImage = [self->_originalImage gaussBlur:[self getBlurValue]];
        UIImage *image = [self buildResultImage:self->_originalImage withBlurImage:blurImage];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completionBlock(image, nil, nil);
        });
    });
}

- (CGFloat)getBlurValue
{
    __block CGFloat value = 0;
    
    safe_dispatch_sync_main(^{
        value = self->_blurSlider.value;
    });
    return value;
}

#pragma mark- 

- (void)setBlurMenu
{
    CGFloat W = 70;
    CGFloat H = _menuScroll.height;
    CGFloat x = 0;
    
    NSArray *_menu = @[
                       @{@"title":[CLImageEditorTheme localizedString:@"CLBlurEffect_MenuItemNormal" withDefault:@"Normal"], @"icon":[self imageForKey:kCLBlurToolNormalIconName defaultImageName:@"btn_normal.png"]},
                       @{@"title":[CLImageEditorTheme localizedString:@"CLBlurEffect_MenuItemCircle" withDefault:@"Circle"], @"icon":[self imageForKey:kCLBlurToolCircleIconName defaultImageName:@"btn_circle.png"]},
                       @{@"title":[CLImageEditorTheme localizedString:@"CLBlurEffect_MenuItemBand" withDefault:@"Band"], @"icon":[self imageForKey:kCLBlurToolBandIconName defaultImageName:@"btn_band.png"]},
    ];
    
    NSInteger tag = 0;
    for(NSDictionary *obj in _menu){
        CLToolbarMenuItem *view = [CLImageEditorTheme menuItemWithFrame:CGRectMake(x, 0, W, H) target:self action:@selector(tappedBlurMenu:) toolInfo:nil];
        view.tag = tag++;
        view.title = obj[@"title"];
        view.iconImage = obj[@"icon"];
        
        if(self.selectedMenu==nil){
            self.selectedMenu = view;
        }
        
        [_menuScroll addSubview:view];
        x += W;
    }
    _menuScroll.contentSize = CGSizeMake(MAX(x, _menuScroll.frame.size.width+1), 0);
}

- (void)setSelectedMenu:(UIView *)selectedMenu
{
    if(selectedMenu != _selectedMenu){
        _selectedMenu.backgroundColor = [UIColor clearColor];
        _selectedMenu = selectedMenu;
        _selectedMenu.backgroundColor = [CLImageEditorTheme toolbarSelectedButtonColor];
    }
}

- (void)setHandlerView
{
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapHandlerView:)];
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panHandlerView:)];
    UIPinchGestureRecognizer *pinch    = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchHandlerView:)];
    UIRotationGestureRecognizer *rot   = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(rotateHandlerView:)];
    
    panGesture.maximumNumberOfTouches = 1;
    
    tapGesture.delegate = self;
    //panGesture.delegate = self;
    pinch.delegate = self;
    rot.delegate = self;
    
    [_handlerView addGestureRecognizer:tapGesture];
    [_handlerView addGestureRecognizer:panGesture];
    [_handlerView addGestureRecognizer:pinch];
    [_handlerView addGestureRecognizer:rot];
}

- (void)setDefaultParams
{
    CGFloat W = 1.5*MIN(_handlerView.width, _handlerView.height);
    
    _circleView = [[CLBlurCircle alloc] initWithFrame:CGRectMake(_handlerView.width/2-W/2, _handlerView.height/2-W/2, W, W)];
    _circleView.backgroundColor = [UIColor clearColor];
    _circleView.color = [UIColor whiteColor];
    
    CGFloat H = _handlerView.height;
    CGFloat R = sqrt((_handlerView.width*_handlerView.width) + (_handlerView.height*_handlerView.height));
    
    _bandView = [[CLBlurBand alloc] initWithFrame:CGRectMake(0, 0, R, H)];
    _bandView.center = CGPointMake(_handlerView.width/2, _handlerView.height/2);
    _bandView.backgroundColor = [UIColor clearColor];
    _bandView.color = [UIColor whiteColor];
    
    CGFloat ratio = _originalImage.size.width / self.editor.imageView.width;
    _bandImageRect = _bandView.frame;
    _bandImageRect.size.width  *= ratio;
    _bandImageRect.size.height *= ratio;
    _bandImageRect.origin.x *= ratio;
    _bandImageRect.origin.y *= ratio;
    
}

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
    [self.editor.view addSubview:container];
    
    return slider;
}

- (void)sliderDidChange:(UISlider*)slider
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        self->_blurImage = [self->_thumbnailImage gaussBlur:[self getBlurValue]];
        [self buildThumbnailImage];
    });
}

- (void)buildThumbnailImage
{
    static BOOL inProgress = NO;
    
    if(inProgress){ return; }
    
    inProgress = YES;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *image = [self buildResultImage:self->_thumbnailImage withBlurImage:self->_blurImage];
        
        [self.editor.imageView performSelectorOnMainThread:@selector(setImage:) withObject:image waitUntilDone:NO];
        inProgress = NO;
    });
}

- (UIImage*)buildResultImage:(UIImage*)image withBlurImage:(UIImage*)blurImage
{
    UIImage *result = blurImage;
    
    switch (_blurType) {
        case kCLBlurTypeCircle:
            result = [self circleBlurImage:image withBlurImage:blurImage];
            break;
        case kCLBlurTypeBand:
            result = [self bandBlurImage:image withBlurImage:blurImage];
            break;
        default:
            break;
    }
    return result;
}

- (UIImage*)blurImage:(UIImage*)image withBlurImage:(UIImage*)blurImage andMask:(UIImage*)maskImage
{
    UIImage *tmp = [image maskedImage:maskImage];
    
    UIGraphicsBeginImageContext(blurImage.size);
    {
        [blurImage drawAtPoint:CGPointZero];
        [tmp drawInRect:CGRectMake(0, 0, blurImage.size.width, blurImage.size.height)];
        tmp = UIGraphicsGetImageFromCurrentImageContext();
    }
    UIGraphicsEndImageContext();
    
    return tmp;
}

- (UIImage*)circleBlurImage:(UIImage*)image withBlurImage:(UIImage*)blurImage
{
    __block CGFloat ratio = 1;
    __block CGRect frame = CGRectZero;
    
    safe_dispatch_sync_main(^{
        ratio = image.size.width / self.editor.imageView.width;
        frame  = self->_circleView.frame;
    });
    
    frame.size.width  *= ratio;
    frame.size.height *= ratio;
    frame.origin.x *= ratio;
    frame.origin.y *= ratio;
    
    UIImage *mask = [CLImageEditorTheme imageNamed:[self class] image:@"circle.png"];
    UIGraphicsBeginImageContext(image.size);
    {
        CGContextSetFillColorWithColor(UIGraphicsGetCurrentContext() , [[UIColor whiteColor] CGColor]);
        CGContextFillRect(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, image.size.width, image.size.height));
        [mask drawInRect:frame];
        mask = UIGraphicsGetImageFromCurrentImageContext();
    }
    UIGraphicsEndImageContext();
    
    return [self blurImage:image withBlurImage:blurImage andMask:mask];
}

- (UIImage*)bandBlurImage:(UIImage*)image withBlurImage:(UIImage*)blurImage
{
    __block CGFloat offset = 0;
    
    safe_dispatch_sync_main(^{
        offset = self->_bandView.offset*image.size.width/self->_handlerView.width;
    });
    
    UIImage *mask = [CLImageEditorTheme imageNamed:[self class] image:@"band.png"];
    
    UIGraphicsBeginImageContext(image.size);
    {
        CGContextRef context =  UIGraphicsGetCurrentContext();
        
        CGContextSetFillColorWithColor(context, [[UIColor whiteColor] CGColor]);
        CGContextFillRect(context, CGRectMake(0, 0, image.size.width, image.size.height));
        
        CGContextSaveGState(context);
        CGFloat ratio = image.size.width / _originalImage.size.width;
        CGFloat Tx = (_bandImageRect.size.width/2  + _bandImageRect.origin.x)*ratio;
        CGFloat Ty = (_bandImageRect.size.height/2 + _bandImageRect.origin.y)*ratio;
        
        CGContextTranslateCTM(context, Tx, Ty);
        CGContextRotateCTM(context, _bandView.rotation);
        CGContextTranslateCTM(context, 0, offset);
        CGContextScaleCTM(context, 1, _bandView.scale);
        CGContextTranslateCTM(context, -Tx, -Ty);
        
        CGRect rct = _bandImageRect;
        rct.size.width  *= ratio;
        rct.size.height *= ratio;
        rct.origin.x    *= ratio;
        rct.origin.y    *= ratio;
        
        [mask drawInRect:rct];
        
        CGContextRestoreGState(context);
        
        mask = UIGraphicsGetImageFromCurrentImageContext();
    }
    UIGraphicsEndImageContext();
    
    return [self blurImage:image withBlurImage:blurImage andMask:mask];
}

#pragma mark- Gesture handler

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (void)tappedBlurMenu:(UITapGestureRecognizer*)sender
{
    UIView *view = sender.view;
    
    self.selectedMenu = view;
    
    view.alpha = 0.2;
    [UIView animateWithDuration:kCLImageToolAnimationDuration
                     animations:^{
                         view.alpha = 1;
                     }
     ];
    
    if(view.tag != _blurType){
        _blurType = view.tag;
        
        [_circleView removeFromSuperview];
        [_bandView removeFromSuperview];
        
        switch (_blurType) {
            case kCLBlurTypeNormal:
                break;
            case kCLBlurTypeCircle:
                [_handlerView addSubview:_circleView];
                [_circleView setNeedsDisplay];
                break;
            case kCLBlurTypeBand:
                [_handlerView addSubview:_bandView];
                [_bandView setNeedsDisplay];
                break;
            default:
                break;
        }
        [self buildThumbnailImage];
    }
}

- (void)tapHandlerView:(UITapGestureRecognizer*)sender
{
    switch (_blurType) {
        case kCLBlurTypeCircle:
        {
            CGPoint point = [sender locationInView:_handlerView];
            _circleView.center = point;
            [self buildThumbnailImage];
            break;
        }
        case kCLBlurTypeBand:
        {
            CGPoint point = [sender locationInView:_handlerView];
            point = CGPointMake(point.x-_handlerView.width/2, point.y-_handlerView.height/2);
            point = CGPointMake(point.x*cos(-_bandView.rotation)-point.y*sin(-_bandView.rotation), point.x*sin(-_bandView.rotation)+point.y*cos(-_bandView.rotation));
            _bandView.offset = point.y;
            [self buildThumbnailImage];
            break;
        }
        default:
            break;
    }
}

- (void)panHandlerView:(UIPanGestureRecognizer*)sender
{
    switch (_blurType) {
        case kCLBlurTypeCircle:
        {
            CGPoint point = [sender locationInView:_handlerView];
            _circleView.center = point;
            [self buildThumbnailImage];
            break;
        }
        case kCLBlurTypeBand:
        {
            CGPoint point = [sender locationInView:_handlerView];
            point = CGPointMake(point.x-_handlerView.width/2, point.y-_handlerView.height/2);
            point = CGPointMake(point.x*cos(-_bandView.rotation)-point.y*sin(-_bandView.rotation), point.x*sin(-_bandView.rotation)+point.y*cos(-_bandView.rotation));
            _bandView.offset = point.y;
            [self buildThumbnailImage];
            break;
        }
        default:
            break;
    }
}

- (void)pinchHandlerView:(UIPinchGestureRecognizer*)sender
{
    switch (_blurType) {
        case kCLBlurTypeCircle:
        {
            static CGRect initialFrame;
            if (sender.state == UIGestureRecognizerStateBegan) {
                initialFrame = _circleView.frame;
            }
            
            CGFloat scale = sender.scale;
            CGRect rct;
            rct.size.width  = MAX(MIN(initialFrame.size.width*scale, 3*MAX(_handlerView.width, _handlerView.height)), 0.3*MIN(_handlerView.width, _handlerView.height));
            rct.size.height = rct.size.width;
            rct.origin.x = initialFrame.origin.x + (initialFrame.size.width-rct.size.width)/2;
            rct.origin.y = initialFrame.origin.y + (initialFrame.size.height-rct.size.height)/2;
            
            _circleView.frame = rct;
            [self buildThumbnailImage];
            break;
        }
        case kCLBlurTypeBand:
        {
            static CGFloat initialScale;
            if (sender.state == UIGestureRecognizerStateBegan) {
                initialScale = _bandView.scale;
            }
            
            _bandView.scale = MIN(2, MAX(0.2, initialScale * sender.scale));
            [self buildThumbnailImage];
            break;
        }
        default:
            break;
    }
}

- (void)rotateHandlerView:(UIRotationGestureRecognizer*)sender
{
    switch (_blurType) {
        case kCLBlurTypeBand:
        {
            static CGFloat initialRotation;
            if (sender.state == UIGestureRecognizerStateBegan) {
                initialRotation = _bandView.rotation;
            }
            
            _bandView.rotation = MIN(M_PI/2, MAX(-M_PI/2, initialRotation + sender.rotation));
            [self buildThumbnailImage];
            break;
        }
        default:
            break;
    }
    
}

@end


#pragma mark- UI components

@implementation CLBlurCircle

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
    rct.origin.x = 0.35*rct.size.width;
    rct.origin.y = 0.35*rct.size.height;
    rct.size.width *= 0.3;
    rct.size.height *= 0.3;
    
    CGContextSetStrokeColorWithColor(context, self.color.CGColor);
    CGContextStrokeEllipseInRect(context, rct);
    
    self.alpha = 1;
    [UIView animateWithDuration:kCLImageToolFadeoutDuration
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




@implementation CLBlurBand

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self){
        _scale    = 1;
        _rotation = 0;
        _offset   = 0;
    }
    return self;
}

- (void)setScale:(CGFloat)scale
{
    _scale = scale;
    [self calcTransform];
}

- (void)setRotation:(CGFloat)rotation
{
    _rotation = rotation;
    [self calcTransform];
}

- (void)setOffset:(CGFloat)offset
{
    _offset = offset;
    [self calcTransform];
}

- (void)calcTransform
{
    CGAffineTransform transform = CGAffineTransformIdentity;
    transform = CGAffineTransformTranslate(transform, -self.offset*sin(self.rotation), self.offset*cos(self.rotation));
    transform = CGAffineTransformRotate(transform, self.rotation);
    transform = CGAffineTransformScale(transform, 1, self.scale);
    self.transform = transform;
}

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

- (void)setTransform:(CGAffineTransform)transform
{
    [super setTransform:transform];
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGRect rct = self.bounds;
    rct.origin.y = 0.3*rct.size.height;
    rct.size.height *= 0.4;
    
    CGContextSetLineWidth(context, 1/self.scale);
    CGContextSetStrokeColorWithColor(context, self.color.CGColor);
    CGContextStrokeRect(context, rct);
    
    self.alpha = 1;
    [UIView animateWithDuration:kCLImageToolFadeoutDuration
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
