//
//  CLPickerView.h
//
//  Created by sho yakushiji on 2013/12/15.
//  Copyright (c) 2013年 CALACULU. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CLPickerViewDataSource;
@protocol CLPickerViewDelegate;


@interface CLPickerView : UIView

@property (nonatomic, weak) id<CLPickerViewDataSource> dataSource;
@property (nonatomic, weak) id<CLPickerViewDelegate> delegate;
@property (nonatomic, strong) UIColor *foregroundColor;

- (void)reloadComponent:(NSInteger)component;
- (void)selectRow:(NSInteger)row inComponent:(NSInteger)component animated:(BOOL)animated;
- (NSInteger)selectedRowInComponent:(NSInteger)component;

@end





@protocol CLPickerViewDataSource <NSObject>
@required
- (NSInteger)numberOfComponentsInPickerView:(CLPickerView *)pickerView;
- (NSInteger)pickerView:(CLPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component;

@end


@protocol CLPickerViewDelegate <NSObject>
@optional
- (CGFloat)pickerView:(CLPickerView *)pickerView widthForComponent:(NSInteger)component;
- (NSString *)pickerView:(CLPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component;
- (UIView *)pickerView:(CLPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view;
- (CGFloat)pickerView:(CLPickerView *)pickerView rowHeightForComponent:(NSInteger)component;

- (void)pickerView:(CLPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component;

@end
