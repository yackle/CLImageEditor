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
            @"CLDefaultEmptyFilter"     : @{@"name":@"CLDefaultEmptyFilter",     @"title":[CLImageEditorTheme localizedString:@"CLDefaultEmptyFilter_DefaultTitle" withDefault:@"None"],       @"version":@(0.0), @"dockedNum":@(0.0)},
            @"CLDefaultLinearFilter"    : @{@"name":@"CISRGBToneCurveToLinear",  @"title":[CLImageEditorTheme localizedString:@"CLDefaultLinearFilter_DefaultTitle" withDefault:@"Linear"],     @"version":@(7.0), @"dockedNum":@(1.0)},
            @"CLDefaultVignetteFilter"  : @{@"name":@"CIVignetteEffect",         @"title":[CLImageEditorTheme localizedString:@"CLDefaultVignetteFilter_DefaultTitle" withDefault:@"Vignette"],   @"version":@(7.0), @"dockedNum":@(2.0)},
            @"CLDefaultInstantFilter"   : @{@"name":@"CIPhotoEffectInstant",     @"title":[CLImageEditorTheme localizedString:@"CLDefaultInstantFilter_DefaultTitle" withDefault:@"Instant"],    @"version":@(7.0), @"dockedNum":@(3.0)},
            @"CLDefaultProcessFilter"   : @{@"name":@"CIPhotoEffectProcess",     @"title":[CLImageEditorTheme localizedString:@"CLDefaultProcessFilter_DefaultTitle" withDefault:@"Process"],    @"version":@(7.0), @"dockedNum":@(4.0)},
            @"CLDefaultTransferFilter"  : @{@"name":@"CIPhotoEffectTransfer",    @"title":[CLImageEditorTheme localizedString:@"CLDefaultTransferFilter_DefaultTitle" withDefault:@"Transfer"],   @"version":@(7.0), @"dockedNum":@(5.0)},
            @"CLDefaultSepiaFilter"     : @{@"name":@"CISepiaTone",              @"title":[CLImageEditorTheme localizedString:@"CLDefaultSepiaFilter_DefaultTitle" withDefault:@"Sepia"],      @"version":@(5.0), @"dockedNum":@(6.0)},
            @"CLDefaultChromeFilter"    : @{@"name":@"CIPhotoEffectChrome",      @"title":[CLImageEditorTheme localizedString:@"CLDefaultChromeFilter_DefaultTitle" withDefault:@"Chrome"],     @"version":@(7.0), @"dockedNum":@(7.0)},
            @"CLDefaultFadeFilter"      : @{@"name":@"CIPhotoEffectFade",        @"title":[CLImageEditorTheme localizedString:@"CLDefaultFadeFilter_DefaultTitle" withDefault:@"Fade"],       @"version":@(7.0), @"dockedNum":@(8.0)},
            @"CLDefaultCurveFilter"     : @{@"name":@"CILinearToSRGBToneCurve",  @"title":[CLImageEditorTheme localizedString:@"CLDefaultCurveFilter_DefaultTitle" withDefault:@"Curve"],      @"version":@(7.0), @"dockedNum":@(9.0)},
            @"CLDefaultTonalFilter"     : @{@"name":@"CIPhotoEffectTonal",       @"title":[CLImageEditorTheme localizedString:@"CLDefaultTonalFilter_DefaultTitle" withDefault:@"Tonal"],      @"version":@(7.0), @"dockedNum":@(10.0)},
            @"CLDefaultNoirFilter"      : @{@"name":@"CIPhotoEffectNoir",        @"title":[CLImageEditorTheme localizedString:@"CLDefaultNoirFilter_DefaultTitle" withDefault:@"Noir"],       @"version":@(7.0), @"dockedNum":@(11.0)},
            @"CLDefaultMonoFilter"      : @{@"name":@"CIPhotoEffectMono",        @"title":[CLImageEditorTheme localizedString:@"CLDefaultMonoFilter_DefaultTitle" withDefault:@"Mono"],       @"version":@(7.0), @"dockedNum":@(12.0)},
            @"CLDefaultInvertFilter"    : @{@"name":@"CIColorInvert",            @"title":[CLImageEditorTheme localizedString:@"CLDefaultInvertFilter_DefaultTitle" withDefault:@"Invert"],     @"version":@(6.0), @"dockedNum":@(13.0)},
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
    
    CIContext *context = [CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer : @(NO)}];
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
