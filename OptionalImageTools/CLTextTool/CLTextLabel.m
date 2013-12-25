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

- (void)setOutlineColor:(UIColor *)outlineColor
{
    if(outlineColor != _outlineColor){
        _outlineColor = outlineColor;
        [self setNeedsDisplay];
    }
}

- (void)setOutlineWidth:(CGFloat)outlineWidth
{
    if(outlineWidth != _outlineWidth){
        _outlineWidth = outlineWidth;
        [self setNeedsDisplay];
    }
}

- (void)drawTextInRect:(CGRect)rect
{
    CGSize shadowOffset = self.shadowOffset;
    UIColor *txtColor = self.textColor;
    
    CGFloat outlineSize = self.outlineWidth * self.font.pointSize * 0.3;
    
    CGContextRef contextRef = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(contextRef, outlineSize);
    CGContextSetLineJoin(contextRef, kCGLineJoinRound);
    
    CGContextSetTextDrawingMode(contextRef, kCGTextStroke);
    self.textColor = self.outlineColor;
    [super drawTextInRect:CGRectInset(rect, outlineSize/4, outlineSize/4)];
    
    CGContextSetTextDrawingMode(contextRef, kCGTextFill);
    self.textColor = txtColor;
    [super drawTextInRect:CGRectInset(rect, outlineSize/4, outlineSize/4)];
    
    self.shadowOffset = shadowOffset;
}

@end
