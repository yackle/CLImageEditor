//
//  CLFilterTool.m
//
//  Created by sho yakushiji on 2013/10/19.
//  Copyright (c) 2013年 CALACULU. All rights reserved.
//

#import "CLFilterTool.h"

#import <QuartzCore/QuartzCore.h>
#import "UIImage+Utility.h"
#import "UIView+Frame.h"



@interface CLFilterPanel : UIView
{
    
}
@property (nonatomic, strong) NSString *filterName;
@property (nonatomic, strong) NSString *title;

@end

@implementation CLFilterPanel

@end


@implementation CLFilterTool
{
    UIImage *_originalImage;
    UIImage *_thumnailImage;
    
    NSArray *_filters;
    
    UIScrollView *_filterScroll;
}

+ (NSString*)title
{
    return @"Filter";
}

+ (BOOL)isAvailable
{
    return ([UIDevice iosVersion] >= 5.0);
}

- (void)setup
{
    [self setFilters];
    
    _originalImage = self.editor.imageView.image;
    _thumnailImage = [_originalImage aspectFill:CGSizeMake(50, 50)];
    
    _filterScroll = [[UIScrollView alloc] initWithFrame:self.editor.menuView.frame];
    _filterScroll.backgroundColor = self.editor.menuView.backgroundColor;
    _filterScroll.showsHorizontalScrollIndicator = NO;
    [self.editor.view addSubview:_filterScroll];
    
    [self setFilterMenu];
    
    _filterScroll.transform = CGAffineTransformMakeTranslation(0, self.editor.view.height-_filterScroll.top);
    [UIView animateWithDuration:kCLImageToolAnimationDuration
                     animations:^{
                         _filterScroll.transform = CGAffineTransformIdentity;
                     }];
}

- (void)cleanup
{
    [UIView animateWithDuration:kCLImageToolAnimationDuration
                     animations:^{
                         _filterScroll.transform = CGAffineTransformMakeTranslation(0, self.editor.view.height-_filterScroll.top);
                     }
                     completion:^(BOOL finished) {
                         [_filterScroll removeFromSuperview];
                     }];
}

- (void)executeWithCompletionBlock:(void (^)(UIImage *, NSError *, NSDictionary *))completionBlock
{
    completionBlock(self.editor.imageView.image, nil, nil);
}

#pragma mark- 

- (void)setFilters
{
    _filters = @[
                 @{@"name":@"Original",                 @"title":@"None",       @"version":@(0.0)},
                 @{@"name":@"CISRGBToneCurveToLinear",  @"title":@"Linear",     @"version":@(7.0)},
                 @{@"name":@"CIVignetteEffect",         @"title":@"Vignette",   @"version":@(7.0)},
                 @{@"name":@"CIPhotoEffectInstant",     @"title":@"Instant",    @"version":@(7.0)},
                 @{@"name":@"CIPhotoEffectProcess",     @"title":@"Process",    @"version":@(7.0)},
                 @{@"name":@"CIPhotoEffectTransfer",    @"title":@"Transfer",   @"version":@(7.0)},
                 @{@"name":@"CISepiaTone",              @"title":@"Sepia",      @"version":@(5.0)},
                 @{@"name":@"CIPhotoEffectChrome",      @"title":@"Chrome",     @"version":@(7.0)},
                 @{@"name":@"CIPhotoEffectFade",        @"title":@"Fade",       @"version":@(7.0)},
                 @{@"name":@"CILinearToSRGBToneCurve",  @"title":@"Curve",      @"version":@(7.0)},
                 @{@"name":@"CIPhotoEffectTonal",       @"title":@"Tonal",      @"version":@(7.0)},
                 @{@"name":@"CIPhotoEffectNoir",        @"title":@"Noir",       @"version":@(7.0)},
                 @{@"name":@"CIPhotoEffectMono",        @"title":@"Mono",       @"version":@(7.0)},
                 @{@"name":@"CIColorInvert",            @"title":@"Invert",     @"version":@(6.0)},
                 ];
}

- (void)setFilterMenu
{
    CGFloat W = 70;
    CGFloat x = 0;
    
    for(NSDictionary *filter in _filters){
        if([UIDevice iosVersion] >= [filter[@"version"] floatValue]){
            CLFilterPanel *view = [[CLFilterPanel alloc] initWithFrame:CGRectMake(x, 0, W, W)];
            view.filterName = filter[@"name"];
            view.title      = filter[@"title"];
            
            UIImageView *iconView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 5, 50, 50)];
            iconView.clipsToBounds = YES;
            iconView.layer.cornerRadius = 5;
            iconView.contentMode = UIViewContentModeScaleAspectFill;
            [view addSubview:iconView];
            
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, W-10, W, 15)];
            label.backgroundColor = [UIColor clearColor];
            label.text = view.title;
            label.font = [UIFont systemFontOfSize:10];
            label.textAlignment = NSTextAlignmentCenter;
            [view addSubview:label];
            
            UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedFilterPanel:)];
            [view addGestureRecognizer:gesture];
            
            [_filterScroll addSubview:view];
            x += W;
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                UIImage *iconImage = [self filteredImage:_thumnailImage withFilterName:filter[@"name"]];
                [iconView performSelectorOnMainThread:@selector(setImage:) withObject:iconImage waitUntilDone:NO];
            });
        }
    }
    _filterScroll.contentSize = CGSizeMake(MAX(x, _filterScroll.frame.size.width+1), 0);
}

- (UIImage*)filteredImage:(UIImage*)image withFilterName:(NSString*)filterName
{
    if([filterName isEqualToString:@"Original"]){
        return _originalImage;
    }
    
    CIImage *ciImage = [[CIImage alloc] initWithImage:image];
    CIFilter *filter = [CIFilter filterWithName:filterName keysAndValues:kCIInputImageKey, ciImage, nil];
    
    //NSLog(@"%@", [filter attributes]);
    
    [filter setDefaults];
    
    if([filterName isEqualToString:@"CIVignetteEffect"]){
        // parameters for CIVignetteEffect
        CGFloat R = MIN(image.size.width, image.size.height)/2;
        CIVector *vct = [[CIVector alloc] initWithX:image.size.width/2 Y:image.size.height/2];
        [filter setValue:vct forKey:@"inputCenter"];
        [filter setValue:[NSNumber numberWithFloat:0.9] forKey:@"inputIntensity"];
        [filter setValue:[NSNumber numberWithFloat:R] forKey:@"inputRadius"];
    }
    
    CIContext *context = [CIContext contextWithOptions:nil];
    CIImage *outputImage = [filter outputImage];
    CGImageRef cgImage = [context createCGImage:outputImage fromRect:[outputImage extent]];
    
    UIImage *result = [UIImage imageWithCGImage:cgImage];
    
    CGImageRelease(cgImage);
    
    return result;
}

- (void)tappedFilterPanel:(UITapGestureRecognizer*)sender
{
    CLFilterPanel *view = (CLFilterPanel*)sender.view;
    
    view.alpha = 0.2;
    [UIView animateWithDuration:kCLImageToolAnimationDuration
                     animations:^{
                         view.alpha = 1;
                     }
     ];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *image = [self filteredImage:_originalImage withFilterName:view.filterName];
        [self.editor.imageView performSelectorOnMainThread:@selector(setImage:) withObject:image waitUntilDone:NO];
    });
}

@end
