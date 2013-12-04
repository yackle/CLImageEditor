//
//  CLImageToolProtocol.h
//
//  Created by sho yakushiji on 2013/11/26.
//  Copyright (c) 2013年 CALACULU. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "UIDevice+SystemVersion.h"

@protocol CLImageToolProtocol

@required
+ (NSString*)defaultIconImagePath;
+ (CGFloat)defaultDockedNumber;
+ (NSString*)defaultTitle;
+ (BOOL)isAvailable;
+ (NSArray*)subtools;


@end
