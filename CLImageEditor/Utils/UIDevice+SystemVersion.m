//
//  UIDevice+SystemVersion.m
//
//  Created by sho yakushiji on 2013/11/06.
//  Copyright (c) 2013年 CALACULU. All rights reserved.
//

#import "UIDevice+SystemVersion.h"

@implementation UIDevice (SystemVersion)

+ (CGFloat)iosVersion
{
    return [[[UIDevice currentDevice] systemVersion] floatValue];
}

@end
