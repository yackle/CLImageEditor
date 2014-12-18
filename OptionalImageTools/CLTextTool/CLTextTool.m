//
//  CLTextTool.m
//
//  Created by sho yakushiji on 2013/12/15.
//  Copyright (c) 2013年 CALACULU. All rights reserved.
//

#import "CLTextTool.h"

#import "CLCircleView.h"
#import "CLColorPickerView.h"
#import "CLFontPickerView.h"
#import "CLTextLabel.h"

#import "CLTextSettingView.h"

static NSString* const CLTextViewActiveViewDidChangeNotification = @"CLTextViewActiveViewDidChangeNotificationString";
static NSString* const CLTextViewActiveViewDidTapNotification = @"CLTextViewActiveViewDidTapNotificationString";

static NSString* const kCLTextToolDeleteIconName = @"deleteIconAssetsName";
static NSString* const kCLTextToolCloseIconName = @"closeIconAssetsName";
static NSString* const kCLTextToolNewTextIconName = @"newTextIconAssetsName";
static NSString* const kCLTextToolEditTextIconName = @"editTextIconAssetsName";
static NSString* const kCLTextToolFontIconName = @"fontIconAssetsName";
static NSString* const kCLTextToolAlignLeftIconName = @"alignLeftIconAssetsName";
static NSString* const kCLTextToolAlignCenterIconName = @"alignCenterIconAssetsName";
static NSString* const kCLTextToolAlignRightIconName = @"alignRightIconAssetsName";


@interface _CLTextView : UIView
@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) UIFont *font;
@property (nonatomic, strong) UIColor *fillColor;
@property (nonatomic, strong) UIColor *borderColor;
@property (nonatomic, assign) CGFloat borderWidth;
@property (nonatomic, assign) NSTextAlignment textAlignment;

+ (void)setActiveTextView:(_CLTextView*)view;
- (id)initWithTool:(CLTextTool*)tool;
- (void)setScale:(CGFloat)scale;
- (void)sizeToFitWithMaxWidth:(CGFloat)width lineHeight:(CGFloat)lineHeight;

@end



@interface CLTextTool()
<CLColorPickerViewDelegate, CLFontPickerViewDelegate, UITextViewDelegate, CLTextSettingViewDelegate>
@property (nonatomic, strong) _CLTextView *selectedTextView;
@end

@implementation CLTextTool
{
    UIImage *_originalImage;
    
    UIView *_workingView;
    
    CLTextSettingView *_settingView;
    
    CLToolbarMenuItem *_textBtn;
    CLToolbarMenuItem *_colorBtn;
    CLToolbarMenuItem *_fontBtn;
    
    CLToolbarMenuItem *_alignLeftBtn;
    CLToolbarMenuItem *_alignCenterBtn;
    CLToolbarMenuItem *_alignRightBtn;
    
    UIScrollView *_menuScroll;
}

+ (NSArray*)subtools
{
    return nil;
}

+ (NSString*)defaultTitle
{
    return [CLImageEditorTheme localizedString:@"CLTextTool_DefaultTitle" withDefault:@"Text"];
}

+ (BOOL)isAvailable
{
    return ([UIDevice iosVersion] >= 5.0);
}

+ (CGFloat)defaultDockedNumber
{
    return 8;
}

#pragma mark- optional info

+ (NSDictionary*)optionalInfo
{
    return @{
             kCLTextToolDeleteIconName:@"",
             kCLTextToolCloseIconName:@"",
             kCLTextToolNewTextIconName:@"",
             kCLTextToolEditTextIconName:@"",
             kCLTextToolFontIconName:@"",
             kCLTextToolAlignLeftIconName:@"",
             kCLTextToolAlignCenterIconName:@"",
             kCLTextToolAlignRightIconName:@"",
             };
}

#pragma mark- implementation

