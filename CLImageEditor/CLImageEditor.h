//
//  CLImageEditor.h
//
//  Created by sho yakushiji on 2013/10/17.
//  Copyright (c) 2013年 CALACULU. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CLImageToolInfo.h"
#import "CLImageEditorTheme.h"

@protocol CLImageEditorDelegate;
@protocol CLImageEditorTransitionDelegate;

@interface CLImageEditor : UIViewController
{
    
}
@property (nonatomic, weak) id<CLImageEditorDelegate> delegate;
@property (nonatomic, readonly) CLImageEditorTheme *theme;
@property (nonatomic, readonly) CLImageToolInfo *toolInfo;

- (id)initWithImage:(UIImage*)image;
- (id)initWithImage:(UIImage*)image delegate:(id<CLImageEditorDelegate>)delegate;
- (id)initWithDelegate:(id<CLImageEditorDelegate>)delegate;

- (void)showInViewController:(UIViewController<CLImageEditorTransitionDelegate>*)controller withImageView:(UIImageView*)imageView;

- (void)refreshToolSettings;

@end



@protocol CLImageEditorDelegate <NSObject>
@optional
- (void)imageEditor:(CLImageEditor*)editor didFinishEdittingWithImage:(UIImage*)image;
- (void)imageEditorDidCancel:(CLImageEditor*)editor;

@end


@protocol CLImageEditorTransitionDelegate <CLImageEditorDelegate>
@optional
- (void)imageEditor:(CLImageEditor*)editor willDismissWithImageView:(UIImageView*)imageView canceled:(BOOL)canceled;
- (void)imageEditor:(CLImageEditor*)editor didDismissWithImageView:(UIImageView*)imageView canceled:(BOOL)canceled;

@end

