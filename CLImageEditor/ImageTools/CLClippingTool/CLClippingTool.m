//
//  CLClippingTool.m
//
//  Created by sho yakushiji on 2013/10/18.
//  Copyright (c) 2013年 CALACULU. All rights reserved.
//

#import "CLClippingTool.h"


static NSString* const kCLClippingToolRatios = @"ratios";
static NSString* const kCLClippingToolSwapButtonHidden = @"swapButtonHidden";
static NSString* const kCLClippingToolRotateIconName = @"rotateIconAssetsName";

static NSString* const kCLClippingToolRatioValue1 = @"value1";
static NSString* const kCLClippingToolRatioValue2 = @"value2";
static NSString* const kCLClippingToolRatioTitleFormat = @"titleFormat";


@interface CLRatio : NSObject
@property (nonatomic, assign) BOOL isLandscape;
@property (nonatomic, readonly) CGFloat ratio;
@property (nonatomic, strong) NSString *titleFormat;

- (id)initWithValue1:(CGFloat)value1 value2:(CGFloat)value2;

@end


@interface CLRatioMenuItem : CLToolbarMenuItem
@property (nonatomic, strong) CLRatio *ratio;
- (void)changeOrientation;
@end


@interface CLClippingPanel : UIView
@property (nonatomic, assign) CGRect clippingRect;
@property (nonatomic, strong) CLRatio *clippingRatio;
- (id)initWithSuperview:(UIView*)superview frame:(CGRect)frame;
- (void)setBgColor:(UIColor*)bgColor;
- (void)setGridColor:(UIColor*)gridColor;
- (void)clippingRatioDidChange;
@end


#pragma mark- CLClippintTool

@interface CLClippingTool()
@property (nonatomic, strong) CLRatioMenuItem *selectedMenu;
@end

@implementation CLClippingTool
{
    CLClippingPanel *_gridView;
    
    UIView *_menuContainer;
    UIScrollView *_menuScroll;
}

+ (NSString*)defaultTitle
{
    return [CLImageEditorTheme localizedString:@"CLClippingTool_DefaultTitle" withDefault:@"Crop"];
}

+ (BOOL)isAvailable
{
    return YES;
}

#pragma mark- optional info

+ (NSArray*)defaultPresetRatios
{
    return @[
             @{kCLClippingToolRatioValue1:@0, kCLClippingToolRatioValue2:@0, kCLClippingToolRatioTitleFormat:[CLImageEditorTheme localizedString:@"CLClippingTool_ItemMenuCustom" withDefault:@"Custom"]},
             @{kCLClippingToolRatioValue1:@1, kCLClippingToolRatioValue2:@1, kCLClippingToolRatioTitleFormat:@"%g : %g"},
             @{kCLClippingToolRatioValue1:@4, kCLClippingToolRatioValue2:@3, kCLClippingToolRatioTitleFormat:@"%g : %g"},
             @{kCLClippingToolRatioValue1:@3, kCLClippingToolRatioValue2:@2, kCLClippingToolRatioTitleFormat:@"%g : %g"},
             @{kCLClippingToolRatioValue1:@16, kCLClippingToolRatioValue2:@9, kCLClippingToolRatioTitleFormat:@"%g : %g"},
             ];
}

+ (NSValue*)defaultSwapButtonHidden
{
    return @(NO);
}

+ (NSDictionary*)optionalInfo
{
    return @{
             kCLClippingToolRatios:[self defaultPresetRatios],
             kCLClippingToolSwapButtonHidden:[self defaultSwapButtonHidden],
             kCLClippingToolRotateIconName:@""
             };
}

#pragma mark- implementation

