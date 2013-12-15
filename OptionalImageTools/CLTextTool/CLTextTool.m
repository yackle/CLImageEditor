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

static NSString* const CLTextViewActiveViewDidChangeNotification = @"CLTextViewActiveViewDidChangeNotificationString";


@interface _CLTextView : UIView
@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) UIFont *font;
@property (nonatomic, strong) UIColor *color;
@property (nonatomic, assign) NSTextAlignment textAlignment;

+ (void)setActiveTextView:(_CLTextView*)view;
- (void)setScale:(CGFloat)scale;

@end



@interface CLToolbarMenuItem(Private)
- (UIImageView*)iconView;
@end

@implementation CLToolbarMenuItem(Private)
- (UIImageView*)iconView{ return _iconView; }
@end


@interface CLTextTool()
<CLColorPickerViewDelegate, CLFontPickerViewDelegate>
@property (nonatomic, strong) _CLTextView *selectedTextView;
@end

@implementation CLTextTool
{
    UIImage *_originalImage;
    
    UIView *_workingView;
    
    UIView *_pickerView;
    CLColorPickerView *_colorPickerView;
    CLFontPickerView *_fontPickerView;
    
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
    return NSLocalizedStringWithDefaultValue(@"CLTextTool_DefaultTitle", nil, [CLImageEditorTheme bundle], @"Text", @"");
}

+ (BOOL)isAvailable
{
    return ([UIDevice iosVersion] >= 5.0);
}

+ (CGFloat)defaultDockedNumber
{
    return 8;
}

#pragma mark- implementation

- (void)setup
{
    _originalImage = self.editor.imageView.image;
    
    [self.editor fixZoomScaleWithAnimated:YES];
    
    
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyBoardWillChange:) name:UIKeyboardWillShowNotification object:nil];
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyBoardWillChange:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activeTextViewDidChange:) name:CLTextViewActiveViewDidChangeNotification object:nil];
    
    _menuScroll = [[UIScrollView alloc] initWithFrame:self.editor.menuView.frame];
    _menuScroll.backgroundColor = self.editor.menuView.backgroundColor;
    _menuScroll.showsHorizontalScrollIndicator = NO;
    [self.editor.view addSubview:_menuScroll];
    
    _workingView = [[UIView alloc] initWithFrame:[self.editor.view convertRect:self.editor.imageView.frame fromView:self.editor.imageView.superview]];
    _workingView.clipsToBounds = YES;
    [self.editor.view addSubview:_workingView];
    
    _pickerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.editor.view.width, 180)];
    _pickerView.top = _menuScroll.top - _pickerView.height;
    _pickerView.backgroundColor = self.editor.menuView.backgroundColor;
    _pickerView.hidden = YES;
    [self.editor.view addSubview:_pickerView];
    
    _colorPickerView = [CLColorPickerView new];
    _colorPickerView.delegate = self;
    _colorPickerView.center = CGPointMake(_pickerView.width/2, _pickerView.height/2);
    _colorPickerView.hidden = YES;
    [_pickerView addSubview:_colorPickerView];
    
    _fontPickerView = [[CLFontPickerView alloc] initWithFrame:_pickerView.bounds];
    _fontPickerView.delegate = self;
    _fontPickerView.center = _colorPickerView.center;
    _fontPickerView.sizeComponentHidden = YES;
    _fontPickerView.foregroundColor = self.editor.menuView.backgroundColor;
    _fontPickerView.hidden = YES;
    _fontPickerView.textColor = [CLImageEditorTheme toolbarTextColor];
    [_pickerView addSubview:_fontPickerView];
    
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
    
    [_pickerView endEditing:YES];
    [_workingView removeFromSuperview];
    [_pickerView removeFromSuperview];
    
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
    UIGraphicsBeginImageContext(image.size);
    
    [image drawAtPoint:CGPointZero];
    
    CGFloat scale = image.size.width / _workingView.width;
    CGContextScaleCTM(UIGraphicsGetCurrentContext(), scale, scale);
    [_workingView.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage *tmp = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return tmp;
}

