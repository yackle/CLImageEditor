//
//  CLFilterBase.h
//
//  Created by sho yakushiji on 2013/11/26.
//  Copyright (c) 2013年 CALACULU. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "../ToolSettings/CLImageToolSettings.h"

@protocol CLFilterBaseProtocol <NSObject>

@required
+ (UIImage*)applyFilter:(UIImage*)image;

@end


@interface CLFilterBase : NSObject<CLImageToolProtocol, CLFilterBaseProtocol>

@end
