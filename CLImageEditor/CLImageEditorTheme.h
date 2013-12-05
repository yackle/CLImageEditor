//
//  CLImageEditorTheme.h
//
//  Created by sho yakushiji on 2013/12/05.
//  Copyright (c) 2013年 CALACULU. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CLImageEditorTheme : NSObject

@property (nonatomic, strong) NSString *bundleName;

- (NSBundle*)bundle;



+ (CLImageEditorTheme*)theme;
+ (NSString*)bundleName;
+ (NSBundle*)bundle;
+ (UIImage*)imageNamed:(NSString*)path;

@end
