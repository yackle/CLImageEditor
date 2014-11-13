//
//  CLResizeTool.m
//
//  Created by sho yakushiji on 2013/12/12.
//  Copyright (c) 2013年 CALACULU. All rights reserved.
//

#import "CLResizeTool.h"

static NSString* const kCLResizeToolPresetSizes = @"presetSizes";
static NSString* const kCLResizeToolLimitSize = @"limitSize";
static NSString* const kCLResizeToolHorizontalIconName = @"horizontalIconAssetsName";
static NSString* const kCLResizeToolVerticalIconName = @"verticalIconAssetsName";
static NSString* const kCLResizeToolChainOnIconName = @"chainOnIconAssetsName";
static NSString* const kCLResizeToolChainOffIconName = @"chainOffIconAssetsName";

@interface _CLResizePanel : UIView
<UITextFieldDelegate>
- (id)initWithFrame:(CGRect)frame originalSize:(CGSize)size tool:(CLResizeTool*)tool;
- (void)setImageWidth:(CGFloat)width;
- (void)setImageHeight:(CGFloat)height;
- (void)setLimitSize:(CGFloat)limit;
- (CGSize)imageSize;
@end


@implementation CLResizeTool
{
    UIImage *_originalImage;
    
    UIView *_menuContainer;
    CLToolbarMenuItem *_switchBtn;
    UIScrollView *_menuScroll;
    _CLResizePanel *_resizePanel;
}

+ (NSArray*)subtools
{
    return nil;
}

+ (NSString*)defaultTitle
{
    return [CLImageEditorTheme localizedString:@"CLResizeTool_DefaultTitle" withDefault:@"Resize"];
}

+ (BOOL)isAvailable
{
    return ([UIDevice iosVersion] >= 5.0);
}

+ (CGFloat)defaultDockedNumber
{
    return 5.5;
}

#pragma mark- optional info

+ (NSArray*)defaultPresetSizes
{
    return @[@240, @320, @480, @640, @800, @960, @1024, @2048];
}

+ (NSNumber*)defaultLimitSize
{
    return @3200;
}

+ (NSDictionary*)optionalInfo
{
    return @{
             kCLResizeToolPresetSizes:[self defaultPresetSizes],
             kCLResizeToolLimitSize:[self defaultLimitSize],
             kCLResizeToolHorizontalIconName:@"",
             kCLResizeToolVerticalIconName:@"",
             kCLResizeToolChainOnIconName:@"",
             kCLResizeToolChainOffIconName:@"",
             };
}

#pragma mark- implementation

- (void)setup
{
    _originalImage = self.editor.imageView.image;
    
    [self.editor fixZoomScaleWithAnimated:YES];
    
    _menuContainer = [[UIView alloc] initWithFrame:self.editor.menuView.frame];
    _menuContainer.backgroundColor = self.editor.menuView.backgroundColor;
    [self.editor.view addSubview:_menuContainer];
    
    _menuScroll = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, _menuContainer.width - 70, _menuContainer.height)];
    _menuScroll.backgroundColor = [UIColor clearColor];
    _menuScroll.showsHorizontalScrollIndicator = NO;
    _menuScroll.clipsToBounds = NO;
    [_menuContainer addSubview:_menuScroll];
    
    UIView *btnPanel = [[UIView alloc] initWithFrame:CGRectMake(_menuScroll.right, 0, 70, _menuContainer.height)];
    btnPanel.backgroundColor = [_menuContainer.backgroundColor colorWithAlphaComponent:0.97];
    [_menuContainer addSubview:btnPanel];
    
    _switchBtn = [CLImageEditorTheme menuItemWithFrame:CGRectMake(0, 0, 70, btnPanel.height) target:self action:@selector(pushedSwitchBtn:) toolInfo:nil];
    _switchBtn.tag = 0;
	
    _switchBtn.iconImage = [self imageForKey:kCLResizeToolHorizontalIconName defaultImageName:@"btn_width.png"];
    [btnPanel addSubview:_switchBtn];
    
    NSNumber *limit = self.toolInfo.optionalInfo[kCLResizeToolLimitSize];
    if(limit==nil){ limit = [self.class defaultLimitSize]; }
    
    _resizePanel = [[_CLResizePanel alloc] initWithFrame:self.editor.imageView.superview.frame originalSize:_originalImage.size tool:self];
    _resizePanel.backgroundColor = [[CLImageEditorTheme toolbarColor] colorWithAlphaComponent:0.4];
    [_resizePanel setLimitSize:limit.floatValue];
    [self.editor.view addSubview:_resizePanel];
    
    [self setResizeMenu];
    
    _menuContainer.transform = CGAffineTransformMakeTranslation(0, self.editor.view.height-_menuScroll.top);
    [UIView animateWithDuration:kCLImageToolAnimationDuration
                     animations:^{
                         _menuContainer.transform = CGAffineTransformIdentity;
                     }];
}

