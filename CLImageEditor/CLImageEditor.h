//
//  CLImageEditor.h
//
//  Created by sho yakushiji on 2013/10/17.
//  Copyright (c) 2013年 CALACULU. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CLImageToolInfo.h"

@protocol CLImageEditorDelegate;

@interface CLImageEditor : UIViewController
{
    
}
@property (nonatomic, weak) id<CLImageEditorDelegate> delegate;
@property (nonatomic, readonly) CLImageToolInfo *toolInfo;

- (id)initWithImage:(UIImage*)image;

@end



@protocol CLImageEditorDelegate <NSObject>
@required
- (void)imageEditor:(CLImageEditor*)editor didFinishEdittingWithImage:(UIImage*)image;

@optional
- (void)imageEditorDidCancel:(CLImageEditor*)editor;

@end