- (void)setup
{
    _originalImage = self.editor.imageView.image;
    
    [self.editor fixZoomScaleWithAnimated:YES];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activeTextViewDidChange:) name:CLTextViewActiveViewDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activeTextViewDidTap:) name:CLTextViewActiveViewDidTapNotification object:nil];
    
    _menuScroll = [[UIScrollView alloc] initWithFrame:self.editor.menuView.frame];
    _menuScroll.backgroundColor = self.editor.menuView.backgroundColor;
    _menuScroll.showsHorizontalScrollIndicator = NO;
    [self.editor.view addSubview:_menuScroll];
    
    _workingView = [[UIView alloc] initWithFrame:[self.editor.view convertRect:self.editor.imageView.frame fromView:self.editor.imageView.superview]];
    _workingView.clipsToBounds = YES;
    [self.editor.view addSubview:_workingView];
    
    _settingView = [[CLTextSettingView alloc] initWithFrame:CGRectMake(0, 0, self.editor.view.width, 180)];
    _settingView.top = _menuScroll.top - _settingView.height;
    _settingView.backgroundColor = [CLImageEditorTheme toolbarColor];
    _settingView.textColor = [CLImageEditorTheme toolbarTextColor];
    _settingView.fontPickerForegroundColor = _settingView.backgroundColor;
    _settingView.delegate = self;
    [self.editor.view addSubview:_settingView];
    
    UIButton *okButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [okButton setImage:[self imageForKey:kCLTextToolCloseIconName defaultImageName:@"btn_delete.png"] forState:UIControlStateNormal];
    okButton.frame = CGRectMake(_settingView.width-32, 0, 32, 32);
    [okButton addTarget:self action:@selector(pushedButton:) forControlEvents:UIControlEventTouchUpInside];
    [_settingView addSubview:okButton];
    
    [self setMenu];
    
    self.selectedTextView = nil;
    
    _menuScroll.transform = CGAffineTransformMakeTranslation(0, self.editor.view.height-_menuScroll.top);
    [UIView animateWithDuration:kCLImageToolAnimationDuration
                     animations:^{
                         _menuScroll.transform = CGAffineTransformIdentity;
                     }];
}

- (void)cleanup
{
    [self.editor resetZoomScaleWithAnimated:YES];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_settingView endEditing:YES];
    [_settingView removeFromSuperview];
    [_workingView removeFromSuperview];
    
    [UIView animateWithDuration:kCLImageToolAnimationDuration
                     animations:^{
                         _menuScroll.transform = CGAffineTransformMakeTranslation(0, self.editor.view.height-_menuScroll.top);
                     }
                     completion:^(BOOL finished) {
                         [_menuScroll removeFromSuperview];
                     }];
}

- (void)executeWithCompletionBlock:(void (^)(UIImage *, NSError *, NSDictionary *))completionBlock
{
    [_CLTextView setActiveTextView:nil];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *image = [self buildImage:_originalImage];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completionBlock(image, nil, nil);
        });
    });
}

#pragma mark-

