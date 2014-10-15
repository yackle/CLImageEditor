//
//  CLFilterBase.m
//
//  Created by sho yakushiji on 2013/11/26.
//  Copyright (c) 2013年 CALACULU. All rights reserved.
//

#import "CLFilterBase.h"

@implementation CLFilterBase

+ (NSString*)defaultIconImagePath
{
    return nil;
}

+ (NSArray*)subtools
{
    return nil;
}

+ (CGFloat)defaultDockedNumber
{
    return 0;
}

+ (NSString*)defaultTitle
{
    return @"CLFilterBase";
}

+ (BOOL)isAvailable
{
    return NO;
}

+ (NSDictionary*)optionalInfo
{
    return nil;
}

#pragma mark-

+ (UIImage*)applyFilter:(UIImage*)image
{
    return image;
}

@end




#pragma mark- Default Filters


@interface CLDefaultEmptyFilter : CLFilterBase

@end

@implementation CLDefaultEmptyFilter

+ (NSDictionary*)defaultFilterInfo
{
    NSDictionary *defaultFilterInfo = nil;
    if(defaultFilterInfo==nil){
        defaultFilterInfo =
        @{
            @"CLDefaultEmptyFilter"     : @{@"name":@"CLDefaultEmptyFilter",     @"title":NSLocalizedStringWithDefaultValue(@"CLDefaultEmptyFilter_DefaultTitle",    nil, [CLImageEditorTheme bundle], @"None", @""),       @"version":@(0.0), @"dockedNum":@(0.0)},
            @"CLDefaultLinearFilter"    : @{@"name":@"CISRGBToneCurveToLinear",  @"title":NSLocalizedStringWithDefaultValue(@"CLDefaultLinearFilter_DefaultTitle",   nil, [CLImageEditorTheme bundle], @"Linear", @""),     @"version":@(7.0), @"dockedNum":@(1.0)},
            @"CLDefaultVignetteFilter"  : @{@"name":@"CIVignetteEffect",         @"title":NSLocalizedStringWithDefaultValue(@"CLDefaultVignetteFilter_DefaultTitle", nil, [CLImageEditorTheme bundle], @"Vignette", @""),   @"version":@(7.0), @"dockedNum":@(2.0)},
            @"CLDefaultInstantFilter"   : @{@"name":@"CIPhotoEffectInstant",     @"title":NSLocalizedStringWithDefaultValue(@"CLDefaultInstantFilter_DefaultTitle",  nil, [CLImageEditorTheme bundle], @"Instant", @""),    @"version":@(7.0), @"dockedNum":@(3.0)},
            @"CLDefaultProcessFilter"   : @{@"name":@"CIPhotoEffectProcess",     @"title":NSLocalizedStringWithDefaultValue(@"CLDefaultProcessFilter_DefaultTitle",  nil, [CLImageEditorTheme bundle], @"Process", @""),    @"version":@(7.0), @"dockedNum":@(4.0)},
            @"CLDefaultTransferFilter"  : @{@"name":@"CIPhotoEffectTransfer",    @"title":NSLocalizedStringWithDefaultValue(@"CLDefaultTransferFilter_DefaultTitle", nil, [CLImageEditorTheme bundle], @"Transfer", @""),   @"version":@(7.0), @"dockedNum":@(5.0)},
            @"CLDefaultSepiaFilter"     : @{@"name":@"CISepiaTone",              @"title":NSLocalizedStringWithDefaultValue(@"CLDefaultSepiaFilter_DefaultTitle",    nil, [CLImageEditorTheme bundle], @"Sepia", @""),      @"version":@(5.0), @"dockedNum":@(6.0)},
            @"CLDefaultChromeFilter"    : @{@"name":@"CIPhotoEffectChrome",      @"title":NSLocalizedStringWithDefaultValue(@"CLDefaultChromeFilter_DefaultTitle",   nil, [CLImageEditorTheme bundle], @"Chrome", @""),     @"version":@(7.0), @"dockedNum":@(7.0)},
            @"CLDefaultFadeFilter"      : @{@"name":@"CIPhotoEffectFade",        @"title":NSLocalizedStringWithDefaultValue(@"CLDefaultFadeFilter_DefaultTitle",     nil, [CLImageEditorTheme bundle], @"Fade", @""),       @"version":@(7.0), @"dockedNum":@(8.0)},
            @"CLDefaultCurveFilter"     : @{@"name":@"CILinearToSRGBToneCurve",  @"title":NSLocalizedStringWithDefaultValue(@"CLDefaultCurveFilter_DefaultTitle",    nil, [CLImageEditorTheme bundle], @"Curve", @""),      @"version":@(7.0), @"dockedNum":@(9.0)},
            @"CLDefaultTonalFilter"     : @{@"name":@"CIPhotoEffectTonal",       @"title":NSLocalizedStringWithDefaultValue(@"CLDefaultTonalFilter_DefaultTitle",    nil, [CLImageEditorTheme bundle], @"Tonal", @""),      @"version":@(7.0), @"dockedNum":@(10.0)},
            @"CLDefaultNoirFilter"      : @{@"name":@"CIPhotoEffectNoir",        @"title":NSLocalizedStringWithDefaultValue(@"CLDefaultNoirFilter_DefaultTitle",     nil, [CLImageEditorTheme bundle], @"Noir", @""),       @"version":@(7.0), @"dockedNum":@(11.0)},
            @"CLDefaultMonoFilter"      : @{@"name":@"CIPhotoEffectMono",        @"title":NSLocalizedStringWithDefaultValue(@"CLDefaultMonoFilter_DefaultTitle",     nil, [CLImageEditorTheme bundle], @"Mono", @""),       @"version":@(7.0), @"dockedNum":@(12.0)},
            @"CLDefaultInvertFilter"    : @{@"name":@"CIColorInvert",            @"title":NSLocalizedStringWithDefaultValue(@"CLDefaultInvertFilter_DefaultTitle",   nil, [CLImageEditorTheme bundle], @"Invert", @""),     @"version":@(6.0), @"dockedNum":@(13.0)},
        };
    }
    return defaultFilterInfo;
}

