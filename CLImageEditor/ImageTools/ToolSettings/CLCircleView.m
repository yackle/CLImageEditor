//
//  CLCircleView.m
//
//  Created by sho yakushiji on 2013/12/11.
//  Copyright (c) 2013年 CALACULU. All rights reserved.
//

#import "CLCircleView.h"

@implementation CLCircleView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        self.color = [UIColor blackColor];
        self.radius = 1;
        
        self.borderColor = [UIColor clearColor];
        self.borderWidth = 0;
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGRect rct = self.bounds;
    rct.origin.x = 0.5 * (rct.size.width - self.radius * rct.size.width);
    rct.origin.y = 0.5 * (rct.size.height - self.radius * rct.size.height);
    rct.size.width = self.radius * rct.size.width;
    rct.size.height = self.radius * rct.size.height;
    
    CGContextSetFillColorWithColor(context, self.color.CGColor);
    CGContextFillEllipseInRect(context, rct);
    
    CGContextSetStrokeColorWithColor(context, self.borderColor.CGColor);
    CGContextSetLineWidth(context, self.borderWidth);
    CGContextStrokeEllipseInRect(context, rct);
}

@end
