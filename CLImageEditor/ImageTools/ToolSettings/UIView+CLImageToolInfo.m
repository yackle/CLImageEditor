//
//  UIView+CLImageToolInfo.m
//
//  Created by sho yakushiji on 2013/11/26.
//  Copyright (c) 2013年 CALACULU. All rights reserved.
//

#import "UIView+CLImageToolInfo.h"

#import <objc/runtime.h>

@implementation UIView (CLImageToolInfo)

- (CLImageToolInfo*)toolInfo
{
    return objc_getAssociatedObject(self, @"UIView+CLImageToolInfo");
}

- (void)setToolInfo:(CLImageToolInfo *)toolInfo
{
    objc_setAssociatedObject(self, @"UIView+CLImageToolInfo", toolInfo, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
