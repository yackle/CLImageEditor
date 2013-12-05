//
//  CLImageEditorTheme.m
//
//  Created by sho yakushiji on 2013/12/05.
//  Copyright (c) 2013年 CALACULU. All rights reserved.
//

#import "CLImageEditorTheme.h"

@implementation CLImageEditorTheme

#pragma mark - singleton pattern

static CLImageEditorTheme *_sharedInstance = nil;

+ (CLImageEditorTheme*)theme
{
    static dispatch_once_t  onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[CLImageEditorTheme alloc] init];
    });
    return _sharedInstance;
}

+ (id)allocWithZone:(NSZone *)zone
{
    @synchronized(self) {
        if (_sharedInstance == nil) {
            _sharedInstance = [super allocWithZone:zone];
            return _sharedInstance;
        }
    }
    return nil;
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.bundleName = @"CLImageEditor";
    }
    return self;
}

#pragma mark- instance methods

- (NSBundle*)bundle
{
    return [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:self.bundleName ofType:@"bundle"]];
}

#pragma mark- class methods

+ (NSString*)bundleName
{
    return self.theme.bundleName;
}

+ (NSBundle*)bundle
{
    return self.theme.bundle;
}

+ (UIImage*)imageNamed:(NSString *)path
{
    return [UIImage imageNamed:[NSString stringWithFormat:@"%@.bundle/%@", self.bundleName, path]];
}

@end
