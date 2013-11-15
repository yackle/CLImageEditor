//
//  CLEffectTool.m
//
//  Created by sho yakushiji on 2013/10/23.
//  Copyright (c) 2013年 CALACULU. All rights reserved.
//

#import "CLEffectTool.h"

#import "CLEffectBase.h"
#import "UIImage+Utility.h"
#import "UIView+Frame.h"
#import "CLClassList.h"

@interface CLEffectTool()
@property (nonatomic, strong) UIView *selectedMenu;
@property (nonatomic, strong) CLEffectBase *selectedEffect;
@end


@implementation CLEffectTool
{
    NSArray *_effectClasses;
    
    UIImage *_originalImage;
    UIImage *_thumnailImage;
    
    UIScrollView *_menuScroll;
    UIActivityIndicatorView *_indicatorView;
}

+ (NSArray*)effectList
{
    static NSArray *list = nil;
    if(list==nil){
        NSMutableArray *tmp = [@[[CLEffectBase class]] mutableCopy];
        [tmp addObjectsFromArray:[CLClassList subclassesOfClass:[CLEffectBase class]]];
        
        list = [tmp sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            CGFloat dockedNum1 = [obj1 dockedNumber];
            CGFloat dockedNum2 = [obj2 dockedNumber];
            
            if(dockedNum1 < dockedNum2){ return NSOrderedAscending; }
            else if(dockedNum1 > dockedNum2){ return NSOrderedDescending; }
            return NSOrderedSame;
        }];
    }
    return list;
}

+ (NSString*)title
{
    return @"Effect";
}

+ (BOOL)isAvailable
{
    return ([UIDevice iosVersion] >= 5.0);
}

- (void)setup
{
    _originalImage = self.editor.imageView.image;
    _thumnailImage = [_originalImage resize:self.editor.imageView.frame.size];
    
    CGFloat minZoomScale = self.editor.scrollView.minimumZoomScale;
    self.editor.scrollView.maximumZoomScale = 0.95*minZoomScale;
    self.editor.scrollView.minimumZoomScale = 0.95*minZoomScale;
    [self.editor.scrollView setZoomScale:self.editor.scrollView.minimumZoomScale animated:YES];
    
    _menuScroll = [[UIScrollView alloc] initWithFrame:self.editor.menuView.frame];
    _menuScroll.backgroundColor = self.editor.menuView.backgroundColor;
    _menuScroll.showsHorizontalScrollIndicator = NO;
    [self.editor.view addSubview:_menuScroll];
    
    _effectClasses = [[self class] effectList];
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
    
    [self.editor resetZoomScaleWithAnimate:YES];
    
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
        _indicatorView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 80, 80)];
        _indicatorView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6];
        _indicatorView.layer.cornerRadius = 5;
        _indicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
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
    CGFloat x = 0;
    
    for(NSInteger i=0; i<_effectClasses.count; ++i){
        Class effect = _effectClasses[i];
        
        if([effect isSubclassOfClass:[CLEffectBase class]] && [effect isAvailable]){
            UIView *view = [[UIView alloc] initWithFrame:CGRectMake(x, 0, W, _menuScroll.height)];
            view.tag = i;
            
            UIImageView *iconView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 5, 50, 50)];
            iconView.clipsToBounds = YES;
            iconView.layer.cornerRadius = 5;
            iconView.contentMode = UIViewContentModeScaleAspectFill;
            iconView.image = [effect iconImage];
            [view addSubview:iconView];
            
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, W-10, W, 15)];
            label.backgroundColor = [UIColor clearColor];
            label.text = [effect title];;
            label.font = [UIFont systemFontOfSize:10];
            label.textAlignment = NSTextAlignmentCenter;
            [view addSubview:label];
            
            UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedMenu:)];
            [view addGestureRecognizer:gesture];
            
            [_menuScroll addSubview:view];
            x += W;
            
            if(self.selectedMenu==nil){
                self.selectedMenu = view;
            }
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
        _selectedMenu.backgroundColor = [[UIColor cyanColor] colorWithAlphaComponent:0.2];
        
        Class effectClass = _effectClasses[_selectedMenu.tag];
        self.selectedEffect = [[effectClass alloc] initWithSuperView:self.editor.scrollView imageViewFrame:self.editor.imageView.frame];
    }
}

- (void)setSelectedEffect:(CLEffectBase *)selectedEffect
{
    if(selectedEffect != _selectedEffect){
        [_selectedEffect cleanup];
        _selectedEffect = selectedEffect;
        _selectedEffect.delegate = self;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self buildThumnailImage];
        });
    }
}

- (void)buildThumnailImage
{
    UIImage *image;
    if(self.selectedEffect.needsThumnailPreview){
        image = [self.selectedEffect applyEffect:_thumnailImage];
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
            [self buildThumnailImage];
            inProgress = NO;
        });
    }
}

@end