- (void)setup
{
    [self.editor fixZoomScaleWithAnimated:YES];
    
    if(!self.toolInfo.optionalInfo){
        self.toolInfo.optionalInfo = [[self.class optionalInfo] mutableCopy];
    }
    
    BOOL swapBtnHidden = [self.toolInfo.optionalInfo[kCLClippingToolSwapButtonHidden] boolValue];
    CGFloat buttonWidth = (swapBtnHidden) ? 0 : 70;
    
    _menuContainer = [[UIView alloc] initWithFrame:self.editor.menuView.frame];
    _menuContainer.backgroundColor = self.editor.menuView.backgroundColor;
    [self.editor.view addSubview:_menuContainer];
    
    _menuScroll = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, _menuContainer.width - buttonWidth, _menuContainer.height)];
    _menuScroll.backgroundColor = [UIColor clearColor];
    _menuScroll.showsHorizontalScrollIndicator = NO;
    _menuScroll.clipsToBounds = NO;
    [_menuContainer addSubview:_menuScroll];
    
    if(!swapBtnHidden){
        UIView *btnPanel = [[UIView alloc] initWithFrame:CGRectMake(_menuScroll.right, 0, buttonWidth, _menuContainer.height)];
        btnPanel.backgroundColor = [_menuContainer.backgroundColor colorWithAlphaComponent:0.9];
        [_menuContainer addSubview:btnPanel];
        
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(0, 0, 40, 40);
        btn.center = CGPointMake(btnPanel.width/2, btnPanel.height/2 - 10);
        [btn addTarget:self action:@selector(pushedRotateBtn:) forControlEvents:UIControlEventTouchUpInside];
        [btn setImage:[self imageForKey:kCLClippingToolRotateIconName defaultImageName:@"btn_rotate.png"] forState:UIControlStateNormal];
        btn.adjustsImageWhenHighlighted = YES;
        [btnPanel addSubview:btn];
    }
    
    _gridView = [[CLClippingPanel alloc] initWithSuperview:self.editor.imageView.superview frame:self.editor.imageView.frame];
    _gridView.backgroundColor = [UIColor clearColor];
    _gridView.bgColor = [self.editor.view.backgroundColor colorWithAlphaComponent:0.8];
    _gridView.gridColor = [[UIColor darkGrayColor] colorWithAlphaComponent:0.8];
    _gridView.clipsToBounds = NO;
    
    [self setCropMenu];
    
    _menuContainer.transform = CGAffineTransformMakeTranslation(0, self.editor.view.height-_menuScroll.top);
    [UIView animateWithDuration:kCLImageToolAnimationDuration
                     animations:^{
                         self->_menuContainer.transform = CGAffineTransformIdentity;
                     }];
}

- (void)cleanup
{
    [self.editor resetZoomScaleWithAnimated:YES];
    [_gridView removeFromSuperview];
    
    [UIView animateWithDuration:kCLImageToolAnimationDuration
                     animations:^{
                         self->_menuContainer.transform = CGAffineTransformMakeTranslation(0, self.editor.view.height-self->_menuScroll.top);
                     }
                     completion:^(BOOL finished) {
                         [self->_menuContainer removeFromSuperview];
                     }];
}

- (void)executeWithCompletionBlock:(void (^)(UIImage *, NSError *, NSDictionary *))completionBlock
{
    CGFloat zoomScale = self.editor.imageView.width / self.editor.imageView.image.size.width;
    CGRect rct = _gridView.clippingRect;
    rct.size.width  /= zoomScale;
    rct.size.height /= zoomScale;
    rct.origin.x    /= zoomScale;
    rct.origin.y    /= zoomScale;
    
    UIImage *result = [self.editor.imageView.image crop:rct];
    completionBlock(result, nil, nil);
}

#pragma mark-

- (void)setCropMenu
{
    CGFloat W = 70;
    CGFloat x = 0;
    
    NSArray *ratios = self.toolInfo.optionalInfo[kCLClippingToolRatios];
    BOOL swapBtnHidden = [self.toolInfo.optionalInfo[kCLClippingToolSwapButtonHidden] boolValue];
    
    CGSize  imgSize = self.editor.imageView.image.size;
    CGFloat maxW = MIN(imgSize.width, imgSize.height);
    UIImage *iconImage = [self.editor.imageView.image resize:CGSizeMake(W * imgSize.width/maxW, W * imgSize.height/maxW)];
    
    for(NSDictionary *info in ratios){
        CGFloat val1 = [info[kCLClippingToolRatioValue1] floatValue];
        CGFloat val2 = [info[kCLClippingToolRatioValue2] floatValue];
        
        CLRatio *ratio = [[CLRatio alloc] initWithValue1:val1 value2:val2];
        ratio.titleFormat = info[kCLClippingToolRatioTitleFormat];
        
        if(swapBtnHidden){
            ratio.isLandscape = (val1 > val2);
        }
        else{
            ratio.isLandscape = (imgSize.width > imgSize.height);
        }
        
        CLRatioMenuItem *view = [[CLRatioMenuItem alloc] initWithFrame:CGRectMake(x, 0, W, _menuScroll.height) target:self action:@selector(tappedMenu:) toolInfo:nil];
        view.iconImage = iconImage;
        view.ratio = ratio;
        
        if(ratios.count>1 || !swapBtnHidden){
            [_menuScroll addSubview:view];
            x += W;
        }
        
        if(self.selectedMenu==nil){
            self.selectedMenu = view;
        }
    }
    _menuScroll.contentSize = CGSizeMake(MAX(x, _menuScroll.frame.size.width+1), 0);
}

