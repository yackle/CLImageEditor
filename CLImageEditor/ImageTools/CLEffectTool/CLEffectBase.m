//
//  CLEffectBase.m
//
//  Created by sho yakushiji on 2013/10/23.
//  Copyright (c) 2013年 CALACULU. All rights reserved.
//

#import "CLEffectBase.h"

@implementation CLEffectBase

#pragma mark-

+ (NSString*)defaultIconImagePath
{
    return [NSString stringWithFormat:@"%@/CLEffectTool/%@.png", CLImageEditorTheme.bundle.bundlePath, NSStringFromClass([self class])];
}

+ (CGFloat)defaultDockedNumber
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

+ (NSArray*)subtools
{
    return nil;
}

+ (NSString*)defaultTitle
{
    return [CLImageEditorTheme localizedString:@"CLEffectBase_DefaultTitle" withDefault:@"None"];
}

+ (BOOL)isAvailable
{
    return YES;
}

+ (NSDictionary*)optionalInfo
{
    return nil;
}

#pragma mark-

- (id)initWithSuperView:(UIView*)superview imageViewFrame:(CGRect)frame toolInfo:(CLImageToolInfo*)info
{
    self = [super init];
    if(self){
        self.toolInfo = info;
    }
    return self;
}

- (void)cleanup
{
    
}

- (BOOL)needsThumbnailPreview
{
    return YES;
}

- (UIImage*)applyEffect:(UIImage*)image
{
    return image;
}

@end
