//
//  CLImageEditorTheme+Private.m
//
//  Created by sho yakushiji on 2013/12/07.
//  Copyright (c) 2013年 CALACULU. All rights reserved.
//

#import "CLImageEditorTheme+Private.h"

#import "CLImageEditor.h"
#import "UIImage+Utility.h"

@implementation CLImageEditorTheme (Private)

#pragma mark- instance methods

- (NSBundle*)bundle
{
    NSString *path = [[NSBundle mainBundle] pathForResource:self.bundleName ofType:@"bundle"];
    if(path){
        return [NSBundle bundleWithPath:path];
    }
    
    path = [[NSBundle bundleForClass:self.class] pathForResource:self.bundleName ofType:@"bundle"];
    if(path){
        return [NSBundle bundleWithPath:path];
    }
    return nil;
}

#pragma mark- class methods

+ (NSString*)bundleName
{
    return self.theme.bundleName;
}

+ (NSBundle*)bundle
{
    return self.theme.bundle;
}

+ (UIImage*)imageNamed:(Class)path image:(NSString*)image
{
    CLImageEditorTheme *theme = [CLImageEditorTheme theme];
    NSString *imagePath = [self.bundle.bundlePath stringByAppendingString:[NSString stringWithFormat:@"/%@/%@/%@", path, theme.toolIconColor, image]];
    
    return [UIImage fastImageWithContentsOfFile:imagePath];
}

+ (NSString*)localizedString:(NSString*)key withDefault:defaultValue
{
    NSString *str = NSLocalizedString(key, @"");
    if(![str isEqualToString:key]){ return str; }
    return NSLocalizedStringWithDefaultValue(key, nil, [CLImageEditorTheme bundle], defaultValue, @"");
}

#pragma mark color settings

+ (UIColor*)backgroundColor
{
    return self.theme.backgroundColor;
}

+ (UIColor*)toolbarColor
{
    return self.theme.toolbarColor;
}

+ (UIColor*)toolbarTextColor
{
    return self.theme.toolbarTextColor;
}

+ (UIColor*)toolbarSelectedButtonColor
{
    return self.theme.toolbarSelectedButtonColor;
}

#pragma mark font settings

+ (UIFont*)toolbarTextFont
{
    return self.theme.toolbarTextFont;
}

#pragma mark UI components

+ (UIActivityIndicatorView*)indicatorView
{
    if([self.theme.delegate respondsToSelector:@selector(imageEditorThemeActivityIndicatorView)]){
        return [self.theme.delegate imageEditorThemeActivityIndicatorView];
    }
    
    // default indicator view
    UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 80, 80)];
    indicatorView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6];
    indicatorView.layer.cornerRadius = 5;
    indicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    
    return indicatorView;
}

+ (CLToolbarMenuItem*)menuItemWithFrame:(CGRect)frame target:(id)target action:(SEL)action toolInfo:(CLImageToolInfo*)toolInfo;
{
    return [[CLToolbarMenuItem alloc] initWithFrame:frame target:target action:action toolInfo:toolInfo];
}

@end
