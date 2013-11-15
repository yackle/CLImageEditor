//
//  CLImageTools.m
//
//  Created by sho yakushiji on 2013/10/17.
//  Copyright (c) 2013年 CALACULU. All rights reserved.
//

#import "CLImageTools.h"

#import "CLClassList.h"

@implementation CLImageTools

+ (NSArray*)list
{
    static NSArray *list = nil;
    if(list==nil){
        list = [CLClassList subclassesOfClass:[CLImageToolBase class]];
        
        list = [list sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            CGFloat dockedNum1 = [obj1 dockedNumber];
            CGFloat dockedNum2 = [obj2 dockedNumber];
            
            if(dockedNum1 < dockedNum2){ return NSOrderedAscending; }
            else if(dockedNum1 > dockedNum2){ return NSOrderedDescending; }
            return NSOrderedSame;
        }];
    }
    return list;
}

@end
