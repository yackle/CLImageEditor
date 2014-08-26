//
//  CLPickerDrum.m
//
//  Created by sho yakushiji on 2013/12/15.
//  Copyright (c) 2013年 CALACULU. All rights reserved.
//

#import "CLPickerDrum.h"

#import "UIView+Frame.h"


#define MAX_SCROLLABLE_VIEWS 10000


@interface CLPickerDrum()
<UIScrollViewDelegate>
@property (nonatomic, assign) NSInteger centerContentIndex;
@end


@implementation CLPickerDrum
{
    CGFloat _VIEW_WIDTH;
    CGFloat _VIEW_HEIGHT;
    
    NSInteger _VIEW_NUM;
    NSInteger _ROW_NUM;
    
    NSInteger _topContentIndex;
    NSInteger _topViewIndex;
    NSInteger _bottomViewIndex;
    NSInteger _centerViewIndex;
    
    UIImageView *_imageView;
    UIScrollView *_scrollView;
    
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
    _centerContentIndex = 0;
    
    self.foregroundColor = [UIColor colorWithWhite:1 alpha:0.5];
    
    _imageView = [[UIImageView alloc] initWithFrame:self.bounds];
    _imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self addSubview:_imageView];
    
    _scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
    _scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.showsVerticalScrollIndicator   = NO;
    _scrollView.pagingEnabled = NO;
    _scrollView.delegate = self;
    [self insertSubview:_scrollView atIndex:0];
}

- (void)setDataSource:(id<CLPickerDrumDataSource>)dataSource
{
    if(dataSource != _dataSource){
        _dataSource = dataSource;
        _didLoad = NO;
    }
}

- (void)setDelegate:(id<CLPickerDrumDelegate>)delegate
{
    if(delegate != _delegate){
        _delegate = delegate;
        _didLoad = NO;
    }
}

#pragma mark- Build foreground image

- (UIImage*)foregroundImage
{
    UIGraphicsBeginImageContextWithOptions(self.frame.size, NO, 0.0);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, self.foregroundColor.CGColor);
    CGContextFillRect(context, self.bounds);
    
    CGRect rct = CGRectMake(0, (self.height - _VIEW_HEIGHT)/2, self.width, _VIEW_HEIGHT);
    CGContextClearRect(context, rct);
    
    UIImage *tmp = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return tmp;
}

#pragma mark- Instance method

- (void)reload
{
    _didLoad = NO;
    [self layoutSubviews];
}

- (void)selectRow:(NSInteger)row animated:(BOOL)animated
{
    _centerContentIndex = row;
    
    if(_didLoad){
        _didLoad = NO;
        [self refreshViews];
    }
    else{
        [self layoutSubviews];
    }
}

- (NSInteger)selectedRow
{
    return self.centerContentIndex;
}

#pragma mark- Info from delegate

- (CGFloat)rowHeight
{
    if([self.delegate respondsToSelector:@selector(rowHeightInPickerDrum:)]){
        return [self.delegate rowHeightInPickerDrum:self];
    }
    return ceil(self.height/3.0);
}

- (NSInteger)rowNumberFromIndex:(NSInteger)index
{
    NSInteger N = _ROW_NUM;
    if(N!=0){ index = (index+N)%N; }
    return index;
}

- (UIView*)viewForIndex:(NSInteger)index reusingView:(UIView*)view
{
    NSInteger row = [self rowNumberFromIndex:index];
    
    if(row >=0 && row<_ROW_NUM && [self.delegate respondsToSelector:@selector(pickerDrum:viewForRow:reusingView:)]){
        return [self.delegate pickerDrum:self viewForRow:row reusingView:view];
    }
    return nil;
}

- (NSString*)titleForIndex:(NSInteger)index
{
    NSInteger row = [self rowNumberFromIndex:index];
    
    if(row >=0 && row<_ROW_NUM && [self.delegate respondsToSelector:@selector(pickerDrum:titleForRow:)]){
        return [self.delegate pickerDrum:self titleForRow:row];
    }
    return @"";
}

#pragma mark- View layout

- (void)layoutSubviews
{
    _scrollView.bounds = self.bounds;
    
    _VIEW_NUM    = 0;
    _VIEW_WIDTH  = self.width;
    _VIEW_HEIGHT = self.rowHeight;
    _ROW_NUM = [self.dataSource numberOfRowsInPickerDrum:self];
    
    _imageView.image = [self foregroundImage];
    
    [self refreshViews];
}