- (void)tappedMenu:(UITapGestureRecognizer*)sender
{
    CLRatioMenuItem *view = (CLRatioMenuItem*)sender.view;
    
    view.alpha = 0.2;
    [UIView animateWithDuration:kCLImageToolAnimationDuration
                     animations:^{
                         view.alpha = 1;
                     }
     ];
    
    self.selectedMenu = view;
}

- (void)setSelectedMenu:(CLRatioMenuItem *)selectedMenu
{
    if(selectedMenu != _selectedMenu){
        _selectedMenu.backgroundColor = [UIColor clearColor];
        _selectedMenu = selectedMenu;
        _selectedMenu.backgroundColor = [CLImageEditorTheme toolbarSelectedButtonColor];
        
        if(selectedMenu.ratio.ratio==0){
            _gridView.clippingRatio = nil;
        }
        else{
            _gridView.clippingRatio = selectedMenu.ratio;
        }
    }
}

- (void)pushedRotateBtn:(UIButton*)sender
{
    for(CLRatioMenuItem *item in _menuScroll.subviews){
        if([item isKindOfClass:[CLRatioMenuItem class]]){
            [item changeOrientation];
        }
    }
    
    if(_gridView.clippingRatio.ratio!=0 && _gridView.clippingRatio.ratio!=1){
        [_gridView clippingRatioDidChange];
    }
}

@end


#pragma mark- UI components

@interface CLClippingCircle : UIView

@property (nonatomic, strong) UIColor *bgColor;

@end

@implementation CLClippingCircle

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

@end

@interface CLGridLayar : CALayer
@property (nonatomic, assign) CGRect clippingRect;
@property (nonatomic, strong) UIColor *bgColor;
@property (nonatomic, strong) UIColor *gridColor;
@end

@implementation CLGridLayar

+ (BOOL)needsDisplayForKey:(NSString*)key
{
    if ([key isEqualToString:@"clippingRect"]) {
        return YES;
    }
    return [super needsDisplayForKey:key];
}

- (id)initWithLayer:(id)layer
{
    self = [super initWithLayer:layer];
    if(self && [layer isKindOfClass:[CLGridLayar class]]){
        self.bgColor   = ((CLGridLayar*)layer).bgColor;
        self.gridColor = ((CLGridLayar*)layer).gridColor;
        self.clippingRect = ((CLGridLayar*)layer).clippingRect;
    }
    return self;
}

- (void)drawInContext:(CGContextRef)context
{
    CGRect rct = self.bounds;
    CGContextSetFillColorWithColor(context, self.bgColor.CGColor);
    CGContextFillRect(context, rct);
    
    CGContextClearRect(context, _clippingRect);
    
    CGContextSetStrokeColorWithColor(context, self.gridColor.CGColor);
    CGContextSetLineWidth(context, 1);
    
    rct = self.clippingRect;
    
    CGContextBeginPath(context);
    CGFloat dW = 0;
    for(int i=0;i<4;++i){
        CGContextMoveToPoint(context, rct.origin.x+dW, rct.origin.y);
        CGContextAddLineToPoint(context, rct.origin.x+dW, rct.origin.y+rct.size.height);
        dW += _clippingRect.size.width/3;
    }
    
    dW = 0;
    for(int i=0;i<4;++i){
        CGContextMoveToPoint(context, rct.origin.x, rct.origin.y+dW);
        CGContextAddLineToPoint(context, rct.origin.x+rct.size.width, rct.origin.y+dW);
        dW += rct.size.height/3;
    }
    CGContextStrokePath(context);
}

@end

@implementation CLClippingPanel
{
    CLGridLayar *_gridLayer;
    CLClippingCircle *_ltView;
    CLClippingCircle *_lbView;
    CLClippingCircle *_rtView;
    CLClippingCircle *_rbView;
}