- (void)setSelectedTextView:(_CLTextView *)selectedTextView
{
    if(selectedTextView != _selectedTextView){
        _selectedTextView = selectedTextView;
    }
    
    if(_selectedTextView==nil){
        _textBtn.userInteractionEnabled = NO;
        _colorBtn.userInteractionEnabled = NO;
        _fontBtn.userInteractionEnabled = NO;;
        _alignLeftBtn.userInteractionEnabled = NO;
        _alignCenterBtn.userInteractionEnabled = NO;
        _alignRightBtn.userInteractionEnabled = NO;
        
        _colorBtn.iconView.backgroundColor = _colorPickerView.color;
        _alignLeftBtn.backgroundColor = [UIColor clearColor];
        _alignCenterBtn.backgroundColor = [UIColor clearColor];
        _alignRightBtn.backgroundColor = [UIColor clearColor];
    }
    else{
        _textBtn.userInteractionEnabled = YES;
        _colorBtn.userInteractionEnabled = YES;
        _fontBtn.userInteractionEnabled = YES;
        _alignLeftBtn.userInteractionEnabled = YES;
        _alignCenterBtn.userInteractionEnabled = YES;
        _alignRightBtn.userInteractionEnabled = YES;
        
        _colorBtn.iconView.backgroundColor = selectedTextView.color;
        
        _colorPickerView.color = selectedTextView.color;
        _fontPickerView.font = selectedTextView.font;
    }
}

- (void)activeTextViewDidChange:(NSNotification*)notification
{
    self.selectedTextView = notification.object;
}

