//
//  CLEffectBase.m
//
//  Created by sho yakushiji on 2013/10/23.
//  Copyright (c) 2013年 CALACULU. All rights reserved.
//

#import "CLEffectBase.h"

@implementation CLEffectBase

#pragma mark-

+ (UIImage*)iconImage
{
    NSString *fileName = [NSString stringWithFormat:@"CLImageEditor.bundle/CLEffectTool/%@.png", NSStringFromClass([self class])];
    return [UIImage imageNamed:fileName];
}

+ (CGFloat)dockedNumber
{
    // Effect tools are sorted according to the dockedNumber in tool bar.
    // Override point for tool bar customization
    NSArray *effects = @[
                         @"CLEffectBase",
                         @"CLSpotEffect",
                         @"CLHueEffect",
                         @"CLHighlightShadowEffect",
                         @"CLBloomEffect",
                         @"CLGloomEffect",
                         @"CLPosterizeEffect",
                         @"CLPixellateEffect",
                         ];
    return [effects indexOfObject:NSStringFromClass(self)];
}

#pragma mark- 

+ (NSString*)title
{
    return @"None";
}

+ (BOOL)isAvailable
{
    return YES;
}

- (id)initWithSuperView:(UIView*)superview imageViewFrame:(CGRect)frame;
{
    self = [super init];
    if(self){
        
    }
    return self;
}

- (void)cleanup
{
    
}

- (BOOL)needsThumnailPreview
{
    return YES;
}

- (UIImage*)applyEffect:(UIImage*)image
{
    return image;
}

@end
