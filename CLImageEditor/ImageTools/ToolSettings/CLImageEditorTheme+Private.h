//
//  CLImageEditorTheme+Private.h
//
//  Created by sho yakushiji on 2013/12/07.
//  Copyright (c) 2013年 CALACULU. All rights reserved.
//

#import "CLImageEditorTheme.h"

#import "CLToolbarMenuItem.h"

@interface CLImageEditorTheme (Private)

+ (NSString*)bundleName;
+ (NSBundle*)bundle;
+ (UIImage*)imageNamed:(Class)path image:(NSString*)image;

+ (UIColor*)backgroundColor;
+ (UIColor*)toolbarColor;
+ (UIColor*)toolbarTextColor;
+ (UIColor*)toolbarSelectedButtonColor;

+ (UIFont*)toolbarTextFont;

+ (UIActivityIndicatorView*)indicatorView;
+ (CLToolbarMenuItem*)menuItemWithFrame:(CGRect)frame target:(id)target action:(SEL)action toolInfo:(CLImageToolInfo*)toolInfo;

@end