- (void)cleanup
{
    [self.editor resetZoomScaleWithAnimated:YES];
    
    [_resizePanel endEditing:YES];
    [_resizePanel removeFromSuperview];
    
    [UIView animateWithDuration:kCLImageToolAnimationDuration
                     animations:^{
                         _menuContainer.transform = CGAffineTransformMakeTranslation(0, self.editor.view.height-_menuScroll.top);
                     }
                     completion:^(BOOL finished) {
                         [_menuContainer removeFromSuperview];
                     }];
}

- (void)executeWithCompletionBlock:(void (^)(UIImage *, NSError *, NSDictionary *))completionBlock
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        CGSize size = _resizePanel.imageSize;
        
        if(size.width>0 && size.height>0){
            UIImage *image = [_originalImage resize:size];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(image, nil, nil);
            });
        }
        else{
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(nil, nil, nil);
            });
        }
    });
}

#pragma mark-

- (UIImage*)imageWithString:(NSString*)str
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    label.textAlignment = NSTextAlignmentCenter;
    label.text = str;
    label.font = [UIFont boldSystemFontOfSize:30];
    label.minimumScaleFactor = 0.5;
    
    label.backgroundColor = [[CLImageEditorTheme theme] toolbarTextColor];
    label.textColor = [[CLImageEditorTheme theme] toolbarColor];
    
    UIGraphicsBeginImageContextWithOptions(label.frame.size, NO, 0.0);
    [label.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (void)setResizeMenu
{
    CGFloat W = 70;
    CGFloat H = _menuScroll.height;
    CGFloat x = 0;
    
    NSArray *sizes = self.toolInfo.optionalInfo[kCLResizeToolPresetSizes];
    if(sizes==nil || ![sizes isKindOfClass:[NSArray class]] || sizes.count==0){
        sizes = [[self class] defaultPresetSizes];
    }
    
    for(NSNumber *size in sizes){
        CLToolbarMenuItem *view = [CLImageEditorTheme menuItemWithFrame:CGRectMake(x, 0, W, H) target:self action:@selector(tappedResizePanel:) toolInfo:nil];
        view.userInfo = @{@"size":size};
        view.iconImage = [self imageWithString:[NSString stringWithFormat:@"%@", size]];
        
        [_menuScroll addSubview:view];
        x += W;
    }
    _menuScroll.contentSize = CGSizeMake(MAX(x, _menuScroll.frame.size.width+1), 0);
}

- (void)pushedSwitchBtn:(UITapGestureRecognizer*)sender
{
    if(_switchBtn.tag==0){
        _switchBtn.tag = 1;
        _switchBtn.iconImage = [self imageForKey:kCLResizeToolVerticalIconName defaultImageName:@"btn_height.png"];
    }
    else{
        _switchBtn.tag = 0;
        _switchBtn.iconImage = [self imageForKey:kCLResizeToolHorizontalIconName defaultImageName:@"btn_width.png"];
    }
    
    _switchBtn.alpha = 0.2;
    [UIView animateWithDuration:kCLImageToolAnimationDuration
                     animations:^{
                         _switchBtn.alpha = 1;
                     }
     ];
}

- (void)tappedResizePanel:(UITapGestureRecognizer*)sender
{
    UIView *view = sender.view;
    
    NSNumber *size = view.userInfo[@"size"];
    if(size){
        if(_switchBtn.tag==0){
            [_resizePanel setImageWidth:size.floatValue];
        }
        else{
            [_resizePanel setImageHeight:size.floatValue];
        }
    }
    
    view.alpha = 0.2;
    [UIView animateWithDuration:kCLImageToolAnimationDuration
                     animations:^{
                         view.alpha = 1;
                     }
     ];
}

@end





@implementation _CLResizePanel
{
    UIView *_infoPanel;
    CGSize _originalSize;
    
    CGFloat _limitSize;
    UITextField *_fieldW;
    UITextField *_fieldH;
    
    UIButton *_chainBtn;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self){
        _infoPanel = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width*0.85, 180)];
        _infoPanel.backgroundColor = [[CLImageEditorTheme toolbarColor] colorWithAlphaComponent:0.9];
        _infoPanel.layer.cornerRadius = 5;
        _infoPanel.center = CGPointMake(self.width/2, self.height/2);
        _infoPanel.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
        [self addSubview:_infoPanel];
        
        [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewDidTap:)]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyBoardWillChange:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyBoardWillChange:) name:UIKeyboardWillHideNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithFrame:(CGRect)frame originalSize:(CGSize)size tool:(CLResizeTool *)tool
{
    self = [self initWithFrame:frame];
    if(self){
        _originalSize = size;
        [self initInfoPanelWithTool:tool];
    }
    return self;
}