- (CLClippingCircle*)clippingCircleWithTag:(NSInteger)tag
{
    CLClippingCircle *view = [[CLClippingCircle alloc] initWithFrame:CGRectMake(0, 0, 75, 75)];
    view.backgroundColor = [UIColor clearColor];
    view.bgColor = [UIColor blackColor];
    view.tag = tag;
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panCircleView:)];
    [view addGestureRecognizer:panGesture];
    
    [self.superview addSubview:view];
    
    return view;
}

- (id)initWithSuperview:(UIView*)superview frame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self){
        [superview addSubview:self];
        
        _gridLayer = [[CLGridLayar alloc] init];
        _gridLayer.frame = self.bounds;
        _gridLayer.bgColor   = [UIColor colorWithWhite:1 alpha:0.6];
        _gridLayer.gridColor = [UIColor colorWithWhite:0 alpha:0.6];
        [self.layer addSublayer:_gridLayer];
        
        _ltView = [self clippingCircleWithTag:0];
        _lbView = [self clippingCircleWithTag:1];
        _rtView = [self clippingCircleWithTag:2];
        _rbView = [self clippingCircleWithTag:3];
        
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGridView:)];
        [self addGestureRecognizer:panGesture];
        
        self.clippingRect = self.bounds;
    }
    return self;
}

- (void)removeFromSuperview
{
    [super removeFromSuperview];
    
    [_ltView removeFromSuperview];
    [_lbView removeFromSuperview];
    [_rtView removeFromSuperview];
    [_rbView removeFromSuperview];
}

- (void)setBgColor:(UIColor *)bgColor
{
    _gridLayer.bgColor = bgColor;
}

- (void)setGridColor:(UIColor *)gridColor
{
    _gridLayer.gridColor = gridColor;
    _ltView.bgColor = _lbView.bgColor = _rtView.bgColor = _rbView.bgColor = [gridColor colorWithAlphaComponent:1];
}

- (void)setClippingRect:(CGRect)clippingRect
{
    _clippingRect = clippingRect;
    
    _ltView.center = [self.superview convertPoint:CGPointMake(_clippingRect.origin.x, _clippingRect.origin.y) fromView:self];
    _lbView.center = [self.superview convertPoint:CGPointMake(_clippingRect.origin.x, _clippingRect.origin.y+_clippingRect.size.height) fromView:self];
    _rtView.center = [self.superview convertPoint:CGPointMake(_clippingRect.origin.x+_clippingRect.size.width, _clippingRect.origin.y) fromView:self];
    _rbView.center = [self.superview convertPoint:CGPointMake(_clippingRect.origin.x+_clippingRect.size.width, _clippingRect.origin.y+_clippingRect.size.height) fromView:self];
    
    _gridLayer.clippingRect = clippingRect;
    [self setNeedsDisplay];
}

- (void)setClippingRect:(CGRect)clippingRect animated:(BOOL)animated
{
    if(animated){
        [UIView animateWithDuration:kCLImageToolFadeoutDuration
                         animations:^{
                             self->_ltView.center = [self.superview convertPoint:CGPointMake(clippingRect.origin.x, clippingRect.origin.y) fromView:self];
                             self->_lbView.center = [self.superview convertPoint:CGPointMake(clippingRect.origin.x, clippingRect.origin.y+clippingRect.size.height) fromView:self];
                             self->_rtView.center = [self.superview convertPoint:CGPointMake(clippingRect.origin.x+clippingRect.size.width, clippingRect.origin.y) fromView:self];
                             self->_rbView.center = [self.superview convertPoint:CGPointMake(clippingRect.origin.x+clippingRect.size.width, clippingRect.origin.y+clippingRect.size.height) fromView:self];
                         }
         ];
        
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"clippingRect"];
        animation.duration = kCLImageToolFadeoutDuration;
        animation.fromValue = [NSValue valueWithCGRect:_clippingRect];
        animation.toValue = [NSValue valueWithCGRect:clippingRect];
        [_gridLayer addAnimation:animation forKey:nil];
        
        _gridLayer.clippingRect = clippingRect;
        _clippingRect = clippingRect;
        [self setNeedsDisplay];
    }
    else{
        self.clippingRect = clippingRect;
    }
}

- (void)clippingRatioDidChange
{
    CGRect rect = self.bounds;
    if(self.clippingRatio){
        CGFloat H = rect.size.width * self.clippingRatio.ratio;
        if(H<=rect.size.height){
            rect.size.height = H;
        }
        else{
            rect.size.width *= rect.size.height / H;
        }
        
        rect.origin.x = (self.bounds.size.width - rect.size.width) / 2;
        rect.origin.y = (self.bounds.size.height - rect.size.height) / 2;
    }
    [self setClippingRect:rect animated:YES];
}

