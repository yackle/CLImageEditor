//
//  CLCircleView.h
//
//  Created by sho yakushiji on 2013/12/11.
//  Copyright (c) 2013年 CALACULU. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CLCircleView : UIView

@property (nonatomic, strong) UIColor *color;
@property (nonatomic, assign) CGFloat radius;

@property (nonatomic, strong) UIColor *borderColor;
@property (nonatomic, assign) CGFloat borderWidth;

@end