- (UIImage*)buildImage:(UIImage*)image
{
    UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
    
    [image drawAtPoint:CGPointZero];
    
    CGFloat scale = image.size.width / _workingView.width;
    CGContextScaleCTM(UIGraphicsGetCurrentContext(), scale, scale);
    [_workingView.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage *tmp = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return tmp;
}

- (void)setMenuBtnEnabled:(BOOL)enabled
{
    _textBtn.userInteractionEnabled =
    _colorBtn.userInteractionEnabled =
    _fontBtn.userInteractionEnabled =
    _alignLeftBtn.userInteractionEnabled =
    _alignCenterBtn.userInteractionEnabled =
    _alignRightBtn.userInteractionEnabled = enabled;
}

- (void)setSelectedTextView:(_CLTextView *)selectedTextView
{
    if(selectedTextView != _selectedTextView){
        _selectedTextView = selectedTextView;
    }
    
    [self setMenuBtnEnabled:(_selectedTextView!=nil)];
    
    if(_selectedTextView==nil){
        [self hideSettingView];
        
        _colorBtn.iconView.backgroundColor = _settingView.selectedFillColor;
        _alignLeftBtn.selected = _alignCenterBtn.selected = _alignRightBtn.selected = NO;
    }
    else{
        _colorBtn.iconView.backgroundColor = selectedTextView.fillColor;
        _colorBtn.iconView.layer.borderColor = selectedTextView.borderColor.CGColor;
        _colorBtn.iconView.layer.borderWidth = MAX(2, 10*selectedTextView.borderWidth);
        
        _settingView.selectedText = selectedTextView.text;
        _settingView.selectedFillColor = selectedTextView.fillColor;
        _settingView.selectedBorderColor = selectedTextView.borderColor;
        _settingView.selectedBorderWidth = selectedTextView.borderWidth;
        _settingView.selectedFont = selectedTextView.font;
        [self setTextAlignment:selectedTextView.textAlignment];
    }
}

- (void)activeTextViewDidChange:(NSNotification*)notification
{
    self.selectedTextView = notification.object;
}

- (void)activeTextViewDidTap:(NSNotification*)notification
{
    [self beginTextEditting];
}

- (void)setMenu
{
    CGFloat W = 70;
    CGFloat H = _menuScroll.height;
    CGFloat x = 0;
    
    NSArray *_menu = @[
                       @{@"title":[CLImageEditorTheme localizedString:@"CLTextTool_MenuItemNew" withDefault:@"New"], @"icon":[self imageForKey:kCLTextToolNewTextIconName defaultImageName:@"btn_add.png"]},
                       @{@"title":[CLImageEditorTheme localizedString:@"CLTextTool_MenuItemText" withDefault:@"Text"], @"icon":[self imageForKey:kCLTextToolEditTextIconName defaultImageName:@"icon.png"]},
                       @{@"title":[CLImageEditorTheme localizedString:@"CLTextTool_MenuItemColor" withDefault:@"Color"]},
                       @{@"title":[CLImageEditorTheme localizedString:@"CLTextTool_MenuItemFont" withDefault:@"Font"], @"icon":[self imageForKey:kCLTextToolFontIconName defaultImageName:@"btn_font.png"]},
                       @{@"title":[CLImageEditorTheme localizedString:@"CLTextTool_MenuItemAlignLeft" withDefault:@" "], @"icon":[self imageForKey:kCLTextToolAlignLeftIconName defaultImageName:@"btn_align_left.png"]},
                       @{@"title":[CLImageEditorTheme localizedString:@"CLTextTool_MenuItemAlignCenter" withDefault:@" "], @"icon":[self imageForKey:kCLTextToolAlignCenterIconName defaultImageName:@"btn_align_center.png"]},
                       @{@"title":[CLImageEditorTheme localizedString:@"CLTextTool_MenuItemAlignRight" withDefault:@" "], @"icon":[self imageForKey:kCLTextToolAlignRightIconName defaultImageName:@"btn_align_right.png"]},
                       ];
    
    NSInteger tag = 0;
    for(NSDictionary *obj in _menu){
        CLToolbarMenuItem *view = [CLImageEditorTheme menuItemWithFrame:CGRectMake(x, 0, W, H) target:self action:@selector(tappedMenuPanel:) toolInfo:nil];
        view.tag = tag++;
        view.title = obj[@"title"];
        view.iconImage = obj[@"icon"];
        
        switch (view.tag) {
            case 1:
                _textBtn = view;
                break;
            case 2:
                _colorBtn = view;
                _colorBtn.iconView.layer.borderWidth = 2;
                _colorBtn.iconView.layer.borderColor = [[UIColor blackColor] CGColor];
                break;
            case 3:
                _fontBtn = view;
                break;
            case 4:
                _alignLeftBtn = view;
                break;
            case 5:
                _alignCenterBtn = view;
                break;
            case 6:
                _alignRightBtn = view;
                break;
        }
        
        [_menuScroll addSubview:view];
        x += W;
    }
    _menuScroll.contentSize = CGSizeMake(MAX(x, _menuScroll.frame.size.width+1), 0);
}

- (void)tappedMenuPanel:(UITapGestureRecognizer*)sender
{
    UIView *view = sender.view;
    
    switch (view.tag) {
        case 0:
            [self addNewText];
            break;
        case 1:
        case 2:
        case 3:
            [self showSettingViewWithMenuIndex:view.tag-1];
            break;
        case 4:
            [self setTextAlignment:NSTextAlignmentLeft];
            break;
        case 5:
            [self setTextAlignment:NSTextAlignmentCenter];
            break;
        case 6:
            [self setTextAlignment:NSTextAlignmentRight];
            break;
    }
    
    view.alpha = 0.2;
    [UIView animateWithDuration:kCLImageToolAnimationDuration
                     animations:^{
                         view.alpha = 1;
                     }
     ];
}

- (void)addNewText
{
    _CLTextView *view = [[_CLTextView alloc] initWithTool:self];
    view.fillColor = _settingView.selectedFillColor;
    view.borderColor = _settingView.selectedBorderColor;
    view.borderWidth = _settingView.selectedBorderWidth;
    view.font = _settingView.selectedFont;
    
    CGFloat ratio = MIN( (0.8 * _workingView.width) / view.width, (0.2 * _workingView.height) / view.height);
    [view setScale:ratio];
    view.center = CGPointMake(_workingView.width/2, view.height/2 + 10);
    
    [_workingView addSubview:view];
    [_CLTextView setActiveTextView:view];
    
    [self beginTextEditting];
}

- (void)hideSettingView
{
    [_settingView endEditing:YES];
    _settingView.hidden = YES;
}

- (void)showSettingViewWithMenuIndex:(NSInteger)index
{
    if(_settingView.hidden){
        _settingView.hidden = NO;
        [_settingView showSettingMenuWithIndex:index animated:NO];
    }
    else{
        [_settingView showSettingMenuWithIndex:index animated:YES];
    }
}

- (void)beginTextEditting
{
    [self showSettingViewWithMenuIndex:0];
    [_settingView becomeFirstResponder];
}

- (void)setTextAlignment:(NSTextAlignment)alignment
{
    self.selectedTextView.textAlignment = alignment;
    
    _alignLeftBtn.selected = _alignCenterBtn.selected = _alignRightBtn.selected = NO;
    switch (alignment) {
        case NSTextAlignmentLeft:
            _alignLeftBtn.selected = YES;
            break;
        case NSTextAlignmentCenter:
            _alignCenterBtn.selected = YES;
            break;
        case NSTextAlignmentRight:
            _alignRightBtn.selected = YES;
            break;
        default:
            break;
    }
}

- (void)pushedButton:(UIButton*)button
{
    if(_settingView.isFirstResponder){
        [_settingView resignFirstResponder];
    }
    else{
        [self hideSettingView];
    }
}

#pragma mark- Setting view delegate

- (void)textSettingView:(CLTextSettingView *)settingView didChangeText:(NSString *)text
{
    // set text
    self.selectedTextView.text = text;
    [self.selectedTextView sizeToFitWithMaxWidth:0.8*_workingView.width lineHeight:0.2*_workingView.height];
}

- (void)textSettingView:(CLTextSettingView*)settingView didChangeFillColor:(UIColor*)fillColor
{
    _colorBtn.iconView.backgroundColor = fillColor;
    self.selectedTextView.fillColor = fillColor;
}

- (void)textSettingView:(CLTextSettingView*)settingView didChangeBorderColor:(UIColor*)borderColor
{
    _colorBtn.iconView.layer.borderColor = borderColor.CGColor;
    self.selectedTextView.borderColor = borderColor;
}

- (void)textSettingView:(CLTextSettingView*)settingView didChangeBorderWidth:(CGFloat)borderWidth
{
    _colorBtn.iconView.layer.borderWidth = MAX(2, 10*borderWidth);
    self.selectedTextView.borderWidth = borderWidth;
}

- (void)textSettingView:(CLTextSettingView *)settingView didChangeFont:(UIFont *)font
{
    self.selectedTextView.font = font;
    [self.selectedTextView sizeToFitWithMaxWidth:0.8*_workingView.width lineHeight:0.2*_workingView.height];
}

@end



const CGFloat MAX_FONT_SIZE = 50.0;


#pragma mark- _CLTextView

@implementation _CLTextView
{
    CLTextLabel *_label;
    UIButton *_deleteButton;
    CLCircleView *_circleView;
    
    CGFloat _scale;
    CGFloat _arg;
    
    CGPoint _initialPoint;
    CGFloat _initialArg;
    CGFloat _initialScale;
}

+ (void)setActiveTextView:(_CLTextView*)view
{
    static _CLTextView *activeView = nil;
    if(view != activeView){
        [activeView setAvtive:NO];
        activeView = view;
        [activeView setAvtive:YES];
        
        [activeView.superview bringSubviewToFront:activeView];
        
        NSNotification *n = [NSNotification notificationWithName:CLTextViewActiveViewDidChangeNotification object:view userInfo:nil];
        [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:n waitUntilDone:NO];
    }
}

- (id)initWithTool:(CLTextTool*)tool
{
    self = [super initWithFrame:CGRectMake(0, 0, 132, 132)];
    if(self){
        _label = [[CLTextLabel alloc] init];
        [_label setTextColor:[CLImageEditorTheme toolbarTextColor]];
        _label.numberOfLines = 0;
        _label.backgroundColor = [UIColor clearColor];
        _label.layer.borderColor = [[UIColor blackColor] CGColor];
        _label.layer.cornerRadius = 3;
        _label.font = [UIFont systemFontOfSize:MAX_FONT_SIZE];
        _label.minimumScaleFactor = 1/MAX_FONT_SIZE;
        _label.adjustsFontSizeToFitWidth = YES;
        _label.textAlignment = NSTextAlignmentCenter;
        self.text = @"";
        [self addSubview:_label];
        
        CGSize size = [_label sizeThatFits:CGSizeMake(FLT_MAX, FLT_MAX)];
        _label.frame = CGRectMake(16, 16, size.width, size.height);
        self.frame = CGRectMake(0, 0, size.width + 32, size.height + 32);
        
        _deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_deleteButton setImage:[tool imageForKey:kCLTextToolDeleteIconName defaultImageName:@"btn_delete.png"] forState:UIControlStateNormal];
        _deleteButton.frame = CGRectMake(0, 0, 32, 32);
        _deleteButton.center = _label.frame.origin;
        [_deleteButton addTarget:self action:@selector(pushedDeleteBtn:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_deleteButton];
        
        _circleView = [[CLCircleView alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
        _circleView.center = CGPointMake(_label.width + _label.left, _label.height + _label.top);
        _circleView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
        _circleView.radius = 0.7;
        _circleView.color = [UIColor whiteColor];
        _circleView.borderColor = [UIColor blackColor];
        _circleView.borderWidth = 5;
        [self addSubview:_circleView];
        
        _arg = 0;
        [self setScale:1];
        
        [self initGestures];
    }
    return self;
}

- (void)initGestures
{
    _label.userInteractionEnabled = YES;
    [_label addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewDidTap:)]];
    [_label addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(viewDidPan:)]];
    [_circleView addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(circleViewDidPan:)]];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView* view= [super hitTest:point withEvent:event];
    if(view==self){
        return nil;
    }
    return view;
}

