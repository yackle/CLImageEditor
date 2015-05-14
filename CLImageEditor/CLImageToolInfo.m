//
//  CLImageToolInfo.m
//
//  Created by sho yakushiji on 2013/11/26.
//  Copyright (c) 2013年 CALACULU. All rights reserved.
//

#import "CLImageToolInfo.h"
#import "UIImage+Utility.h"

@interface CLImageToolInfo()
@property (nonatomic, strong) NSString *toolName;
@property (nonatomic, strong) NSArray *subtools;
@end

@implementation CLImageToolInfo

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
    if(self.optionalInfo){
        [self setObject:self.optionalInfo forKey:@"optionalInfo" inDictionary:dict];
    }
    
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
    return [UIImage fastImageWithContentsOfFile:self.iconImagePath];
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
