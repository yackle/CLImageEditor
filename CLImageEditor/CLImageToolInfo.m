//
//  CLImageToolInfo.m
//
//  Created by sho yakushiji on 2013/11/26.
//  Copyright (c) 2013年 CALACULU. All rights reserved.
//

#import "CLImageToolInfo.h"

#import "CLImageToolProtocol.h"

@interface CLImageToolInfo()
@property (nonatomic, strong) NSString *toolName;
@property (nonatomic, strong) NSArray *subtools;
@end

@implementation CLImageToolInfo

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
        return info;
    }
    
    return nil;
}

- (UIImage*)iconImage
{
    return [UIImage imageNamed:self.iconImagePath];
}

- (CLImageToolInfo*)subToolInfoWithToolName:(NSString*)toolName
{
    return [self subToolInfoWithToolName:toolName recursive:NO];
}

- (CLImageToolInfo*)subToolInfoWithToolName:(NSString*)toolName recursive:(BOOL)recursive
{
    CLImageToolInfo *result = nil;
    
    for(CLImageToolInfo *sub in self.subtools){
        if([sub.toolName isEqualToString:toolName]){
            result = sub;
            break;
        }
        if(recursive){
            result = [sub subToolInfoWithToolName:toolName recursive:recursive];
            if(result){
                break;
            }
        }
    }
    
    return result;
}

- (CLImageToolInfo*)subToolInfoWithTitle:(NSString *)title
{
    return [self subToolInfoWithTitle:title recursive:NO];
}

- (CLImageToolInfo*)subToolInfoWithTitle:(NSString*)title recursive:(BOOL)recursive
{
    CLImageToolInfo *result = nil;
    
    for(CLImageToolInfo *sub in self.subtools){
        if([sub.title isEqualToString:title]){
            result = sub;
            break;
        }
        if(recursive){
            result = [sub subToolInfoWithTitle:title recursive:recursive];
            if(result){
                break;
            }
        }
    }
    
    return result;
}

@end
