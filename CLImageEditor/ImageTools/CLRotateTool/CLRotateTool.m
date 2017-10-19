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
static NSString* const kCLRotateToolFineRotationEnabled = @"fineRotationEnabled";
static NSString* const kCLRotateToolCropRotate = @"cropRotateEnabled";


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

    BOOL _fineRotationEnabled;

    CLRotatePanel *_gridView;
    UIImageView *_rotateImageView;

    CGFloat _rotationArg;
    CGFloat _orientation;
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
             kCLRotateToolFlipVerticalIconName : @"",
             kCLRotateToolFineRotationEnabled : @NO,
             kCLRotateToolCropRotate : @NO
             };
}

#pragma mark-

- (void)setup
{
    _executed = NO;

    _fineRotationEnabled = [self.toolInfo.optionalInfo[kCLRotateToolFineRotationEnabled] boolValue];

    [self.editor fixZoomScaleWithAnimated:YES];
    
    _initialRect = self.editor.imageView.frame;

    _rotationArg = 0;
    _flipState1 = 0;
    _flipState2 = 0;
    
    _gridView = [[CLRotatePanel alloc] initWithSuperview:self.editor.imageView.superview frame:self.editor.imageView.frame];
    _gridView.backgroundColor = [UIColor clearColor];
    _gridView.bgColor = [self.editor.view.backgroundColor colorWithAlphaComponent:0.8];
    _gridView.gridColor = [[UIColor darkGrayColor] colorWithAlphaComponent:0.8];
    _gridView.clipsToBounds = NO;

    float sliderMaxima = _fineRotationEnabled ? 0.5 : 1;
    _rotateSlider = [self sliderWithValue:0 minimumValue:-sliderMaxima maximumValue:sliderMaxima];
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
    
    UIImage *originalImage = self.editor.imageView.image;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *image = [self buildImage:originalImage];
        
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
            if (_fineRotationEnabled) {
                _orientation = _rotateSlider.value < 0 ? _orientation : _orientation  + 1;
            } else {
                _orientation = (int)floorf((_rotateSlider.value + 1) * 2) + 1;
            }

            if(_orientation > 4){ _orientation -= 4; }
            _rotateSlider.value = _fineRotationEnabled ? 0 : (_orientation / 2) - 1;
            
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
    __block CGFloat rotateValue = 0;
    safe_dispatch_sync_main(^{
        rotateValue = _rotateSlider.value;
    });
    
    CGFloat orientationOffset = _fineRotationEnabled ? _orientation * M_PI_2 : 0;
    _rotationArg = orientationOffset + rotateValue*(_fineRotationEnabled ? M_PI_4 : M_PI);
    if(!clockwise){
        _rotationArg *= -1;
    }
    
    CATransform3D transform = initialTransform;
    transform = CATransform3DRotate(transform, _rotationArg, 0, 0, 1);
    transform = CATransform3DRotate(transform, _flipState1*M_PI, 0, 1, 0);
    transform = CATransform3DRotate(transform, _flipState2*M_PI, 1, 0, 0);
    
    return transform;
}

- (void)rotateStateDidChange
{
    CATransform3D transform = [self rotateTransform:CATransform3DIdentity clockwise:YES];
    CGFloat Wnew = fabs(_initialRect.size.width * cos(_rotationArg)) + fabs(_initialRect.size.height * sin(_rotationArg));
    CGFloat Hnew = fabs(_initialRect.size.width * sin(_rotationArg)) + fabs(_initialRect.size.height * cos(_rotationArg));

    BOOL cropRotateEnabled = [self.toolInfo.optionalInfo[kCLRotateToolCropRotate] boolValue];
    CGFloat Rw = _gridView.width / Wnew;
    CGFloat Rh = _gridView.height / Hnew;
    CGFloat scale = MIN(Rw, Rh) * 0.95;
    if (cropRotateEnabled) {
        Rw = _initialRect.size.width / Wnew;
        Rh = _initialRect.size.height / Hnew;
        scale = 1 / MIN(Rw, Rh);
    }

    
    transform = CATransform3DScale(transform, scale, scale, 1);
    _rotateImageView.layer.transform = transform;

    if (!cropRotateEnabled) {
        _gridView.gridRect = _rotateImageView.frame;
    }
}

- (UIImage*)buildImage:(UIImage*)image
{
    CIImage *ciImage = [[CIImage alloc] initWithImage:image];
    CIFilter *filter = [CIFilter filterWithName:@"CIAffineTransform" keysAndValues:kCIInputImageKey, ciImage, nil];

    [filter setDefaults];
    CGAffineTransform transform = CATransform3DGetAffineTransform([self rotateTransform:CATransform3DIdentity clockwise:NO]);
    [filter setValue:[NSValue valueWithBytes:&transform objCType:@encode(CGAffineTransform)] forKey:@"inputTransform"];
    
    
    CIContext *context = [CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer : @(NO)}];
    CIImage *outputImage = [filter outputImage];
    CGImageRef cgImage = [context createCGImage:outputImage fromRect:[outputImage extent]];
    
    UIImage *result = [UIImage imageWithCGImage:cgImage];
    
    CGImageRelease(cgImage);

    BOOL cropRotateEnabled = [self.toolInfo.optionalInfo[kCLRotateToolCropRotate] boolValue];
    if (cropRotateEnabled) {
        result = [self cropAdjustImage:result];
    }

    return result;
}

- (UIImage *)cropAdjustImage:(UIImage *)image
{
    CGFloat Wnew = fabs(_initialRect.size.width * cos(_rotationArg)) + fabs(_initialRect.size.height * sin(_rotationArg));
    CGFloat Hnew = fabs(_initialRect.size.width * sin(_rotationArg)) + fabs(_initialRect.size.height * cos(_rotationArg));

    CGFloat Rw = _initialRect.size.width / Wnew;
    CGFloat Rh = _initialRect.size.height / Hnew;
    CGFloat scale = MIN(Rw, Rh);

    CGSize originalFrame = self.editor.imageView.image.size;
    CGFloat finalW = originalFrame.width * scale;
    CGFloat finalH = originalFrame.height * scale;

    CGFloat deltaX = (image.size.width - finalW) / 2.0;
    CGFloat deltaY = (image.size.height - finalH) / 2.0;
    CGRect newFrame = CGRectMake(deltaX, deltaY, finalW, finalH);
    UIImage *croppedImage = [image crop:newFrame];

    return croppedImage;
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