- (void)setClippingRatio:(CLRatio *)clippingRatio
{
    if(clippingRatio != _clippingRatio){
        _clippingRatio = clippingRatio;
        [self clippingRatioDidChange];
    }
}

- (void)setNeedsDisplay
{
    [super setNeedsDisplay];
    [_gridLayer setNeedsDisplay];
}

- (void)panCircleView:(UIPanGestureRecognizer*)sender
{
    CGPoint point = [sender locationInView:self];
    CGPoint dp = [sender translationInView:self];
    
    CGRect rct = self.clippingRect;
    
    const CGFloat W = self.frame.size.width;
    const CGFloat H = self.frame.size.height;
    CGFloat minX = 0;
    CGFloat minY = 0;
    CGFloat maxX = W;
    CGFloat maxY = H;
    
    CGFloat ratio = (sender.view.tag == 1 || sender.view.tag==2) ? -self.clippingRatio.ratio : self.clippingRatio.ratio;
    
    switch (sender.view.tag) {
        case 0: // upper left
        {
            maxX = MAX((rct.origin.x + rct.size.width)  - 0.1 * W, 0.1 * W);
            maxY = MAX((rct.origin.y + rct.size.height) - 0.1 * H, 0.1 * H);
            
            if(ratio!=0){
                CGFloat y0 = rct.origin.y - ratio * rct.origin.x;
                CGFloat x0 = -y0 / ratio;
                minX = MAX(x0, 0);
                minY = MAX(y0, 0);
                
                point.x = MAX(minX, MIN(point.x, maxX));
                point.y = MAX(minY, MIN(point.y, maxY));
                
                if(-dp.x*ratio + dp.y > 0){ point.x = (point.y - y0) / ratio; }
                else{ point.y = point.x * ratio + y0; }
            }
            else{
                point.x = MAX(minX, MIN(point.x, maxX));
                point.y = MAX(minY, MIN(point.y, maxY));
            }
            
            rct.size.width  = rct.size.width  - (point.x - rct.origin.x);
            rct.size.height = rct.size.height - (point.y - rct.origin.y);
            rct.origin.x = point.x;
            rct.origin.y = point.y;
            break;
        }
        case 1: // lower left
        {
            maxX = MAX((rct.origin.x + rct.size.width)  - 0.1 * W, 0.1 * W);
            minY = MAX(rct.origin.y + 0.1 * H, 0.1 * H);
            
            if(ratio!=0){
                CGFloat y0 = (rct.origin.y + rct.size.height) - ratio* rct.origin.x ;
                CGFloat xh = (H - y0) / ratio;
                minX = MAX(xh, 0);
                maxY = MIN(y0, H);
                
                point.x = MAX(minX, MIN(point.x, maxX));
                point.y = MAX(minY, MIN(point.y, maxY));
                
                if(-dp.x*ratio + dp.y < 0){ point.x = (point.y - y0) / ratio; }
                else{ point.y = point.x * ratio + y0; }
            }
            else{
                point.x = MAX(minX, MIN(point.x, maxX));
                point.y = MAX(minY, MIN(point.y, maxY));
            }
            
            rct.size.width  = rct.size.width  - (point.x - rct.origin.x);
            rct.size.height = point.y - rct.origin.y;
            rct.origin.x = point.x;
            break;
        }
        case 2: // upper right
        {
            minX = MAX(rct.origin.x + 0.1 * W, 0.1 * W);
            maxY = MAX((rct.origin.y + rct.size.height) - 0.1 * H, 0.1 * H);
            
            if(ratio!=0){
                CGFloat y0 = rct.origin.y - ratio * (rct.origin.x + rct.size.width);
                CGFloat yw = ratio * W + y0;
                CGFloat x0 = -y0 / ratio;
                maxX = MIN(x0, W);
                minY = MAX(yw, 0);
                
                point.x = MAX(minX, MIN(point.x, maxX));
                point.y = MAX(minY, MIN(point.y, maxY));
                
                if(-dp.x*ratio + dp.y > 0){ point.x = (point.y - y0) / ratio; }
                else{ point.y = point.x * ratio + y0; }
            }
            else{
                point.x = MAX(minX, MIN(point.x, maxX));
                point.y = MAX(minY, MIN(point.y, maxY));
            }
            
            rct.size.width  = point.x - rct.origin.x;
            rct.size.height = rct.size.height - (point.y - rct.origin.y);
            rct.origin.y = point.y;
            break;
        }
        case 3: // lower right
        {
            minX = MAX(rct.origin.x + 0.1 * W, 0.1 * W);
            minY = MAX(rct.origin.y + 0.1 * H, 0.1 * H);
            
            if(ratio!=0){
                CGFloat y0 = (rct.origin.y + rct.size.height) - ratio * (rct.origin.x + rct.size.width);
                CGFloat yw = ratio * W + y0;
                CGFloat xh = (H - y0) / ratio;
                maxX = MIN(xh, W);
                maxY = MIN(yw, H);
                
                point.x = MAX(minX, MIN(point.x, maxX));
                point.y = MAX(minY, MIN(point.y, maxY));
                
                if(-dp.x*ratio + dp.y < 0){ point.x = (point.y - y0) / ratio; }
                else{ point.y = point.x * ratio + y0; }
            }
            else{
                point.x = MAX(minX, MIN(point.x, maxX));
                point.y = MAX(minY, MIN(point.y, maxY));
            }
            
            rct.size.width  = point.x - rct.origin.x;
            rct.size.height = point.y - rct.origin.y;
            break;
        }
        default:
            break;
    }
    self.clippingRect = rct;
}

