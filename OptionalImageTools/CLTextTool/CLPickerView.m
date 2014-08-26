//
//  CLPickerView.m
//
//  Created by sho yakushiji on 2013/12/15.
//  Copyright (c) 2013年 CALACULU. All rights reserved.
//

#import "CLPickerView.h"

#import "UIView+Frame.h"
#import "CLPickerDrum.h"

@interface CLPickerView()
<CLPickerDrumDelegate, CLPickerDrumDataSource>
@end


@implementation CLPickerView
{
    NSMutableArray *_drums;
    BOOL _didLoad;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self customInit];
    }
    return self;
}

- (void)awakeFromNib
{
    [self customInit];
}

- (void)customInit
{
    _didLoad = NO;
    _drums = [NSMutableArray array];
}

- (void)setDataSource:(id<CLPickerViewDataSource>)dataSource
{
    if(dataSource != _dataSource){
        _dataSource = dataSource;
        _didLoad = NO;
    }
}

- (void)setDelegate:(id<CLPickerViewDelegate>)delegate
{
    if(delegate != _delegate){
        _delegate = delegate;
        _didLoad = NO;
    }
}

#pragma mark- picker info

- (void)reloadComponent:(NSInteger)component
{
    if(!_didLoad){ [self layoutSubviews]; }
    
    if(component>=0 && component<_drums.count){
        CLPickerDrum *drum = _drums[component];
        [drum reload];
    }
}

- (void)selectRow:(NSInteger)row inComponent:(NSInteger)component animated:(BOOL)animated
{
    if(!_didLoad){ [self layoutSubviews]; }
    
    if(component>=0 && component<_drums.count){
        CLPickerDrum *drum = _drums[component];
        [drum selectRow:row animated:animated];
    }
}

- (NSInteger)selectedRowInComponent:(NSInteger)component
{
    if(component>=0 && component<_drums.count){
        CLPickerDrum *drum = _drums[component];
        return [drum selectedRow];
    }
    return 0;
}

#pragma mark- Info from delegate

- (CGFloat)widthForComponent:(NSInteger)component
{
    if([self.delegate respondsToSelector:@selector(pickerView:widthForComponent:)]){
        return [self.delegate pickerView:self widthForComponent:component];
    }
    return 0;
}

#pragma mark- View layout

- (void)layoutSubviews
{
    NSInteger N = [self.dataSource numberOfComponentsInPickerView:self];
    CGFloat x = 0;
    
    for(NSInteger i=0; i<N; ++i){
        CGFloat width = [self widthForComponent:i];
        if(width==0){ width = self.width / N; }
        
        CLPickerDrum *drum = nil;
        if(i<_drums.count){
            drum = _drums[i];
        }
        else{
            drum = [[CLPickerDrum alloc] initWithFrame:CGRectMake(x, 0, width, self.height)];
            [_drums addObject:drum];
            [self addSubview:drum];
        }
        
        drum.frame = CGRectMake(x, 0, width, self.height);
        drum.tag = i;
        drum.backgroundColor = [UIColor clearColor];
        drum.foregroundColor = self.foregroundColor;
        drum.dataSource = self;
        drum.delegate = self;
        [drum reload];
        
        x += width;
    }
    for(NSInteger i=_drums.count-1; i>=N; --i){
        CLPickerDrum *drum = [_drums objectAtIndex:i];
        [drum removeFromSuperview];
        [_drums removeObject:drum];
    }
    
    _didLoad = YES;
}

#pragma mark- CLPickerDrum data source

- (NSInteger)numberOfRowsInPickerDrum:(CLPickerDrum *)pickerDrum
{
    return [self.dataSource pickerView:self numberOfRowsInComponent:pickerDrum.tag];
}

#pragma mark- CLPickerDrum delegate

- (CGFloat)rowHeightInPickerDrum:(CLPickerDrum *)pickerDrum
{
    if([self.delegate respondsToSelector:@selector(pickerView:rowHeightForComponent:)]){
        return [self.delegate pickerView:self rowHeightForComponent:pickerDrum.tag];
    }
    return ceil(self.height / 3);
}

- (UIView*)pickerDrum:(CLPickerDrum *)pickerDrum viewForRow:(NSInteger)row reusingView:(UIView *)view
{
    if([self.delegate respondsToSelector:@selector(pickerView:viewForRow:forComponent:reusingView:)]){
        return [self.delegate pickerView:self viewForRow:row forComponent:pickerDrum.tag reusingView:view];
    }
    return nil;
}

- (NSString *)pickerDrum:(CLPickerDrum *)pickerDrum titleForRow:(NSInteger)row
{
    if([self.delegate respondsToSelector:@selector(pickerView:titleForRow:forComponent:)]){
        return [self.delegate pickerView:self titleForRow:row forComponent:pickerDrum.tag];
    }
    return [NSString stringWithFormat:@"%ld - %ld", (long)pickerDrum.tag, (long)row];
}

- (void)pickerDrum:(CLPickerDrum *)pickerDrum didSelectRow:(NSInteger)row
{
    if([self.delegate respondsToSelector:@selector(pickerView:didSelectRow:inComponent:)]){
        [self.delegate pickerView:self didSelectRow:row inComponent:pickerDrum.tag];
    }
}

@end