#pragma mark- Properties

- (void)setAvtive:(BOOL)active
{
    _deleteButton.hidden = !active;
    _circleView.hidden = !active;
    _label.layer.borderWidth = (active) ? 1/_scale : 0;
}

- (BOOL)active
{
    return !_deleteButton.hidden;
}

- (void)sizeToFitWithMaxWidth:(CGFloat)width lineHeight:(CGFloat)lineHeight
{
    self.transform = CGAffineTransformIdentity;
    _label.transform = CGAffineTransformIdentity;
    
    CGSize size = [_label sizeThatFits:CGSizeMake(width / (15/MAX_FONT_SIZE), FLT_MAX)];
    _label.frame = CGRectMake(16, 16, size.width, size.height);
    
    CGFloat viewW = (_label.width + 32);
    CGFloat viewH = _label.font.lineHeight;
    
    CGFloat ratio = MIN(width / viewW, lineHeight / viewH);
    [self setScale:ratio];
}

- (void)setScale:(CGFloat)scale
{
    _scale = scale;
    
    self.transform = CGAffineTransformIdentity;
    
    _label.transform = CGAffineTransformMakeScale(_scale, _scale);
    
    CGRect rct = self.frame;
    rct.origin.x += (rct.size.width - (_label.width + 32)) / 2;
    rct.origin.y += (rct.size.height - (_label.height + 32)) / 2;
    rct.size.width  = _label.width + 32;
    rct.size.height = _label.height + 32;
    self.frame = rct;
    
    _label.center = CGPointMake(rct.size.width/2, rct.size.height/2);
    
    self.transform = CGAffineTransformMakeRotation(_arg);
    
    _label.layer.borderWidth = 1/_scale;
    _label.layer.cornerRadius = 3/_scale;
}

