//
//  CLTextSettingView.h
//
//  Created by sho yakushiji on 2013/12/18.
//  Copyright (c) 2013年 CALACULU. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CLTextSettingViewDelegate;

@interface CLTextSettingView : UIView

@property (nonatomic, weak) id<CLTextSettingViewDelegate> delegate;
@property (nonatomic, strong) NSString *selectedText;
@property (nonatomic, strong) UIColor *selectedColor;
@property (nonatomic, strong) UIFont *selectedFont;


- (void)setTextColor:(UIColor*)textColor;
- (void)setFontPickerForegroundColor:(UIColor*)foregroundColor;

- (void)showSettingMenuWithIndex:(NSInteger)index animated:(BOOL)animated;

@end



@protocol CLTextSettingViewDelegate <NSObject>
@optional
- (void)textSettingView:(CLTextSettingView*)settingView didChangeText:(NSString*)text;
- (void)textSettingView:(CLTextSettingView*)settingView didChangeTextColor:(UIColor*)textColor;
- (void)textSettingView:(CLTextSettingView*)settingView didChangeFont:(UIFont*)font;

@end