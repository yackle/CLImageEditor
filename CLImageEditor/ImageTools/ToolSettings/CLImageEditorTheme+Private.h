//
//  CLImageEditorTheme+Private.h
//
//  Created by sho yakushiji on 2013/12/07.
//  Copyright (c) 2013年 CALACULU. All rights reserved.
//

#import "CLImageEditorTheme.h"

#import "UIView+CLImageToolInfo.h"

@interface CLImageEditorTheme (Private)

+ (NSString*)bundleName;
+ (NSBundle*)bundle;
+ (UIImage*)imageNamed:(NSString*)path;

+ (UIColor*)backgroundColor;
+ (UIColor*)toolbarColor;
+ (UIColor*)toolbarTextColor;
+ (UIColor*)toolbarSelectedButtonColor;

+ (UIFont*)toolbarTextFont;

+ (UIActivityIndicatorView*)indicatorView;

@end
