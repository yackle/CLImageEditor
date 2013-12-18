//
//  CLTextSettingView.m
//
//  Created by sho yakushiji on 2013/12/18.
//  Copyright (c) 2013年 CALACULU. All rights reserved.
//

#import "CLTextSettingView.h"

#import "UIView+Frame.h"
#import "CLImageEditorTheme.h"
#import "CLColorPickerView.h"
#import "CLFontPickerView.h"


@interface CLTextSettingView()
<CLColorPickerViewDelegate, CLFontPickerViewDelegate, UITextViewDelegate>
@end


@implementation CLTextSettingView
{
    UIScrollView *_scrollView;
    
    UITextView *_textView;
    CLColorPickerView *_colorPickerView;
    CLFontPickerView *_fontPickerView;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self customInit];
    }
    return self;
}

- (void)customInit
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyBoardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyBoardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    _scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
    _scrollView.pagingEnabled = YES;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.scrollEnabled = NO;
    [self addSubview:_scrollView];
    
    _textView = [[UITextView alloc] initWithFrame:CGRectMake(10, 0, self.width-42, 80)];
    _textView.delegate = self;
    _textView.backgroundColor = [UIColor clearColor];
    [_scrollView addSubview:_textView];
    
    _colorPickerView = [CLColorPickerView new];
    _colorPickerView.delegate = self;
    _colorPickerView.center = CGPointMake(self.width/2 + _textView.right, self.height/2);
    [_scrollView addSubview:_colorPickerView];
    
    _fontPickerView = [[CLFontPickerView alloc] initWithFrame:CGRectMake(self.width * 2, 0, self.width, self.height)];
    _fontPickerView.delegate = self;
    _fontPickerView.sizeComponentHidden = YES;
    [_scrollView addSubview:_fontPickerView];
    
    _scrollView.contentSize = CGSizeMake(self.width * 3, self.height);
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setTextColor:(UIColor*)textColor
{
    _fontPickerView.textColor = textColor;
    _textView.textColor = textColor;
}

- (BOOL)isFirstResponder
{
    return _textView.isFirstResponder;
}

- (BOOL)becomeFirstResponder
{
    return [_textView becomeFirstResponder];
}

- (BOOL)resignFirstResponder
{
    return [_textView resignFirstResponder];
}

#pragma mark - Properties

- (void)setSelectedText:(NSString *)selectedText
{
    _textView.text = selectedText;
}

- (NSString*)selectedText
{
    return _textView.text;
}

- (void)setSelectedColor:(UIColor *)selectedColor
{
    _colorPickerView.color = selectedColor;
}

- (UIColor*)selectedColor
{
    return _colorPickerView.color;
}

- (void)setSelectedFont:(UIFont *)selectedFont
{
    _fontPickerView.font = selectedFont;
}

- (UIFont*)selectedFont
{
    return _fontPickerView.font;
}

- (void)setFontPickerForegroundColor:(UIColor*)foregroundColor
{
    _fontPickerView.foregroundColor = foregroundColor;
}

- (void)showSettingMenuWithIndex:(NSInteger)index animated:(BOOL)animated
{
    [_scrollView setContentOffset:CGPointMake(index * self.width, 0) animated:animated];
}

#pragma mark - keyboard events

- (void)keyBoardWillShow:(NSNotification *)notificatioin
{
    [self keyBoardWillChange:notificatioin withTextViewHeight:80];
    [_textView scrollRangeToVisible:_textView.selectedRange];
}

- (void)keyBoardWillHide:(NSNotification *)notificatioin
{
    [self keyBoardWillChange:notificatioin withTextViewHeight:self.height - 20];
}

- (void)keyBoardWillChange:(NSNotification *)notificatioin withTextViewHeight:(CGFloat)height
{
    CGRect keyboardFrame = [[notificatioin.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    keyboardFrame = [self.superview convertRect:keyboardFrame fromView:self.window];
    
    UIViewAnimationCurve animationCurve = [[notificatioin.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    double duration = [[notificatioin.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    [UIView animateWithDuration:duration
                          delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState | (animationCurve<<16)
                     animations:^{
                         _textView.height = height;
                         CGFloat dy = MIN(0, (keyboardFrame.origin.y - _textView.height) - self.top);
                         self.transform = CGAffineTransformMakeTranslation(0, dy);
                     } completion:^(BOOL finished) {
                         
                     }
     ];
}

#pragma mark- Color picker delegate
- (void)colorPickerView:(CLColorPickerView *)picker colorDidChange:(UIColor *)color
{
    if([self.delegate respondsToSelector:@selector(textSettingView:didChangeTextColor:)]){
        [self.delegate textSettingView:self didChangeTextColor:color];
    }
}

#pragma mark- Font picker delegate

- (void)fontPickerView:(CLFontPickerView *)pickerView didSelectFont:(UIFont *)font
{
    if([self.delegate respondsToSelector:@selector(textSettingView:didChangeFont:)]){
        [self.delegate textSettingView:self didChangeFont:font];
    }
}

#pragma mark- UITextView delegate

- (void)textViewDidChange:(UITextView*)textView
{
    NSRange selection = textView.selectedRange;
    if(selection.location+selection.length == textView.text.length && [textView.text characterAtIndex:textView.text.length-1] == '\n') {
        [textView layoutSubviews];
        [textView scrollRectToVisible:CGRectMake(0, textView.contentSize.height - 1, 1, 1) animated:YES];
    }
    else {
        [textView scrollRangeToVisible:textView.selectedRange];
    }
    
    if([self.delegate respondsToSelector:@selector(textSettingView:didChangeText:)]){
        [self.delegate textSettingView:self didChangeText:textView.text];
    }
}

@end