+ (id)defaultInfoForKey:(NSString*)key
{
    return self.defaultFilterInfo[NSStringFromClass(self)][key];
}

+ (NSString*)filterName
{
    return [self defaultInfoForKey:@"name"];
}

#pragma mark- 

+ (NSString*)defaultTitle
{
    return [self defaultInfoForKey:@"title"];
}

+ (BOOL)isAvailable
{
    return ([UIDevice iosVersion] >= [[self defaultInfoForKey:@"version"] floatValue]);
}

+ (CGFloat)defaultDockedNumber
{
    return [[self defaultInfoForKey:@"dockedNum"] floatValue];
}

#pragma mark- 

+ (UIImage*)applyFilter:(UIImage *)image
{
    return [self filteredImage:image withFilterName:self.filterName];
}

+ (UIImage*)filteredImage:(UIImage*)image withFilterName:(NSString*)filterName
{
    if([filterName isEqualToString:@"CLDefaultEmptyFilter"]){
        return image;
    }
    
    CIImage *ciImage = [[CIImage alloc] initWithImage:image];
    CIFilter *filter = [CIFilter filterWithName:filterName keysAndValues:kCIInputImageKey, ciImage, nil];
    
    //NSLog(@"%@", [filter attributes]);
    
    [filter setDefaults];
    
    if([filterName isEqualToString:@"CIVignetteEffect"]){
        // parameters for CIVignetteEffect
        CGFloat R = MIN(image.size.width, image.size.height)*image.scale/2;
        CIVector *vct = [[CIVector alloc] initWithX:image.size.width*image.scale/2 Y:image.size.height*image.scale/2];
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

@end



@interface CLDefaultLinearFilter : CLDefaultEmptyFilter
@end
@implementation CLDefaultLinearFilter
@end

@interface CLDefaultVignetteFilter : CLDefaultEmptyFilter
@end
@implementation CLDefaultVignetteFilter
@end

@interface CLDefaultInstantFilter : CLDefaultEmptyFilter
@end
@implementation CLDefaultInstantFilter
@end

@interface CLDefaultProcessFilter : CLDefaultEmptyFilter
@end
@implementation CLDefaultProcessFilter
@end

@interface CLDefaultTransferFilter : CLDefaultEmptyFilter
@end
@implementation CLDefaultTransferFilter
@end

@interface CLDefaultSepiaFilter : CLDefaultEmptyFilter
@end
@implementation CLDefaultSepiaFilter
@end

@interface CLDefaultChromeFilter : CLDefaultEmptyFilter
@end
@implementation CLDefaultChromeFilter
@end

@interface CLDefaultFadeFilter : CLDefaultEmptyFilter
@end
@implementation CLDefaultFadeFilter
@end

@interface CLDefaultCurveFilter : CLDefaultEmptyFilter
@end
@implementation CLDefaultCurveFilter
@end

@interface CLDefaultTonalFilter : CLDefaultEmptyFilter
@end
@implementation CLDefaultTonalFilter
@end

@interface CLDefaultNoirFilter : CLDefaultEmptyFilter
@end
@implementation CLDefaultNoirFilter
@end

@interface CLDefaultMonoFilter : CLDefaultEmptyFilter
@end
@implementation CLDefaultMonoFilter
@end

@interface CLDefaultInvertFilter : CLDefaultEmptyFilter
@end
@implementation CLDefaultInvertFilter
@end
