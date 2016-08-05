//
//  CLEffectBase.h
//
//  Created by sho yakushiji on 2013/10/23.
//  Copyright (c) 2013年 CALACULU. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "../ToolSettings/CLImageToolSettings.h"


static const CGFloat kCLEffectToolAnimationDuration = 0.2;


@protocol CLEffectDelegate;

@interface CLEffectBase : NSObject<CLImageToolProtocol>

@property (nonatomic, weak) id<CLEffectDelegate> delegate;
@property (nonatomic, weak) CLImageToolInfo *toolInfo;


- (id)initWithSuperView:(UIView*)superview imageViewFrame:(CGRect)frame toolInfo:(CLImageToolInfo*)info;
- (void)cleanup;

- (BOOL)needsThumbnailPreview;
- (UIImage*)applyEffect:(UIImage*)image;

@end



@protocol CLEffectDelegate <NSObject>
@required
- (void)effectParameterDidChange:(CLEffectBase*)effect;
@end
