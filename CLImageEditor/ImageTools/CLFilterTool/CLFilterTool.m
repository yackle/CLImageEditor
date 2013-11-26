//
//  CLFilterTool.m
//
//  Created by sho yakushiji on 2013/10/19.
//  Copyright (c) 2013年 CALACULU. All rights reserved.
//

#import "CLFilterTool.h"

#import "CLFilterBase.h"
#import "UIImage+Utility.h"
#import "UIView+Frame.h"
#import "CLClassList.h"
#import "UIView+CLImageToolInfo.h"


@implementation CLFilterTool
{
    UIImage *_originalImage;
    
    UIScrollView *_menuScroll;
}

+ (NSArray*)subtools
{
    NSMutableArray *array = [NSMutableArray array];
    
    NSArray *list = [CLClassList subclassesOfClass:[CLFilterBase class]];
    for(Class subtool in list){
        CLImageToolInfo *info = [CLImageToolInfo toolInfoForToolClass:subtool];
        if(info){
            [array addObject:info];
        }
    }
    return [array copy];
}

+ (NSString*)defaultTitle
{
    return @"Filter";
}

+ (BOOL)isAvailable
{
    return ([UIDevice iosVersion] >= 5.0);
}

- (void)setup
{
    _originalImage = self.editor.imageView.image;
    
    _menuScroll = [[UIScrollView alloc] initWithFrame:self.editor.menuView.frame];
    _menuScroll.backgroundColor = self.editor.menuView.backgroundColor;
    _menuScroll.showsHorizontalScrollIndicator = NO;
    [self.editor.view addSubview:_menuScroll];
    
    [self setFilterMenu];
    
    _menuScroll.transform = CGAffineTransformMakeTranslation(0, self.editor.view.height-_menuScroll.top);
    [UIView animateWithDuration:kCLImageToolAnimationDuration
                     animations:^{
                         _menuScroll.transform = CGAffineTransformIdentity;
                     }];
}

- (void)cleanup
{
    [UIView animateWithDuration:kCLImageToolAnimationDuration
                     animations:^{
                         _menuScroll.transform = CGAffineTransformMakeTranslation(0, self.editor.view.height-_menuScroll.top);
                     }
                     completion:^(BOOL finished) {
                         [_menuScroll removeFromSuperview];
                     }];
}

- (void)executeWithCompletionBlock:(void (^)(UIImage *, NSError *, NSDictionary *))completionBlock
{
    completionBlock(self.editor.imageView.image, nil, nil);
}

#pragma mark- 

- (void)setFilterMenu
{
    CGFloat W = 70;
    CGFloat x = 0;
    
    UIImage *iconThumnail = [_originalImage aspectFill:CGSizeMake(50, 50)];
    
    for(CLImageToolInfo *info in self.toolInfo.subtools){
        if(!info.available){
            continue;
        }
        
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(x, 0, W, W)];
        view.toolInfo = info;
        
        UIImageView *iconView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 5, 50, 50)];
        iconView.clipsToBounds = YES;
        iconView.layer.cornerRadius = 5;
        iconView.contentMode = UIViewContentModeScaleAspectFill;
        [view addSubview:iconView];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, W-10, W, 15)];
        label.backgroundColor = [UIColor clearColor];
        label.text = info.title;
        label.font = [UIFont systemFontOfSize:10];
        label.textAlignment = NSTextAlignmentCenter;
        [view addSubview:label];
        
        UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedFilterPanel:)];
        [view addGestureRecognizer:gesture];
        
        [_menuScroll addSubview:view];
        x += W;
        
        if(info.iconImagePath){
            iconView.image = info.iconImage;
        }
        else{
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                UIImage *iconImage = [self filteredImage:iconThumnail withToolInfo:info];
                [iconView performSelectorOnMainThread:@selector(setImage:) withObject:iconImage waitUntilDone:NO];
            });
        }
    }
    _menuScroll.contentSize = CGSizeMake(MAX(x, _menuScroll.frame.size.width+1), 0);
}

- (void)tappedFilterPanel:(UITapGestureRecognizer*)sender
{
    UIView *view = sender.view;
    
    view.alpha = 0.2;
    [UIView animateWithDuration:kCLImageToolAnimationDuration
                     animations:^{
                         view.alpha = 1;
                     }
     ];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *image = [self filteredImage:_originalImage withToolInfo:view.toolInfo];
        [self.editor.imageView performSelectorOnMainThread:@selector(setImage:) withObject:image waitUntilDone:NO];
    });
}

- (UIImage*)filteredImage:(UIImage*)image withToolInfo:(CLImageToolInfo*)info
{
    @autoreleasepool {
        Class filterClass = NSClassFromString(info.toolName);
        if([(Class)filterClass conformsToProtocol:@protocol(CLFilterBaseProtocol)]){
            return [filterClass applyFilter:image];
        }
        return nil;
    }
}

@end
