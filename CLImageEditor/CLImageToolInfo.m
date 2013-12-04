//
//  CLImageToolInfo.m
//
//  Created by sho yakushiji on 2013/11/26.
//  Copyright (c) 2013年 CALACULU. All rights reserved.
//

#import "CLImageToolInfo.h"

#import "CLImageToolProtocol.h"
#import "CLClassList.h"

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

- (void)setObject:(id)object forKey:(NSString *)key inDictionary:(NSMutableDictionary*)dictionary
{
    if(object){
        dictionary[key] = object;
    }
}

- (NSDictionary*)descriptionDictionary
{
    NSMutableArray *array = [NSMutableArray array];
    for(CLImageToolInfo *sub in self.sortedSubtools){
        [array addObject:sub.descriptionDictionary];
    }
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [self setObject:self.toolName forKey:@"toolName"  inDictionary:dict];
    [self setObject:self.title forKey:@"title" inDictionary:dict];
    [self setObject:((self.available)?@"YES":@"NO") forKey:@"available" inDictionary:dict];
    [self setObject:@(self.dockedNumber) forKey:@"dockedNumber" inDictionary:dict];
    [self setObject:self.iconImagePath forKey:@"iconImagePath" inDictionary:dict];
    [self setObject:array forKey:@"subtools" inDictionary:dict];
    
    return dict;
}

- (NSString*)description
{
    return [NSString stringWithFormat:@"%@", self.descriptionDictionary];
}

- (NSString*)toolTreeDescriptionWithSpace:(NSString*)space
{
    NSString *str = [NSString stringWithFormat:@"%@%@\n", space, self.toolName];
    
    space = [NSString stringWithFormat:@"    %@", space];
    for(CLImageToolInfo *sub in self.sortedSubtools){
        str = [str stringByAppendingFormat:@"%@", [sub toolTreeDescriptionWithSpace:space]];
    }
    return str;
}

- (NSString*)toolTreeDescription
{
    return [NSString stringWithFormat:@"\n%@", [self toolTreeDescriptionWithSpace:@""]];
}


- (UIImage*)iconImage
{
    return [UIImage imageNamed:self.iconImagePath];
}

- (NSString*)toolName
{
    if([_toolName isEqualToString:@"_CLImageEditorViewController"]){
        return @"CLImageEditor";
    }
    return _toolName;
}

- (NSArray*)sortedSubtools
{
    self.subtools = [self.subtools sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        CGFloat dockedNum1 = [obj1 dockedNumber];
        CGFloat dockedNum2 = [obj2 dockedNumber];
        
        if(dockedNum1 < dockedNum2){ return NSOrderedAscending; }
        else if(dockedNum1 > dockedNum2){ return NSOrderedDescending; }
        return NSOrderedSame;
    }];
    return self.subtools;
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

@end