- (void)panGridView:(UIPanGestureRecognizer*)sender
{
    static BOOL dragging = NO;
    static CGRect initialRect;
    
    if(sender.state==UIGestureRecognizerStateBegan){
        CGPoint point = [sender locationInView:self];
        dragging = CGRectContainsPoint(_clippingRect, point);
        initialRect = self.clippingRect;
    }
    else if(dragging){
        CGPoint point = [sender translationInView:self];
        CGFloat left  = MIN(MAX(initialRect.origin.x + point.x, 0), self.frame.size.width-initialRect.size.width);
        CGFloat top   = MIN(MAX(initialRect.origin.y + point.y, 0), self.frame.size.height-initialRect.size.height);
        
        CGRect rct = self.clippingRect;
        rct.origin.x = left;
        rct.origin.y = top;
        self.clippingRect = rct;
    }
}
@end




@implementation CLRatio
{
    CGFloat _longSide;
    CGFloat _shortSide;
}

- (id)initWithValue1:(CGFloat)value1 value2:(CGFloat)value2
{
    self = [super init];
    if(self){
        _longSide  = MAX(fabs(value1), fabs(value2));
        _shortSide = MIN(fabs(value1), fabs(value2));
    }
    return self;
}

- (NSString*)description
{
    NSString *format = (self.titleFormat) ? self.titleFormat : @"%g : %g";
    
    if(self.isLandscape){
        return [NSString stringWithFormat:format, _longSide, _shortSide];
    }
    return [NSString stringWithFormat:format, _shortSide, _longSide];
}

- (CGFloat)ratio
{
    if(_longSide==0 || _shortSide==0){
        return 0;
    }
    
    if(self.isLandscape){
        return _shortSide / (CGFloat)_longSide;
    }
    return _longSide / (CGFloat)_shortSide;
}

@end


@implementation CLRatioMenuItem

- (void)setRatio:(CLRatio *)ratio
{
    if(ratio != _ratio){
        _ratio = ratio;
        [self refreshViews];
    }
}

- (void)refreshViews
{
    _titleLabel.text = [_ratio description];
    
    CGPoint center = _iconView.center;
    CGFloat W, H;
    if(_ratio.ratio!=0){
        if(_ratio.isLandscape){
            W = 50;
            H = 50*_ratio.ratio;
        }
        else{
            W = 50/_ratio.ratio;
            H = 50;
        }
    }
    else{
        CGFloat maxW  = MAX(_iconView.image.size.width, _iconView.image.size.height);
        W = 50 * _iconView.image.size.width / maxW;
        H = 50 * _iconView.image.size.height / maxW;
    }
    _iconView.frame = CGRectMake(center.x-W/2, center.y-H/2, W, H);
}

- (void)changeOrientation
{
    self.ratio.isLandscape = !self.ratio.isLandscape;
    
    [UIView animateWithDuration:kCLImageToolFadeoutDuration
                     animations:^{
                         [self refreshViews];
                     }
     ];
}

@end