- (void)setFillColor:(UIColor *)fillColor
{
    _label.textColor = fillColor;
}

- (UIColor*)fillColor
{
    return _label.textColor;
}

- (void)setBorderColor:(UIColor *)borderColor
{
    _label.outlineColor = borderColor;
}

- (UIColor*)borderColor
{
    return _label.outlineColor;
}

- (void)setBorderWidth:(CGFloat)borderWidth
{
    _label.outlineWidth = borderWidth;
}

- (CGFloat)borderWidth
{
    return _label.outlineWidth;
}

- (void)setFont:(UIFont *)font
{
    _label.font = [font fontWithSize:MAX_FONT_SIZE];
}

- (UIFont*)font
{
    return _label.font;
}

- (void)setTextAlignment:(NSTextAlignment)textAlignment
{
    _label.textAlignment = textAlignment;
}

- (NSTextAlignment)textAlignment
{
    return _label.textAlignment;
}

- (void)setText:(NSString *)text
{
    if(![text isEqualToString:_text]){
        _text = text;
        _label.text = (_text.length>0) ? _text : [CLImageEditorTheme localizedString:@"CLTextTool_EmptyText" withDefault:@"Text"];
    }
}

#pragma mark- gesture events

- (void)pushedDeleteBtn:(id)sender
{
    _CLTextView *nextTarget = nil;
    
    const NSInteger index = [self.superview.subviews indexOfObject:self];
    
    for(NSInteger i=index+1; i<self.superview.subviews.count; ++i){
        UIView *view = [self.superview.subviews objectAtIndex:i];
        if([view isKindOfClass:[_CLTextView class]]){
            nextTarget = (_CLTextView*)view;
            break;
        }
    }
    
    if(nextTarget==nil){
        for(NSInteger i=index-1; i>=0; --i){
            UIView *view = [self.superview.subviews objectAtIndex:i];
            if([view isKindOfClass:[_CLTextView class]]){
                nextTarget = (_CLTextView*)view;
                break;
            }
        }
    }
    
    [[self class] setActiveTextView:nextTarget];
    [self removeFromSuperview];
}

