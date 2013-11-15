//
//  CLClassList.m
//
//  Created by sho yakushiji on 2013/11/14.
//  Copyright (c) 2013年 CALACULU. All rights reserved.
//  reference: http://www.cocoawithlove.com/2010/01/getting-subclasses-of-objective-c-class.html
//

#import "CLClassList.h"

#import <objc/runtime.h>

@implementation CLClassList

+ (NSArray*)subclassesOfClass:(Class)parentClass
{
    int numClasses = objc_getClassList(NULL, 0);
    Class *classes = (Class*)malloc(sizeof(Class) * numClasses);
    
    numClasses = objc_getClassList(classes, numClasses);
    
    NSMutableArray *result = [NSMutableArray array];
    for(NSInteger i=0; i<numClasses; i++){
        Class cls = classes[i];
        
        do{
           cls = class_getSuperclass(cls);
        }while(cls && cls != parentClass);
        
        if(cls){
            [result addObject:classes[i]];
        }
    }
    
    free(classes);
    
    return [result copy];
}

@end