- (void)initInfoPanelWithTool:(CLResizeTool*)tool
{
    UIFont *font = [CLImageEditorTheme toolbarTextFont];
    
    CGFloat y = 0;
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, _infoPanel.width-20, 30)];
	[label setTextColor:[CLImageEditorTheme toolbarTextColor]];
    label.backgroundColor = [UIColor clearColor];
    label.font = [font fontWithSize:17];
    
    label.text = [CLImageEditorTheme localizedString:@"CLResizeTool_InfoPanelTextOriginalSize" withDefault:@"Original Image Size:"];
    [_infoPanel addSubview:label];
    y = label.bottom;
    
    label = [[UILabel alloc] initWithFrame:CGRectMake(10, y, _infoPanel.width-20, 50)];
	[label setTextColor:[CLImageEditorTheme toolbarTextColor]];
    label.backgroundColor = [UIColor clearColor];
    label.font = [font fontWithSize:30];
    label.text = [NSString stringWithFormat:@"%ld x %ld", (long)_originalSize.width, (long)_originalSize.height];
    label.textAlignment = NSTextAlignmentCenter;
    [_infoPanel addSubview:label];
    //y = label.bottom;
    
    label = [[UILabel alloc] initWithFrame:CGRectMake(10, _infoPanel.height/2, _infoPanel.width-20, 30)];
	[label setTextColor:[CLImageEditorTheme toolbarTextColor]];
    label.backgroundColor = [UIColor clearColor];
    label.font = [font fontWithSize:17];
    label.text = [CLImageEditorTheme localizedString:@"CLResizeTool_InfoPanelTextNewSize" withDefault:@"New Image Size:"];
    [_infoPanel addSubview:label];
    y = label.bottom;
    /*
    label = [[UILabel alloc] initWithFrame:CGRectMake(10, y, _infoPanel.width-20, 50)];
    label.backgroundColor = [UIColor clearColor];
    label.font = [font fontWithSize:30];
    label.text = @"x";
    label.textAlignment = NSTextAlignmentCenter;
    [_infoPanel addSubview:label];
    */
    _chainBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _chainBtn.frame = CGRectMake(0, 0, 35, 35);
    _chainBtn.center = CGPointMake(label.center.x, y + 25);
	
    [_chainBtn setImage:[tool imageForKey:kCLResizeToolChainOffIconName defaultImageName:@"btn_chain_off.png"] forState:UIControlStateNormal];
    [_chainBtn setImage:[tool imageForKey:kCLResizeToolChainOnIconName defaultImageName:@"btn_chain_on.png"] forState:UIControlStateSelected];
    [_chainBtn addTarget:self action:@selector(chainBtnDidPush:) forControlEvents:UIControlEventTouchUpInside];
    _chainBtn.selected = YES;
    [_infoPanel addSubview:_chainBtn];
    
    _fieldW = [[UITextField alloc] initWithFrame:CGRectMake(_chainBtn.left - 110, y+5, 100, 40)];
	[_fieldW setTextColor:[CLImageEditorTheme toolbarTextColor]];
    _fieldW.font = [font fontWithSize:30];
    _fieldW.textAlignment = NSTextAlignmentCenter;
    _fieldW.keyboardType = UIKeyboardTypeNumberPad;
    _fieldW.layer.borderWidth = 1;
    _fieldW.layer.borderColor = [[[CLImageEditorTheme theme] toolbarTextColor] CGColor];
    _fieldW.text = [NSString stringWithFormat:@"%ld", (long)_originalSize.width];
    _fieldW.delegate = self;
    [_fieldW addTarget:self action:@selector(textFieldDidChanged:) forControlEvents:UIControlEventEditingChanged];
    [_infoPanel addSubview:_fieldW];
    
    _fieldH = [[UITextField alloc] initWithFrame:CGRectMake(_chainBtn.right + 10, y+5, 100, 40)];
	[_fieldH setTextColor:[CLImageEditorTheme toolbarTextColor]];
    _fieldH.font = [font fontWithSize:30];
    _fieldH.textAlignment = NSTextAlignmentCenter;
    _fieldH.keyboardType = UIKeyboardTypeNumberPad;
    _fieldH.layer.borderWidth = 1;
    _fieldH.layer.borderColor = _fieldW.layer.borderColor;
    _fieldH.text = [NSString stringWithFormat:@"%ld", (long)_originalSize.height];
    _fieldH.delegate = self;
    [_fieldH addTarget:self action:@selector(textFieldDidChanged:) forControlEvents:UIControlEventEditingChanged];
    [_infoPanel addSubview:_fieldH];
}

