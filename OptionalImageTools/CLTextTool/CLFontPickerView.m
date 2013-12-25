//
//  CLFontPickerView.m
//
//  Created by sho yakushiji on 2013/12/14.
//  Copyright (c) 2013年 CALACULU. All rights reserved.
//

#import "CLFontPickerView.h"

#import "UIView+Frame.h"
#import "CLPickerView.h"

const CGFloat kCLFontPickerViewConstantFontSize = 14;

@interface CLFontPickerView()
<CLPickerViewDelegate, CLPickerViewDataSource>
@end

@implementation CLFontPickerView
{
    CLPickerView *_pickerView;
}

+ (NSArray*)allFontList
{
    NSMutableArray *list = [NSMutableArray array];
    
    for(NSString *familyName in [UIFont familyNames]){
        for(NSString *fontName in [UIFont fontNamesForFamilyName:familyName]){
            [list addObject:[UIFont fontWithName:fontName size:kCLFontPickerViewConstantFontSize]];
        }
    }
    
    return [list sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"fontName" ascending:YES]]];
}

+ (NSArray*)defaultSizes
{
    return @[@8, @10, @12, @14, @16, @18, @20, @24, @28, @32, @38, @44, @50];
}

+ (UIFont*)defaultFont
{
    return [UIFont fontWithName:@"HiraKakuProN-W3"size:kCLFontPickerViewConstantFontSize];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.clipsToBounds = YES;
        
        _pickerView = [[CLPickerView alloc] initWithFrame:self.bounds];
        _pickerView.center = CGPointMake(self.width/2, self.height/2);
        _pickerView.backgroundColor = [UIColor clearColor];
        _pickerView.dataSource = self;
        _pickerView.delegate = self;
        [self addSubview:_pickerView];
        
        self.fontList = [self.class allFontList];
        self.fontSizes = [self.class defaultSizes];
        self.font = [self.class defaultFont];
        self.foregroundColor = [UIColor colorWithWhite:1 alpha:0.8];
        self.textColor = [UIColor blackColor];
    }
    return self;
}

- (void)setForegroundColor:(UIColor *)foregroundColor
{
    _pickerView.foregroundColor = foregroundColor;
}

- (UIColor*)foregroundColor
{
    return _pickerView.foregroundColor;
}

- (void)setFontList:(NSArray *)fontList
{
    if(fontList != _fontList){
        _fontList = fontList;
        [_pickerView reloadComponent:0];
    }
}

- (void)setFontSizes:(NSArray *)fontSizes
{
    if(fontSizes != _fontSizes){
        _fontSizes = fontSizes;
        [_pickerView reloadComponent:1];
    }
}

- (void)setFont:(UIFont *)font
{
    UIFont *tmp = [font fontWithSize:kCLFontPickerViewConstantFontSize];
    
    NSInteger fontIndex = [self.fontList indexOfObject:tmp];
    if(fontIndex==NSNotFound){ fontIndex = 0; }
    
    NSInteger sizeIndex = 0;
    for(sizeIndex=0; sizeIndex<self.fontSizes.count; sizeIndex++){
        if(font.pointSize<=[self.fontSizes[sizeIndex] floatValue]){
            break;
        }
    }
    
    [_pickerView selectRow:fontIndex inComponent:0 animated:NO];
    [_pickerView selectRow:sizeIndex inComponent:1 animated:NO];
}

- (UIFont*)font
{
    UIFont *font = self.fontList[[_pickerView selectedRowInComponent:0]];
    CGFloat size = [self.fontSizes[[_pickerView selectedRowInComponent:1]] floatValue];
    return [font fontWithSize:size];
}

- (void)setSizeComponentHidden:(BOOL)sizeComponentHidden
{
    _sizeComponentHidden = sizeComponentHidden;
    
    [_pickerView setNeedsLayout];
}

#pragma mark- UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(CLPickerView *)pickerView
{
    return 2;
}

- (NSInteger)pickerView:(CLPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    switch (component) {
        case 0:
            return self.fontList.count;
        case 1:
            return self.fontSizes.count;
    }
    return 0;
}

#pragma mark- UIPickerViewDelegate

- (CGFloat)pickerView:(CLPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
    return self.height/4;
}

- (CGFloat)pickerView:(CLPickerView *)pickerView widthForComponent:(NSInteger)component
{
    CGFloat ratio = self.sizeComponentHidden ? 1 : 0.8;
    switch (component) {
        case 0:
            return self.width*ratio;
        case 1:
            return self.width*(1-ratio);
    }
    return 0;
}

- (UIView*)pickerView:(CLPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view
{
    UILabel *lbl = nil;
    
    if([view isKindOfClass:[UILabel class]]){
        lbl = (UILabel*)view;
    }
    else{
        CGFloat W = [self pickerView:pickerView widthForComponent:component];
        CGFloat H = [self pickerView:pickerView rowHeightForComponent:component];
        CGFloat dx = 10;
        lbl = [[UILabel alloc] initWithFrame:CGRectMake(dx, 0, W-2*dx, H)];
        lbl.backgroundColor = [UIColor clearColor];
        lbl.adjustsFontSizeToFitWidth = YES;
        lbl.minimumScaleFactor = 0.5;
        lbl.textAlignment = NSTextAlignmentCenter;
        lbl.textColor = self.textColor;
    }
    
    switch (component) {
        case 0:
            lbl.font = self.fontList[row];
            if(self.text.length>0){
                lbl.text = self.text;
            }
            else{
                lbl.text = [NSString stringWithFormat:@"%@", lbl.font.fontName];
            }
            break;
        case 1:
            lbl.font = [UIFont systemFontOfSize:kCLFontPickerViewConstantFontSize];
            lbl.text = [NSString stringWithFormat:@"%@", self.fontSizes[row]];
            break;
        default:
            break;
    }
    
    return lbl;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if([self.delegate respondsToSelector:@selector(fontPickerView:didSelectFont:)]){
        [self.delegate fontPickerView:self didSelectFont:self.font];
    }
}

@end