- (void)refreshViews
{
    for(UIView *view in _scrollView.subviews){ [view removeFromSuperview]; }
    
    self.centerContentIndex = _centerContentIndex;
    
    NSInteger marginNum = ceil((self.height-_VIEW_HEIGHT)/(2*_VIEW_HEIGHT));
    _VIEW_NUM = 2*marginNum + 3;
    NSInteger centerIndex = _VIEW_NUM/2;
    
    _scrollView.contentOffset = CGPointMake(0, _VIEW_HEIGHT*MAX_SCROLLABLE_VIEWS/2);
    _scrollView.contentSize   = CGSizeMake(0, _VIEW_HEIGHT*MAX_SCROLLABLE_VIEWS);
    
    CGRect viewFrame = CGRectMake(0, _scrollView.contentOffset.y+(_scrollView.height-_VIEW_HEIGHT)/2-centerIndex*_VIEW_HEIGHT, _VIEW_WIDTH, _VIEW_HEIGHT);
    for(NSInteger i=0; i<_VIEW_NUM; ++i){
        UIView *view = [self viewForIndex:i-centerIndex+self.centerContentIndex reusingView:nil];
        
        if(view==nil){
            UILabel *label = [UILabel new];
            label.textAlignment = NSTextAlignmentCenter;
            label.text = [self titleForIndex:i-centerIndex+self.centerContentIndex];
            view = label;
        }
        view.frame = viewFrame;
        
        [_scrollView addSubview:view];
        viewFrame.origin.y += _VIEW_HEIGHT;
    }
    
    _topContentIndex = MAX_SCROLLABLE_VIEWS/2;
    _topViewIndex    = 0;
    _bottomViewIndex = _VIEW_NUM-1;
    
    _didLoad = YES;
}

#pragma mark- Scrolling

- (void)setCenterContentIndex:(NSInteger)centerContentIndex
{
    if(_ROW_NUM>0){
        centerContentIndex = (centerContentIndex + _ROW_NUM)%_ROW_NUM;
    }
    else{
        centerContentIndex = 0;
    }
    
    if(centerContentIndex != _centerContentIndex){
        _centerContentIndex = centerContentIndex;
        
        if([self.delegate respondsToSelector:@selector(pickerDrum:didSelectRow:)]){
            [self.delegate pickerDrum:self didSelectRow:_centerContentIndex];
        }
    }
}

- (NSInteger)calcViewIndex:(NSInteger)index incremental:(NSInteger)incremental
{
    return (index + incremental + _VIEW_NUM) % _VIEW_NUM;
}

- (void)scrollWithDirection:(BOOL)upperDirection
{
    NSInteger incremental  = 0;
    NSInteger viewIndex    = 0;
    NSInteger contentIndex = 0;
    if(upperDirection){
        incremental = -1;
        viewIndex   = _bottomViewIndex;
    }
    else{
        incremental = 1;
        viewIndex   = _topViewIndex;
    }
    
    if(viewIndex<_scrollView.subviews.count){
        _topContentIndex = _topContentIndex + incremental;
        self.centerContentIndex = self.centerContentIndex + incremental;
        
        if(upperDirection){
            contentIndex = self.centerContentIndex - _VIEW_NUM/2;
        }
        else{
            contentIndex = self.centerContentIndex - _VIEW_NUM/2 + _VIEW_NUM - 1;
        }
        
        UIView *reuse = [_scrollView.subviews objectAtIndex:viewIndex];
        UIView *view  = [self viewForIndex:contentIndex reusingView:reuse];
        
        if(view==nil){
            if([reuse isKindOfClass:[UILabel class]]){
                UILabel *label = (UILabel*)reuse;
                label.text = [self titleForIndex:contentIndex];
            }
        }
        else if(view!=reuse){
            view.frame = reuse.frame;
            [reuse removeFromSuperview];
            [_scrollView addSubview:view];
            reuse = view;
        }
        
        reuse.top = reuse.top + _VIEW_HEIGHT * _VIEW_NUM * incremental;
        
        _topViewIndex  = [self calcViewIndex:_topViewIndex incremental:incremental];
        _bottomViewIndex = [self calcViewIndex:_bottomViewIndex incremental:incremental];
    }
}

#pragma UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)sender
{
    CGFloat position = sender.contentOffset.y / _VIEW_HEIGHT;
    CGFloat delta    = position - (CGFloat)_topContentIndex;
    NSInteger count  = (NSInteger)MAX(fabs(delta-0.5), fabs(delta+0.5));
    
    for(NSInteger i=0; i<count; ++i){
        [self scrollWithDirection:(delta<0)];
    }
}

- (void)adjustContentOffset
{
    [UIView animateWithDuration:0.25
                          delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         _scrollView.contentOffset = CGPointMake(0, _VIEW_HEIGHT*_topContentIndex);
                     }
                     completion:^(BOOL finished) { }
     ];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)sender
{
    [self adjustContentOffset];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)sender willDecelerate:(BOOL)decelerate
{
    [self adjustContentOffset];
}

@end
