//
//  CLImageEditorTheme.h
//
//  Created by sho yakushiji on 2013/12/05.
//  Copyright (c) 2013年 CALACULU. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@protocol CLImageEditorThemeDelegate;

@interface CLImageEditorTheme : NSObject

@property (nonatomic, weak) id<CLImageEditorThemeDelegate> delegate;
@property (nonatomic, strong) NSString *bundleName;
@property (nonatomic, strong) UIColor  *backgroundColor;
@property (nonatomic, strong) UIColor  *toolbarColor;
@property (nonatomic, strong) NSString *navigationDoneButtonText;
@property (nonatomic, strong) NSString *navigationCancelButtonText;
@property (nonatomic, strong) NSString *navigationBackButtonText;
@property (nonatomic, strong) NSString *navigationApplyButtonText;
@property (nonatomic, strong) UIFont *navigationButtonsFont;
@property (nonatomic, strong) UIFont *navigationTitleFont;
@property (nonatomic, strong) UIColor *navigationTextColor;
@property (nonatomic, strong) UIColor *navigationTitleColor;
@property (nonatomic, strong) NSString *toolIconColor;
@property (nonatomic, strong) UIColor  *toolbarTextColor;
@property (nonatomic, strong) UIColor  *toolbarSelectedButtonColor;
@property (nonatomic, strong) UIFont   *toolbarTextFont;
@property (nonatomic, assign) UIStatusBarStyle statusBarStyle;

+ (CLImageEditorTheme*)theme;

@end


@protocol CLImageEditorThemeDelegate <NSObject>
@optional
- (UIActivityIndicatorView*)imageEditorThemeActivityIndicatorView;

@end
