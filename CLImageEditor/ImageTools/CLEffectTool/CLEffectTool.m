//
//  CLEffectTool.m
//
//  Created by sho yakushiji on 2013/10/23.
//  Copyright (c) 2013年 CALACULU. All rights reserved.
//

#import "CLEffectTool.h"


@interface CLEffectTool()
@property (nonatomic, strong) UIView *selectedMenu;
@property (nonatomic, strong) CLEffectBase *selectedEffect;
@end


@implementation CLEffectTool
{
    UIImage *_originalImage;
    UIImage *_thumbnailImage;
    
    UIScrollView *_menuScroll;
    UIActivityIndicatorView *_indicatorView;
}

+ (NSArray*)subtools
{
    return [CLImageToolInfo toolsWithToolClass:[CLEffectBase class]];
}

+ (NSString*)defaultTitle
{
    return [CLImageEditorTheme localizedString:@"CLEffectTool_DefaultTitle" withDefault:@"Effect"];
}

+ (BOOL)isAvailable
{
    return ([UIDevice iosVersion] >= 5.0);
}

#pragma mark- 

- (void)setup
{
    _originalImage = self.editor.imageView.image;
    _thumbnailImage = [_originalImage resize:self.editor.imageView.frame.size];
    
    [self.editor fixZoomScaleWithAnimated:YES];
    
    _menuScroll = [[UIScrollView alloc] initWithFrame:self.editor.menuView.frame];
    _menuScroll.backgroundColor = self.editor.menuView.backgroundColor;
    _menuScroll.showsHorizontalScrollIndicator = NO;
    [self.editor.view addSubview:_menuScroll];
    
    [self setEffectMenu];
    
    _menuScroll.transform = CGAffineTransformMakeTranslation(0, self.editor.view.height-_menuScroll.top);
    [UIView animateWithDuration:kCLImageToolAnimationDuration
                     animations:^{
                         _menuScroll.transform = CGAffineTransformIdentity;
                     }];
}

- (void)cleanup
{
    [self.selectedEffect cleanup];
    [_indicatorView removeFromSuperview];
    
    [self.editor resetZoomScaleWithAnimated:YES];
    
    [UIView animateWithDuration:kCLImageToolAnimationDuration
                     animations:^{
                         _menuScroll.transform = CGAffineTransformMakeTranslation(0, self.editor.view.height-_menuScroll.top);
                     }
                     completion:^(BOOL finished) {
                         [_menuScroll removeFromSuperview];
                     }];
}

- (void)executeWithCompletionBlock:(void(^)(UIImage *image, NSError *error, NSDictionary *userInfo))completionBlock
{
    dispatch_async(dispatch_get_main_queue(), ^{
        _indicatorView = [CLImageEditorTheme indicatorView];
        _indicatorView.center = self.editor.view.center;
        [self.editor.view addSubview:_indicatorView];
        [_indicatorView startAnimating];
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *image = [self.selectedEffect applyEffect:_originalImage];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completionBlock(image, nil, nil);
        });
    });
}

#pragma mark- 

- (void)setEffectMenu
{
    CGFloat W = 70;
    CGFloat H = _menuScroll.height;
    CGFloat x = 0;
    
    for(CLImageToolInfo *info in self.toolInfo.sortedSubtools){
        if(!info.available){
            continue;
        }
        
        CLToolbarMenuItem *view = [CLImageEditorTheme menuItemWithFrame:CGRectMake(x, 0, W, H) target:self action:@selector(tappedMenu:) toolInfo:info];
        [_menuScroll addSubview:view];
        x += W;
        
        if(self.selectedMenu==nil){
            self.selectedMenu = view;
        }
    }
    _menuScroll.contentSize = CGSizeMake(MAX(x, _menuScroll.frame.size.width+1), 0);
}

- (void)tappedMenu:(UITapGestureRecognizer*)sender
{
    UIView *view = sender.view;
    
    view.alpha = 0.2;
    [UIView animateWithDuration:kCLImageToolAnimationDuration
                     animations:^{
                         view.alpha = 1;
                     }
     ];
    
    self.selectedMenu = view;
}

- (void)setSelectedMenu:(UIView *)selectedMenu
{
    if(selectedMenu != _selectedMenu){
        _selectedMenu.backgroundColor = [UIColor clearColor];
        _selectedMenu = selectedMenu;
        _selectedMenu.backgroundColor = [CLImageEditorTheme toolbarSelectedButtonColor];
        
        Class effectClass = NSClassFromString(_selectedMenu.toolInfo.toolName);
        self.selectedEffect = [[effectClass alloc] initWithSuperView:self.editor.imageView.superview imageViewFrame:self.editor.imageView.frame toolInfo:_selectedMenu.toolInfo];
    }
}

- (void)setSelectedEffect:(CLEffectBase *)selectedEffect
{
    if(selectedEffect != _selectedEffect){
        [_selectedEffect cleanup];
        _selectedEffect = selectedEffect;
        _selectedEffect.delegate = self;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self buildThumbnailImage];
        });
    }
}

- (void)buildThumbnailImage
{
    UIImage *image;
    if(self.selectedEffect.needsThumbnailPreview){
        image = [self.selectedEffect applyEffect:_thumbnailImage];
    }
    else{
        image = [self.selectedEffect applyEffect:_originalImage];
    }
    [self.editor.imageView performSelectorOnMainThread:@selector(setImage:) withObject:image waitUntilDone:NO];
}

#pragma mark- CLEffect delegate

- (void)effectParameterDidChange:(CLEffectBase *)effect
{
    if(effect == self.selectedEffect){
        static BOOL inProgress = NO;
        
        if(inProgress){ return; }
        inProgress = YES;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self buildThumbnailImage];
            inProgress = NO;
        });
    }
}

@end
