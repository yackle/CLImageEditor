//
//  CLSplineInterpolator.h
//
//  Created by sho yakushiji on 2013/10/24.
//  Copyright (c) 2013年 CALACULU. All rights reserved.
//  Reference: http://www5d.biglobe.ne.jp/%257estssk/maze/spline.html
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@interface CLSplineInterpolator : NSObject

- (id)initWithPoints:(NSArray*)points;          // points: array of CIVector
- (CIVector*)interpolatedPoint:(CGFloat)t;      // {t | 0 ≤ t ≤ 1}

@end
