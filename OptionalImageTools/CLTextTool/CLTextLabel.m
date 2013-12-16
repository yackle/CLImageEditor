//
//  CLTextLabel.m
//
//  Created by sho yakushiji on 2013/12/16.
//  Copyright (c) 2013年 CALACULU. All rights reserved.
//

#import "CLTextLabel.h"

@implementation CLTextLabel

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)drawTextInRect:(CGRect)rect
{
    CGSize shadowOffset = self.shadowOffset;
    UIColor *txtColor = self.textColor;
    
    CGContextRef contextRef = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(contextRef, self.outlineWidth);
    CGContextSetLineJoin(contextRef, kCGLineJoinRound);
    
    CGContextSetTextDrawingMode(contextRef, kCGTextStroke);
    self.textColor = self.outlineColor;
    [super drawTextInRect:CGRectInset(rect, self.outlineWidth, self.outlineWidth)];
    
    CGContextSetTextDrawingMode(contextRef, kCGTextFill);
    self.textColor = txtColor;
    [super drawTextInRect:CGRectInset(rect, self.outlineWidth, self.outlineWidth)];
    
    self.shadowOffset = shadowOffset;
}

@end
