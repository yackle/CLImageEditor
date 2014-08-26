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

@property (nonatomic, readonly) CGFloat hueComponent;
@property (nonatomic, readonly) CGFloat saturationComponent;
@property (nonatomic, readonly) CGFloat brightnessComponent;
@property (nonatomic, readonly) CGFloat alphaComponent;

- (void)setColorWithHue:(CGFloat)hue saturation:(CGFloat)saturation brightness:(CGFloat)brightness alpha:(CGFloat)alpha;

@end




@protocol CLColorPickerViewDelegate <NSObject>
@optional
- (void)colorPickerView:(CLColorPickerView*)picker colorDidChange:(UIColor*)color;

@end