#pragma mark - gesture events

- (void)viewDidTap:(UITapGestureRecognizer*)sender
{
    [self endEditing:YES];
}

- (void)chainBtnDidPush:(UIButton*)sender
{
    sender.selected = !sender.selected;
    
    CGFloat W = _fieldW.text.floatValue;
    CGFloat H = _fieldH.text.floatValue;
    if(W>H){
        [self setImageWidth:W];
    }
    else{
        [self setImageHeight:H];
    }
}

#pragma mark - keyboard events

- (void)keyBoardWillChange:(NSNotification *)notificatioin
{
    CGRect keyboardFrame = [[notificatioin.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    keyboardFrame = [self.superview convertRect:keyboardFrame fromView:self.window];
    
    UIViewAnimationCurve animationCurve = [[notificatioin.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    double duration = [[notificatioin.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    [UIView animateWithDuration:duration
                          delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState | (animationCurve<<16)
                     animations:^{
                         CGFloat H = MIN(self.height, keyboardFrame.origin.y - self.top);
                         _infoPanel.center = CGPointMake(_infoPanel.center.x, H/2);
                     } completion:^(BOOL finished) {
                         
                     }
     ];
}

#pragma mark- Size settings

- (void)setLimitSize:(CGFloat)limit
{
    _limitSize = limit;
    [self setImageWidth:_fieldW.text.floatValue];
}

- (void)setImageWidth:(CGFloat)width
{
    width = MIN(width, _limitSize);
    
    if(_chainBtn.selected){
        if(width>0){
            CGFloat height = MAX(1, width * _originalSize.height / _originalSize.width);
            
            if(height>_limitSize){
                [self setImageHeight:_limitSize];
            }
            else{
                _fieldW.text = [NSString stringWithFormat:@"%ld", (long)width];
                _fieldH.text = [NSString stringWithFormat:@"%ld", (long)height];
            }
        }
        else{
            _fieldH.text = @"";
        }
    }
    else if(width>0){
        _fieldW.text = [NSString stringWithFormat:@"%ld", (long)width];
    }
}

- (void)setImageHeight:(CGFloat)height
{
    height = MIN(height, _limitSize);
    
    if(_chainBtn.selected){
        if(height>0){
            CGFloat width = MAX(1, height * _originalSize.width / _originalSize.height);
            
            if(width>_limitSize){
                [self setImageWidth:_limitSize];
            }
            else{
                _fieldW.text = [NSString stringWithFormat:@"%ld", (long)width];
                _fieldH.text = [NSString stringWithFormat:@"%ld", (long)height];
            }
        }
        else{
            _fieldW.text = @"";
        }
    }
    else if(height>0){
        _fieldH.text = [NSString stringWithFormat:@"%ld", (long)height];
    }
}

- (void)textFieldDidChanged:(id)sender
{
    if(sender==_fieldW){
        [self setImageWidth:_fieldW.text.floatValue];
    }
    else if(sender==_fieldH){
        [self setImageHeight:_fieldH.text.floatValue];
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if(textField==_fieldW || textField==_fieldH){
        if((string != nil) && (![@"" isEqualToString:string])){
            const char *c = [string cStringUsingEncoding:NSASCIIStringEncoding];
            if(c[0]==0){ return YES; }
            else if([textField.text length]>=4){ return NO; }
            else {return [self isNumber:string]; }
        }
    }
    return YES;
}

- (BOOL)isNumber:(NSString *)value
{
    if(value == nil || [@"" isEqualToString:value]){ return NO; }
    
    BOOL isNum = NO;
    
    for(int i=0; i<[value length]; i++){
        NSString *str = [[value substringFromIndex:i] substringToIndex:1];
        
        const char *c = [str cStringUsingEncoding:NSASCIIStringEncoding];
        isNum = ((c!=NULL)&&(c[0]>=0x30)&&(c[0]<=0x39));
        
        if(_fieldW.text.length==0 && i==0 && (c!=NULL&&c[0]==0x30)){ isNum = NO; }
        
        if(!isNum){ break; }
    }
    
    return isNum;
}

- (CGSize)imageSize
{
    return CGSizeMake(_fieldW.text.floatValue, _fieldH.text.floatValue);
}

@end

