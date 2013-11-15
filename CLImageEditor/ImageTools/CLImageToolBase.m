//
//  CLImageToolBase.m
//
//  Created by sho yakushiji on 2013/10/17.
//  Copyright (c) 2013年 CALACULU. All rights reserved.
//

#import "CLImageToolBase.h"

@implementation CLImageToolBase

- (id)initWithImageEditor:(_CLImageEditorViewController*)editor
{
    self = [super init];
    if(self){
        self.editor = editor;
    }
    return self;
}

+ (UIImage*)iconImage
{
    NSString *fileName = [NSString stringWithFormat:@"CLImageEditor.bundle/%@/icon.png", NSStringFromClass([self class])];
    return [UIImage imageNamed:fileName];
}

+ (CGFloat)dockedNumber
{
    // Image tools are sorted according to the dockedNumber in tool bar.
    // Override point for tool bar customization
    NSArray *tools = @[
                       @"CLFilterTool",
                       @"CLAdjustmentTool",
                       @"CLEffectTool",
                       @"CLBlurTool",
                       @"CLClippingTool",
                       @"CLRotateTool",
                       @"CLToneCurveTool",
                       ];
    return [tools indexOfObject:NSStringFromClass(self)];
}

#pragma mark-

+ (NSString*)title
{
    return @"None";
}

+ (BOOL)isAvailable
{
    return NO;
}

- (void)setup
{
    
}

- (void)cleanup
{
    
}

- (void)executeWithCompletionBlock:(void(^)(UIImage *image, NSError *error, NSDictionary *userInfo))completionBlock
{
    completionBlock(self.editor.imageView.image, nil, nil);
}

@end