- (void)setMenu
{
    CGFloat W = 70;
    CGFloat H = _menuScroll.height;
    CGFloat x = 0;
    
    NSArray *_menu = @[
                       @{@"title":NSLocalizedStringWithDefaultValue(@"CLTextTool_MenuItemNew", nil, [CLImageEditorTheme bundle], @"New", @""), @"icon":[CLImageEditorTheme imageNamed:[NSString stringWithFormat:@"%@/btn_add.png", [self class]]]},
                       @{@"title":NSLocalizedStringWithDefaultValue(@"CLTextTool_MenuItemText", nil, [CLImageEditorTheme bundle], @"Text", @""), @"icon":[CLImageEditorTheme imageNamed:[NSString stringWithFormat:@"%@/icon.png", [self class]]]},
                       @{@"title":NSLocalizedStringWithDefaultValue(@"CLTextTool_MenuItemColor", nil, [CLImageEditorTheme bundle], @"Color", @"")},
                       @{@"title":NSLocalizedStringWithDefaultValue(@"CLTextTool_MenuItemFont", nil, [CLImageEditorTheme bundle], @"Font", @""), @"icon":[CLImageEditorTheme imageNamed:[NSString stringWithFormat:@"%@/btn_font.png", [self class]]]},
                       @{@"title":NSLocalizedStringWithDefaultValue(@"CLTextTool_MenuItemAlignLeft", nil, [CLImageEditorTheme bundle], @" ", @""), @"icon":[CLImageEditorTheme imageNamed:[NSString stringWithFormat:@"%@/btn_align_left.png", [self class]]]},
                       @{@"title":NSLocalizedStringWithDefaultValue(@"CLTextTool_MenuItemAlignCenter", nil, [CLImageEditorTheme bundle], @" ", @""), @"icon":[CLImageEditorTheme imageNamed:[NSString stringWithFormat:@"%@/btn_align_center.png", [self class]]]},
                       @{@"title":NSLocalizedStringWithDefaultValue(@"CLTextTool_MenuItemAlignRight", nil, [CLImageEditorTheme bundle], @" ", @""), @"icon":[CLImageEditorTheme imageNamed:[NSString stringWithFormat:@"%@/btn_align_right.png", [self class]]]},
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
            [self showTextView];
            break;
        case 2:
            [self showColorPicker];
            break;
        case 3:
            [self showFontPicker];
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
    _CLTextView *view = [_CLTextView new];
    view.color = _colorPickerView.color;
    view.font = _fontPickerView.font;
    
    CGFloat ratio = MIN( (0.8 * _workingView.width) / view.width, (0.2 * _workingView.height) / view.height);
    [view setScale:ratio];
    view.center = CGPointMake(_workingView.width/2, view.height/2 + 10);
    
    [_workingView addSubview:view];
    [_CLTextView setActiveTextView:view];
}

- (void)hidePickerPanel
{
    [_pickerView endEditing:YES];
    _pickerView.hidden = YES;
    _colorPickerView.hidden = YES;
    _fontPickerView.hidden = YES;
}

- (void)showTextView
{
    
}

- (void)showColorPicker
{
    if(_colorPickerView.hidden){
        _pickerView.hidden = NO;
        _colorPickerView.hidden = NO;
        _fontPickerView.hidden = YES;
    }
    else{
        [self hidePickerPanel];
    }
}

- (void)showFontPicker
{
    if(_fontPickerView.hidden){
        _pickerView.hidden = NO;
        _colorPickerView.hidden = YES;
        _fontPickerView.hidden = NO;
    }
    else{
        [self hidePickerPanel];
    }
}

- (void)setTextAlignment:(NSTextAlignment)alignment
{
    self.selectedTextView.textAlignment = alignment;
}

#pragma mark- Color picker delegate

- (void)colorPickerView:(CLColorPickerView *)picker colorDidChange:(UIColor *)color
{
    _colorBtn.iconView.backgroundColor = color;
    self.selectedTextView.color = color;
}

#pragma mark- Font picker delegate

- (void)fontPickerView:(CLFontPickerView *)pickerView didSelectFont:(UIFont *)font
{
    self.selectedTextView.font = font;
}

@end





@implementation _CLTextView
{
    UILabel *_label;
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

- (id)init
{
    self = [super initWithFrame:CGRectMake(0, 0, 132, 132)];
    if(self){
        _label = [[UILabel alloc] init];
        _label.numberOfLines = 0;
        _label.backgroundColor = [UIColor clearColor];
        _label.layer.borderColor = [[UIColor blackColor] CGColor];
        _label.layer.cornerRadius = 3;
        _label.font = [UIFont systemFontOfSize:1000];
        _label.minimumScaleFactor = 1/1000.0;
        _label.adjustsFontSizeToFitWidth = YES;
        _label.textAlignment = NSTextAlignmentCenter;
        self.text = @"";
        [self addSubview:_label];
        
        CGSize size = [_label sizeThatFits:CGSizeMake(FLT_MAX, FLT_MAX)];
        _label.frame = CGRectMake(16, 16, size.width, size.height);
        self.frame = CGRectMake(0, 0, size.width + 32, size.height + 32);
        
        _deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_deleteButton setImage:[CLImageEditorTheme imageNamed:@"CLTextTool/btn_delete.png"] forState:UIControlStateNormal];
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

- (void)setColor:(UIColor *)color
{
    _label.textColor = color;
}

- (UIColor*)color
{
    return _label.textColor;
}

- (void)setFont:(UIFont *)font
{
    CGFloat width = _label.width;
    
    _label.font = [font fontWithSize:1000];
    
    self.transform = CGAffineTransformIdentity;
    _label.transform = CGAffineTransformIdentity;
    
    CGSize size = [_label sizeThatFits:CGSizeMake(FLT_MAX, FLT_MAX)];
    _label.frame = CGRectMake(16, 16, size.width, size.height);
    
    [self setScale:(width/_label.width)];
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
        _label.text = (_text.length>0) ? _text : NSLocalizedStringWithDefaultValue(@"CLTextTool_EmptyText", nil, [CLImageEditorTheme bundle], @"Text", @"");
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
    [self setScale:MAX(_initialScale * R / tmpR, 20/1000.0)];
}

@end


