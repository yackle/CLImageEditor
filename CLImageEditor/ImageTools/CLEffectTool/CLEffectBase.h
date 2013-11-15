//
//  CLEffectBase.h
//
//  Created by sho yakushiji on 2013/10/23.
//  Copyright (c) 2013年 CALACULU. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "UIDevice+SystemVersion.h"

static const CGFloat kCLEffectToolAnimationDuration = 0.2;


@protocol CLEffectDelegate;

@interface CLEffectBase : NSObject

@property (nonatomic, weak) id<CLEffectDelegate> delegate;

+ (UIImage*)iconImage;
+ (NSString*)title;
+ (CGFloat)dockedNumber;
+ (BOOL)isAvailable;

- (id)initWithSuperView:(UIView*)superview imageViewFrame:(CGRect)frame;
- (void)cleanup;

- (BOOL)needsThumnailPreview;
- (UIImage*)applyEffect:(UIImage*)image;

@end



@protocol CLEffectDelegate <NSObject>
@required
- (void)effectParameterDidChange:(CLEffectBase*)effect;
@end
