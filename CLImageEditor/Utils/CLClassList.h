//
//  CLClassList.h
//
//  Created by sho yakushiji on 2013/11/14.
//  Copyright (c) 2013年 CALACULU. All rights reserved.
//  reference: http://www.cocoawithlove.com/2010/01/getting-subclasses-of-objective-c-class.html
//

#import <Foundation/Foundation.h>

@interface CLClassList : NSObject

+ (NSArray*)subclassesOfClass:(Class)parentClass;

@end
