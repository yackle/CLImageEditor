//
//  CLColorPickerView.h
//
//  Created by sho yakushiji on 2013/12/13.
//  Copyright (c) 2013年 CALACULU. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CLColorPickerViewDelegate;

@interface CLColorPickerView : UIView

@property (nonatomic, weak) id<CLColorPickerViewDelegate> delegate;
@property (nonatomic, strong) UIColor *color;

@property (nonatomic, readonly) CGFloat hue;
@property (nonatomic, readonly) CGFloat saturation;
@property (nonatomic, readonly) CGFloat brightness;
@property (nonatomic, readonly) CGFloat alpha;

- (void)setColorWithHue:(CGFloat)hue saturation:(CGFloat)saturation brightness:(CGFloat)brightness alpha:(CGFloat)alpha;

@end




@protocol CLColorPickerViewDelegate <NSObject>
@optional
- (void)colorPickerView:(CLColorPickerView*)picker colorDidChange:(UIColor*)color;

@end