//
//  CLSplineInterpolator.m
//
//  Created by sho yakushiji on 2013/10/24.
//  Copyright (c) 2013年 CALACULU. All rights reserved.
//  Reference: http://www5d.biglobe.ne.jp/%257estssk/maze/spline.html
//

#import "CLSplineInterpolator.h"


@interface CLSplineCalculator : NSObject
- (id)initWithData:(double*)points dataNum:(NSInteger)dataNum;
- (CGFloat)getValue:(CGFloat)t;
@end


#pragma mark- CLSplineInterpolator

@implementation CLSplineInterpolator
{
    NSInteger _pointNum;
    
    CLSplineCalculator *_splineX;
    CLSplineCalculator *_splineY;
}

- (id)initWithPoints:(NSArray *)points
{
    self = [super init];
    if(self){
        _pointNum = points.count;
        
        double *dataX = malloc(sizeof(double) * _pointNum);
        double *dataY = malloc(sizeof(double) * _pointNum);
        
        for(NSInteger i=0; i<_pointNum; ++i){
            CIVector *point = points[i];
            dataX[i] = point.X;
            dataY[i] = point.Y;
        }
        
        _splineX = [[CLSplineCalculator alloc] initWithData:dataX dataNum:_pointNum];
        _splineY = [[CLSplineCalculator alloc] initWithData:dataY dataNum:_pointNum];
        
        free(dataX);
        free(dataY);
    }
    return self;
}

- (CIVector*)interpolatedPoint:(CGFloat)t
{
    t = MAX(0, MIN(t, 1));
    t = t * (_pointNum - 1);
    
    return [CIVector vectorWithX:[_splineX getValue:t] Y:[_splineY getValue:t]];
}

@end

#pragma mark- CLSplineCalculator

@implementation CLSplineCalculator
{
    NSInteger _dataNum;
    double *a, *b, *c, *d;
}

- (id)initWithData:(double*)data dataNum:(NSInteger)dataNum
{
    self = [super init];
    if(self){
        _dataNum = dataNum;
        
        a = b = c = d = NULL;
        
        if(dataNum<=0){
            return nil;
        }
        
        a = malloc(dataNum * sizeof(double));
        b = malloc(dataNum * sizeof(double));
        c = malloc(dataNum * sizeof(double));
        d = malloc(dataNum * sizeof(double));
        
        for(NSInteger i=0; i<dataNum; ++i){
            a[i] = data[i];
        }
        
        c[0] = c[dataNum-1] = 0.0;
        for(NSInteger i=1; i<dataNum-1; ++i){
            c[i] = 3.0 * (a[i-1] - 2.0 * a[i] + a[i+1]);
        }
        
        double *w = malloc(dataNum * sizeof(double));
        w[0]=0.0;
        for(NSInteger i=1; i<dataNum-1; ++i){
            double tmp = 4.0 - w[i-1];
            c[i] = (c[i] - c[i-1])/tmp;
            w[i] = 1.0 / tmp;
        }
        
        for(NSInteger i=dataNum-2; i>0; --i){
            c[i] = c[i] - c[i+1] * w[i];
        }
        
        b[dataNum-1] = d[dataNum-1] =0.0;
        for(NSInteger i=0; i<dataNum-1; ++i){
            d[i] = (c[i+1] - c[i]) / 3.0;
            b[i] = a[i+1] - a[i] - c[i] - d[i];
        }
        
        free(w);
    }
    return self;
}

- (void)dealloc
{
    free(a);
    free(b);
    free(c);
    free(d);
}

- (CGFloat)getValue:(CGFloat)t
{
    NSInteger j = (NSInteger)floor(t);
    if(j < 0){ j=0; }
    else if(j >= _dataNum-1){ j = _dataNum-2; }
    
    double dt = t - j;
    return a[j] + ( b[j] + (c[j] + d[j] * dt) * dt ) * dt;
}

@end