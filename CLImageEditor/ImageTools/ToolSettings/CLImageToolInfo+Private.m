//
//  CLImageToolInfo+Private.m
//
//  Created by sho yakushiji on 2013/12/07.
//  Copyright (c) 2013年 CALACULU. All rights reserved.
//

#import "CLImageToolInfo+Private.h"

#import "CLImageToolProtocol.h"
#import "CLClassList.h"


@interface CLImageToolInfo()
@property (nonatomic, strong) NSString *toolName;
@property (nonatomic, strong) NSArray *subtools;
@end

@implementation CLImageToolInfo (Private)

+ (CLImageToolInfo*)toolInfoForToolClass:(Class<CLImageToolProtocol>)toolClass;
{
    if([(Class)toolClass conformsToProtocol:@protocol(CLImageToolProtocol)] && [toolClass isAvailable]){
        CLImageToolInfo *info = [CLImageToolInfo new];
        info.toolName  = NSStringFromClass(toolClass);
        info.title     = [toolClass defaultTitle];
        info.available = YES;
        info.dockedNumber = [toolClass defaultDockedNumber];
        info.iconImagePath = [toolClass defaultIconImagePath];
        info.subtools = [toolClass subtools];
        info.optionalInfo = [[toolClass optionalInfo] mutableCopy];
        
        return info;
    }
    return nil;
}

+ (NSArray*)toolsWithToolClass:(Class<CLImageToolProtocol>)toolClass
{
    NSMutableArray *array = [NSMutableArray array];
    
    CLImageToolInfo *info = [CLImageToolInfo toolInfoForToolClass:toolClass];
    if(info){
        [array addObject:info];
    }
    
    NSArray *list = [CLClassList subclassesOfClass:toolClass];
    for(Class subtool in list){
        info = [CLImageToolInfo toolInfoForToolClass:subtool];
        if(info){
            [array addObject:info];
        }
    }
    return [array copy];
}

@end