- (void)viewDidTap:(UITapGestureRecognizer*)sender
{
    if(self.active){
        NSNotification *n = [NSNotification notificationWithName:CLTextViewActiveViewDidTapNotification object:self userInfo:nil];
        [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:n waitUntilDone:NO];
    }
    [[self class] setActiveTextView:self];
}

- (void)viewDidPan:(UIPanGestureRecognizer*)sender
{
    [[self class] setActiveTextView:self];
    
    CGPoint p = [sender translationInView:self.superview];
    
    if(sender.state == UIGestureRecognizerStateBegan){
        _initialPoint = self.center;
    }
    self.center = CGPointMake(_initialPoint.x + p.x, _initialPoint.y + p.y);
}

- (void)circleViewDidPan:(UIPanGestureRecognizer*)sender
{
    CGPoint p = [sender translationInView:self.superview];
    
    static CGFloat tmpR = 1;
    static CGFloat tmpA = 0;
    if(sender.state == UIGestureRecognizerStateBegan){
        _initialPoint = [self.superview convertPoint:_circleView.center fromView:_circleView.superview];
        
        CGPoint p = CGPointMake(_initialPoint.x - self.center.x, _initialPoint.y - self.center.y);
        tmpR = sqrt(p.x*p.x + p.y*p.y);
        tmpA = atan2(p.y, p.x);
        
        _initialArg = _arg;
        _initialScale = _scale;
    }
    
    p = CGPointMake(_initialPoint.x + p.x - self.center.x, _initialPoint.y + p.y - self.center.y);
    CGFloat R = sqrt(p.x*p.x + p.y*p.y);
    CGFloat arg = atan2(p.y, p.x);
    
    _arg   = _initialArg + arg - tmpA;
    [self setScale:MAX(_initialScale * R / tmpR, 15/MAX_FONT_SIZE)];
}

@end


